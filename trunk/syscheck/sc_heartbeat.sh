#!/bin/sh 
pidfile=/var/run/heartbeat.pid
procname=heartbeat
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
		printlogmess $HA_LEVEL_2 $HA_ERRNO_2 "$HA_DESCR_2"  
		exit 3
	fi
fi

if [ "x$pid" = "x" ] ; then
	printlogmess $HA_LEVEL_2 $HA_ERRNO_2 "$HA_DESCR_2"  
else
	printlogmess $HA_LEVEL_1 $HA_ERRNO_1 "$HA_DESCR_1"
fi

