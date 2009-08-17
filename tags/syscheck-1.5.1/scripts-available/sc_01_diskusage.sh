#!/bin/bash

# Set default home if not already set.
SYSCHECK_HOME=${SYSCHECK_HOME:-"/usr/local/syscheck"}


## Import common definitions ##
. $SYSCHECK_HOME/resources.sh

# uniq ID of script (please use in the name of this file also for convinice for finding next availavle number)
SCRIPTID=01

getlangfiles $SCRIPTID
getconfig $SCRIPTID
 
ERRNO_1="${SCRIPTID}01"
ERRNO_2="${SCRIPTID}02"

DESCR_1="${DU_DESCR_1}"
DESCR_2="${DU_DESCR_2}"

### local conf ###


if [ "x$1" = "x--help" ] ; then
    echo "$DU_HELP ${DU_PERCENT}%)"
    echo "$ERRNO_1/$DESCR_1"
    echo "$ERRNO_2/$DESCR_2"
    echo "${SCREEN_HELP}"
    exit
elif [ "x$1" = "x-s" -o  "x$1" = "x--screen"  ] ; then
    PRINTTOSCREEN=1
fi 


diskusage () {
	FILESYSTEM=$1
	LIMIT=$2
	PERCENT=`df -h $FILESYSTEM | grep -v Filesystem | awk '{print $5}' | sed 's/%//'`

	if [ $PERCENT -gt $LIMIT ] ; then
                printlogmess $ERROR $ERRNO_2 "$DESCR_2" "$FILESYSTEM" "$PERCENT" "$LIMIT" 
	else
                printlogmess $INFO $ERRNO_1 "$DESCR_1" "$FILESYSTEM" "$PERCENT" "$LIMIT" 
	fi
}


diskusage /  $DU_PERCENT
