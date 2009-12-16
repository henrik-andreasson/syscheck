#!/bin/sh

# Set default home if not already set.
SYSCHECK_HOME=${SYSCHECK_HOME:-"/usr/local/syscheck"}

## Import common definitions ##
. $SYSCHECK_HOME/resources.sh

# uniq ID of script (please use in the name of this file also for convinice for finding next availavle number)
SCRIPTID=924

getlangfiles $SCRIPTID 
getconfig $SCRIPTID

ERRNO_1="${SCRIPTID}1"
ERRNO_2="${SCRIPTID}2"
ERRNO_3="${SCRIPTID}3"

### end config ###

PRINTTOSCREEN=1
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


# Make sure you add quotation marks for the first argument when adding new files that should be copied, for exampel.

if [ ! -f ${SYSCHECK_HOME}/related-enabled/923-rsync-to-remote-machine.sh ] ; then
    printlogmess $ERROR $ERRNO_2 "$DESCR_2"  
    exit
fi

for (( j=0; j < ${#LOCAL_PATH[@]} ; j++ )){
	printtoscreen "Copying file: ${LOCAL_PATH[$j]} to:${REMOTE_HOST[$j]} dir:${REMOTE_DIR[$j]} remotreuser:${REMOTE_USER[$j]} sshkey: ${SSHKEY[$j]}"
	${SYSCHECK_HOME}/related-enabled/923-rsync-to-remote-machine.sh "${LOCAL_PATH[$j]}" ${REMOTE_HOST[$j]} ${REMOTE_DIR[$j]} ${REMOTE_USER[$j]} ${SSHKEY[$j]}
	if [ $? -eq 0 ] ; then
	    printlogmess $INFO $ERRNO_1 "$DESCR_1" "${LOCAL_PATH[$j]} ${REMOTE_HOST[$j]} ${REMOTE_DIR[$j]} ${REMOTE_USER[$j]} ${SSHKEY[$j]}"  
	
	else
	    printlogmess $ERROR $ERRNO_3 "$DESCR_3" "${LOCAL_PATH[$j]} ${REMOTE_HOST[$j]} ${REMOTE_DIR[$j]} ${REMOTE_USER[$j]} ${SSHKEY[$j]}"   
	    
	fi
	
}

