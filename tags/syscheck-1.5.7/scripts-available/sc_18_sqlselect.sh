#!/bin/sh 

# Set default home if not already set.
SYSCHECK_HOME=${SYSCHECK_HOME:-"/usr/local/syscheck"}

## Import common definitions ##
. $SYSCHECK_HOME/resources.sh

SCRIPTID=18

getlangfiles $SCRIPTID
getconfig $SCRIPTID

SQLSELECT_ERRNO_1=${SCRIPTID}01
SQLSELECT_ERRNO_2=${SCRIPTID}02
SQLSELECT_ERRNO_3=${SCRIPTID}03

# help
if [ "x$1" = "x--help" ] ; then
    echo "$0 $SQLSELECT_HELP"
    echo "$SQLSELECT_ERRNO_1/$SQLSELECT_DESCR_1 - $SQLSELECT_HELP_1"
    echo "$SQLSELECT_ERRNO_2/$SQLSELECT_DESCR_2 - $SQLSELECT_HELP_2"
    exit
elif [ "x$1" = "x-s" -o  "x$1" = "x--screen"  ] ; then
    PRINTTOSCREEN=1
fi



if [ $? -ne 0 ] ; then
    printlogmess $ERROR $SQLSELECT_ERRNO_2 "$SQLSELECT_DESCR_2"  
    exit 3
else
    printlogmess $INFO $SQLSELECT_ERRNO_1 "$SQLSELECT_DESCR_1"
fi

