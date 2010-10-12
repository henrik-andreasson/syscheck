#!/bin/bash

# Set default home if not already set.
SYSCHECK_HOME=${SYSCHECK_HOME:-"/usr/local/syscheck"}


## Import common definitions ##
. $SYSCHECK_HOME/config/syscheck-scripts.conf

# uniq ID of script (please use in the name of this file also for convinice for finding next availavle number)
SCRIPTID=01

getlangfiles $SCRIPTID
getconfig $SCRIPTID
 
ERRNO_1="${SCRIPTID}01"
ERRNO_2="${SCRIPTID}02"
ERRNO_3="${SCRIPTID}03"

DESCR_1="${DU_DESCR_1}"
DESCR_2="${DU_DESCR_2}"
DESCR_3="${DU_DESCR_3}"

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
	DFPH=`df -Ph $FILESYSTEM 2>&1`

	if [ $? -ne 0 ] ; then
		printlogmess $ERROR $ERRNO_3 "$DESCR_3" "$FILESYSTEM" "$DFPH"
	else

  		PERCENT=`df -Ph $FILESYSTEM | grep -v Filesystem| awk '{print $5}' | sed 's/%//'`
		if [ $PERCENT -gt $LIMIT ] ; then
       	         	printlogmess $ERROR $ERRNO_2 "$DESCR_2" "$FILESYSTEM" "$PERCENT" "$LIMIT" 
		else
                	printlogmess $INFO $ERRNO_1 "$DESCR_1" "$FILESYSTEM" "$PERCENT" "$LIMIT" 
		fi
	fi
}


for (( i = 0 ;  i < ${#FILESYSTEM[@]} ; i++ )) ; do
	diskusage ${FILESYSTEM[$i]}  ${USAGEPERCENT[$i]}
done

