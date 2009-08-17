#!/bin/bash

# Set default home if not already set.
SYSCHECK_HOME=${SYSCHECK_HOME:-"/usr/local/syscheck"}


## Import common definitions ##
. $SYSCHECK_HOME/resources.sh

# uniq ID of script (please use in the name of this file also for convinice for finding next availavle number)
SCRIPTID=01

DU_ERRNO_1=${SCRIPTID}01
DU_ERRNO_2=${SCRIPTID}02
DU_ERRNO_3=${SCRIPTID}03

DU_PERCENT=80

if [ "x$1" = "x--help" ] ; then
	echo "Script that checks that the disk have enougth free space on the hard drive."
	echo "The limit is configured in the script (limit: ${DU_PERCENT}%)"
	echo "to run with output directed to screen:"
	echo "$0 <-s|--screen>"
	exit
elif [ "x$1" = "x-s" -o  "x$1" = "x--screen"  ] ; then
    PRINTTOSCREEN=1
fi 


diskusage () {
	FILESYSTEM=$1
	LIMIT=$2
	PERCENT=`df -h $FILESYSTEM | grep -v Filesystem | awk '{print $5}' | sed 's/%//'`

	if [ $PERCENT -gt $LIMIT ] ; then
                printlogmess $ERROR $DU_ERRNO_2 "$DU_DESCR_2" "$FILESYSTEM" "$PERCENT" "$LIMIT" 
	else
                printlogmess $INFO $DU_ERRNO_1 "$DU_DESCR_1" "$FILESYSTEM" "$PERCENT" "$LIMIT" 
	fi
}


diskusage /  $DU_PERCENT
