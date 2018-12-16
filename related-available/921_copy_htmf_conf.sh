#!/bin/bash

# 1. First check if SYSCHECK_HOME is set then use that
if [ "x${SYSCHECK_HOME}" = "x" ] ; then
# 2. Check if /etc/syscheck.conf exists then source that (put SYSCHECK_HOME=/path/to/syscheck in ther)
    if [ -e /etc/syscheck.conf ] ; then
	source /etc/syscheck.conf
    else
# 3. last resort use default path
	SYSCHECK_HOME="/opt/syscheck"
    fi
fi

if [ ! -f ${SYSCHECK_HOME}/syscheck.sh ] ; then echo "$0: Can't find syscheck.sh in SYSCHECK_HOME ($SYSCHECK_HOME)" ;exit ; fi

## Import common definitions ##
. $SYSCHECK_HOME/config/related-scripts.conf

# scriptname used to map and explain scripts in icinga and other
SCRIPTNAME=copy_htmf_config

# uniq ID of script (please use in the name of this file also for convinice for finding next availavle number)
SCRIPTID=921

# Index is used to uniquely identify one test done by the script (a harddrive, crl or cert)
SCRIPTINDEX=00

getlangfiles $SCRIPTID
getconfig $SCRIPTID

ERRNO_1="${SCRIPTID}1"
ERRNO_2="${SCRIPTID}2"
ERRNO_3="${SCRIPTID}3"

### end config ###

PRINTTOSCREEN=1
if [ "x$1" = "x-h" -o "x$1" = "x--help" ] ; then
	echo "$ECRT_HELP"
	echo "$ERRNO_1/$COPY_EJBCA_CONF_DESCR_1 - $COPY_EJBCA_CONF_HELP_1"
	echo "$ERRNO_2/$COPY_EJBCA_CONF_DESCR_2 - $COPY_EJBCA_CONF_HELP_2"
	echo "${SCREEN_HELP}"
	exit
elif [ "x$1" = "x-s" -o  "x$1" = "x--screen" -o \
    "x$2" = "x-s" -o  "x$2" = "x--screen"   ] ; then
    PRINTTOSCREEN=1
fi


# Make sure you add quotation marks for the first argument when adding new files that should be copied, for exampel.


${SYSCHECK_HOME}/related-enabled/915_remote_command_via_ssh.sh ${HOSTNAME_NODE2} "mkdir -p ${REMOTE_DIR}" ${SSH_USER} ${SSHKEY}
if [ $? -ne 0 ] ; then
	echo "couldn't make dir"
	exit
fi


for (( j=0; j < ${#HTMF_FILE[@]} ; j++ )){
	printtoscreen "Copying file: ${HTMF_FILE[$j]} to:${HOSTNAME_NODE2} dir:${REMOTE_DIR} remotreuser:${REMOTE_USER} sshkey: ${SSHKEY}"
	${SYSCHECK_HOME}/related-enabled/906_ssh-copy-to-remote-machine.sh "${HTMF_FILE[$j]}" ${HOSTNAME_NODE2} ${REMOTE_DIR} ${REMOTE_USER} ${SSHKEY}
	if [ $? -ne 0 ] ; then
		echo "couln't copy file \"${HTMF_FILE[$j]}\""
		exit
	fi

}
