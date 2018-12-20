#!/bin/bash 

# Set SYSCHECK_HOME if not already set.

# 1. First check if SYSCHECK_HOME is set then use that
if [ "x${SYSCHECK_HOME}" = "x" ] ; then
# 2. Check if /etc/syscheck.conf exists then source that (put SYSCHECK_HOME=/path/to/syscheck in ther)
    if [ -e /etc/syscheck.conf ] ; then 
	source /etc/syscheck.conf 
    else
# 3. last resort use default path
	SYSCHECK_HOME="/opt/syscheck"
    fi
fi

if [ ! -f ${SYSCHECK_HOME}/syscheck.sh ] ; then echo "$0: Can't find syscheck.sh in SYSCHECK_HOME ($SYSCHECK_HOME)" ;exit ; fi




## Import common definitions ##
source $SYSCHECK_HOME/config/syscheck-scripts.conf

# uniq ID of script (please use in the name of this file also for convinice for finding next availavle number)
SCRIPTID=07

# Index is used to uniquely identify one test done by the script (a harddrive, crl or cert)
SCRIPTINDEX=00

ERRNO_1=01
ERRNO_2=02
ERRNO_3=03
ERRNO_4=04

getlangfiles $SCRIPTID
getconfig $SCRIPTID


# help
if [ "x$1" = "x--help" ] ; then
    echo "$0 $HELP"
    echo "$ERRNO_1/$DESCR_1 - $HELP_1"
    echo "$ERRNO_2/$DESCR_2 - $HELP_2"
    echo "$ERRNO_3/$DESCR_3 - $HELP_3"
    exit
elif [ "x$1" = "x-s" -o  "x$1" = "x--screen" ] ; then
    PRINTTOSCREEN=1
fi


send_syslog_msg(){
	chkvalue="${RANDOM}_$$"
	logger -p local0.notice "$0, syscheck test message: $chkvalue"
	sleep 1
	tail -1000 $localsyslogfile | grep "$0, syscheck test message: $chkvalue"   > /dev/null
	if [ $? -ne 0 ] ; then
                printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   $ERROR $ERRNO_1 "$DESCR_1"   
		exit 1;
	else
		printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   $INFO $ERRNO_4 "$DESCR_4"

	fi	
}



syslog=`$SYSCHECK_HOME/lib/proc_checker.sh $pidfile $procname` 
if [ "x$syslog" = "x" ] ; then
        printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   $ERROR $ERRNO_3 "$DESCR_3"
	exit 2;
fi

SCRIPTINDEX=$(addOneToIndex $SCRIPTINDEX)

send_syslog_msg

