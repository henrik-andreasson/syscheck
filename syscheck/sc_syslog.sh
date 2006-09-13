#!/bin/sh 

# Set default home if not already set.
SYSCHECK_HOME=${SYSCHECK_HOME:-"/usr/local/syscheck"}

# Import common resources
. $SYSCHECK_HOME/resources.sh

PATH=$PATH:.
pidfile=/var/run/syslog-ng.pid
status=0

DEBUG="/dev/null 2>&1"
if [ "x$1" = "x--debug" ] ; then
	DEBUG="/dev/stdout"
fi

send_syslog_msg(){
	chkvalue="${RANDOM}_$$"
	logger -p local0.notice "$0, heartbeat loggmsg: $chkvalue"
	tail -1000 /var/log/localmessages | grep "$0, heartbeat loggmsg: $chkvalue"  > $DEBUG 
	if [ $? -ne 0 ] ; then
                printlogmess $SLOG_LEVEL_1 $SLOG_ERRNO_1 "$SLOG_DESCR_1"   
		exit 1;
	fi	
}
if [ -f $pidfile ] ; then
	syslog=`proc_checker.sh $pidfile` 
else
	syslog=`ps h -o user,pid,args | grep syslog-ng | grep -v grep` 
	if [ $? -ne 0 ] ; then
	       printlogmess $SLOG_LEVEL_2 $SLOG_ERRNO_2 "$SLOG_DESCR_2"	
               exit 3
	fi
fi

if [ "x$syslog" = "x" ] ; then
        printlogmess $SLOG_LEVEL_3 $SLOG_ERRNO_3 "$SLOG_DESCR_3"
	exit 2;
else
	echo "syslog pid:" > $DEBUG
	echo $syslog > $DEBUG
fi

send_syslog_msg

printlogmess $SLOG_LEVEL_4 $SLOG_ERRNO_4 "$SLOG_DESCR_4"
