#!/bin/sh

# Set default home if not already set.
SYSCHECK_HOME=${SYSCHECK_HOME:-"/usr/local/syscheck"}

## Import common definitions ##
. $SYSCHECK_HOME/resources.sh

# uniq ID of script (please use in the name of this file also for convinice for finding next availavle number)
SCRIPTID=921

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

