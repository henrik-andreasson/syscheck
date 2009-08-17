#!/bin/bash

# Set default home if not already set.
SYSCHECK_HOME=${SYSCHECK_HOME:-"/usr/local/syscheck"}

## Import common definitions ##
. $SYSCHECK_HOME/resources.sh

# uniq ID of script (please use in the name of this file also for convinice for finding next availavle number)
SCRIPTID=903

getlangfiles $SCRIPTID
getconfig $SCRIPTID

BAK_ERRNO_1="${SCRIPTID}1"
BAK_ERRNO_2="${SCRIPTID}2"
BAK_ERRNO_3="${SCRIPTID}3"


PRINTTOSCREEN=
if [ "x$1" = "x-h" -o "x$1" = "x--help" ] ; then
	echo "$HSM_HELP"
	echo "$ERRNO_1/$DESCR_1 "
	echo "$ERRNO_2/$DESCR_2 "
	echo "${SCREEN_HELP}"
	exit
elif [ "x$1" == "x-s" -o  "x$1" == "x--screen" -o \
    "x$2" == "x-s" -o  "x$2" == "x--screen"   ] ; then
    PRINTTOSCREEN=1
fi 


DATE=`date +%Y%m%d-%H.%M`

tar -c --directory $HSMDIR -f $FULLFILENAME local

if [ $? = 0 ] ; then
    gzip $FULLFILENAME
    if [ $? = 0 ] ; then
	printlogmess $INFO $ERRNO_1 "$DESCR_1" 
    else
	printlogmess $ERROR $ERRNO_2 "$DESCR_2"
    fi  
else
    printlogmess $ERROR $ERRNO_2 "$DESCR_2"
fi 



