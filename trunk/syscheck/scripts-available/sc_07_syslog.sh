#!/bin/sh 

# Set default home if not already set.
SYSCHECK_HOME=${SYSCHECK_HOME:-"/usr/local/syscheck"}

## Import common definitions ##
. $SYSCHECK_HOME/resources.sh

# uniq ID of script (please use in the name of this file also for convinice for finding next availavle number)
SCRIPTID=07

ERRNO_1=${SCRIPTID}01
ERRNO_2=${SCRIPTID}02
ERRNO_3=${SCRIPTID}03
ERRNO_4=${SCRIPTID}04

getlangfiles $SCRIPTID
getconfig $SCRIPTID


# help
if [ "x$1" = "x--help" ] ; then
    echo "$0 $SLOG_HELP"
    echo "$ERRNO_1/$SLOG_DESCR_1 - $SLOG_HELP_1"
    echo "$ERRNO_2/$SLOG_DESCR_2 - $SLOG_HELP_2"
    echo "$ERRNO_3/$SLOG_DESCR_3 - $SLOG_HELP_3"
    exit
elif [ "x$1" = "x-s" -o  "x$1" = "x--screen" ] ; then
    PRINTTOSCREEN=1
fi


send_syslog_msg(){
	chkvalue="${RANDOM}_$$"
	logger -p local0.notice "$0, heartbeat loggmsg: $chkvalue"
	sleep 1
	tail -1000 $localsyslogfile | grep "$0, heartbeat loggmsg: $chkvalue"   > /dev/null
	if [ $? -ne 0 ] ; then
                printlogmess $ERROR $ERRNO_1 "$SLOG_DESCR_1"   
		exit 1;
	fi	
}



syslog=`$SYSCHECK_HOME/lib/proc_checker.sh $pidfile $procname` 
if [ "x$syslog" = "x" ] ; then
        printlogmess $ERROR $ERRNO_3 "$SLOG_DESCR_3"
	exit 2;
fi

send_syslog_msg

printlogmess $INFO $ERRNO_4 "$SLOG_DESCR_4"
