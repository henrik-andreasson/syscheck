#!/bin/sh 

# Set default home if not already set.
SYSCHECK_HOME=${SYSCHECK_HOME:-"/usr/local/syscheck"}

## Import common definitions ##
. $SYSCHECK_HOME/resources.sh

SCRIPTID=12

getlangfiles $SCRIPTID ;
getconfig $SCRIPTID

MYSQL_ERRNO_1=${SCRIPTID}01
MYSQL_ERRNO_2=${SCRIPTID}02
MYSQL_ERRNO_3=${SCRIPTID}03

# help
if [ "x$1" = "x--help" ] ; then
    echo "$0 $MYSQL_HELP"
    echo "$MYSQL_ERRNO_1/$MYSQL_DESCR_1 - $MYSQL_HELP_1"
    echo "$MYSQL_ERRNO_2/$MYSQL_DESCR_2 - $MYSQL_HELP_2"
    exit
elif [ "x$1" = "x-s" -o  "x$1" = "x--screen"  ] ; then
    PRINTTOSCREEN=1
fi


pid=`$SYSCHECK_HOME/lib/proc_checker.sh $pidfile $procname` 
if [ "x$pid" = "x" ] ; then
    printlogmess $ERROR $MYSQL_ERRNO_2 "$MYSQL_DESCR_2"  
    exit 3
else
    printlogmess $INFO $MYSQL_ERRNO_1 "$MYSQL_DESCR_1"
fi

