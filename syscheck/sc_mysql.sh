#!/bin/sh 
pidfile=/var/run/mysqld.pid
procname=/usr/local/mysql/libexec/mysqld
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
		printlogmess $MYSQL_LEVEL_2 $MYSQL_ERRNO_2 "$MYSQL_DESCR_2"  
		exit 3
	fi
fi

if [ "x$pid" = "x" ] ; then
	printlogmess $MYSQL_LEVEL_2 $MYSQL_ERRNO_2 "$MYSQL_DESCR_2"  
else
	printlogmess $MYSQL_LEVEL_1 $MYSQL_ERRNO_1 "$MYSQL_DESCR_1"
fi

