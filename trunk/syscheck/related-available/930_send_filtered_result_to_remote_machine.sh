#!/bin/bash

# Set SYSCHECK_HOME if not already set.

# 1. First check if SYSCHECK_HOME is set then use that
if [ "x${SYSCHECK_HOME}" = "x" ] ; then
# 2. Check if /etc/syscheck.conf exists then source that (put SYSCHECK_HOME=/path/to/syscheck in ther)
    if [ -e /etc/syscheck.conf ] ; then 
	source /etc/syscheck.conf 
    else
# 3. last resort use default path
	SYSCHECK_HOME="/usr/local/syscheck"
    fi
fi

if [ ! -f ${SYSCHECK_HOME}/syscheck.sh ] ; then echo "$0: Can't find syscheck.sh in SYSCHECK_HOME ($SYSCHECK_HOME)" ;exit ; fi




## Import common definitions ##
. $SYSCHECK_HOME/config/related-scripts.conf

# uniq ID of script (please use in the name of this file also for convinice for finding next availavle number)
SCRIPTID=930

getlangfiles $SCRIPTID 
getconfig $SCRIPTID

ERRNO_1="${SCRIPTID}1"
ERRNO_2="${SCRIPTID}2"

### end config ###

PRINTTOSCREEN=0
if [ "x$1" = "x-h" -o "x$1" = "x--help" ] ; then
	echo "$HELP"
	echo "$ERRNO_1/$DESCR_1 - $HELP_1"
	echo "$ERRNO_2/$DESCR_2 - $HELP_2"
	echo "${SCREEN_HELP}"
	exit
elif [ "x$1" = "x-s" -o  "x$1" = "x--screen" -o \
    "x$2" = "x-s" -o  "x$2" = "x--screen"   ] ; then
    PRINTTOSCREEN=1
fi 



for (( j=0; j < ${#REMOTE_HOSTNAME[@]} ; j++ )){
	printtoscreen "Copying file: ${LOCAL_FILE[$j]} to:${REMOTE_HOSTNAME[$j]} dir:${REMOTE_DIR[$j]} remotreuser:${REMOTE_USER[$j]} sshkey: ${SSHKEY[$j]}"
	SSHCOPYRES=$(${SYSCHECK_HOME}/related-enabled/906_ssh-copy-to-remote-machine.sh "${LOCAL_FILE[$j]}" ${REMOTE_HOSTNAME[$j]} ${REMOTE_DIR[$j]}/${REMOTE_FILE[$j]} ${REMOTE_USER[$j]} ${SSHKEY[$j]})
	if [ $? -ne 0 ] ; then
      		printlogmess ${SCRIPTID} ${SCRIPTINDEX}   $ERROR $ERRNO_2 "$DESCR_2" ${LOCAL_FILE[$j]} "file: ${LOCAL_FILE[$j]} to:${REMOTE_HOSTNAME[$j]} dir:${REMOTE_DIR[$j]} remotreuser:${REMOTE_USER[$j]} sshkey: ${SSHKEY[$j]} result: ${SSHCOPYRES}"
	else
		printlogmess ${SCRIPTID} ${SCRIPTINDEX}   $INFO $ERRNO_1 "$DESCR_1" ${LOCAL_FILE[$j]} ${SSHCOPYRES}
	fi
}


