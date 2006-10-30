#!/bin/sh 
pidfile=/var/run/pcscd.pid
procname=/usr/local/sbin/pcscd
status=0

# Set default home if not already set.
SYSCHECK_HOME=${SYSCHECK_HOME:-"/usr/local/syscheck"}

# Import common resources
. $SYSCHECK_HOME/resources.sh

if [ -f $pidfile ] ; then
	pid=`proc_checker.sh $pidfile` 
else
	pid=`ps -ef | grep $procname | grep -v grep | awk '{print $2}'` 
	if [ "x$pid" = "x" ] ; then
		printlogmess $PCSCD_LEVEL_2 $PCSCD_ERRNO_2 "$PCSCD_DESCR_2"  
		exit 3
	fi
fi

if [ "x$pid" = "x" ] ; then
	printlogmess $PCSCD_LEVEL_2 $PCSCD_ERRNO_2 "$PCSCD_DESCR_2"  
else
	printlogmess $PCSCD_LEVEL_1 $PCSCD_ERRNO_1 "$PCSCD_DESCR_1"
fi

