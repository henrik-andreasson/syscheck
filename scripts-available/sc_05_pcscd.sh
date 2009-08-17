#!/bin/sh 

# Set default home if not already set.
SYSCHECK_HOME=${SYSCHECK_HOME:-"/usr/local/syscheck"}

## Import common definitions ##
. $SYSCHECK_HOME/resources.sh

SCRIPTID=05

getlangfiles $SCRIPTID 
getconfig $SCRIPTID

PCSCD_ERRNO_1=${SCRIPTID}01
PCSCD_ERRNO_2=${SCRIPTID}02
PCSCD_ERRNO_3=${SCRIPTID}03

# help
if [ "x$1" = "x--help" ] ; then
    echo "$0 $PCSCD_HELP"
    echo "$PCSCD_ERRNO_1/$PCSCD_DESCR_1 - $PCSCD_HELP_1"
    echo "$PCSCD_ERRNO_2/$PCSCD_DESCR_2 - $PCSCD_HELP_2"
    echo "$PCSCD_ERRNO_3/$PCSCD_DESCR_3 - $PCSCD_HELP_3"
    exit
elif [ "x$1" = "x-s" -o  "x$1" = "x--screen"  ] ; then
    PRINTTOSCREEN=1
fi


if [ -f $pidfile ] ; then
	pid=`${SYSCHECK_HOME}/lib/proc_checker.sh $pidfile` 
else
	pid=`ps -ef | grep $procname | grep -v grep | awk '{print $2}'` 
	if [ "x$pid" = "x" ] ; then
		printlogmess $ERROR $PCSCD_ERRNO_2 "$PCSCD_DESCR_2"  
		exit 3
	fi
fi

if [ "x$pid" = "x" ] ; then
	printlogmess $ERROR $PCSCD_ERRNO_2 "$PCSCD_DESCR_2"  
else
	printlogmess $INFO $PCSCD_ERRNO_1 "$PCSCD_DESCR_1"
fi

