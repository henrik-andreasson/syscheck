#!/bin/sh 

# Set default home if not already set.
SYSCHECK_HOME=${SYSCHECK_HOME:-"/usr/local/syscheck"}

# uniq ID of script (please use in the name of this file also for convinice for finding next availavle number)
SCRIPTID=23

## Import common definitions ##
. $SYSCHECK_HOME/resources.sh

getlangfiles $SCRIPTID ;
getconfig $SCRIPTID

RSA_AXM_ERRNO_1=${SCRIPTID}01
RSA_AXM_ERRNO_2=${SCRIPTID}02
RSA_AXM_ERRNO_3=${SCRIPTID}03


# help
if [ "x$1" = "x--help" ] ; then
    echo "$0 $RSA_AXM_HELP"
    echo "$RSA_AXM_ERRNO_1/$RSA_AXM_DESCR_1 - $RSA_AXM_HELP_1"
    echo "$RSA_AXM_ERRNO_2/$RSA_AXM_DESCR_2 - $RSA_AXM_HELP_2"
    exit
elif [ "x$1" = "x-s" -o  "x$1" = "x--screen"  ] ; then
    PRINTTOSCREEN=1
fi


NUMBER_OF_NOT_RUNNING_PROCS=0
NAMES_OF_NOT_RUNNING_PROCS=""

pidfile=/opt/ctrust/server-60/var/aserver.pid
pid=`cat ${pidfile} | cut -f2 -d\:`
procname='DAuth'
pidinfo=`${SYSCHECK_HOME}/lib/proc_checker.sh $pid $procname` 
if [ $? -ne 0 ] ; then 
        NUMBER_OF_NOT_RUNNING_PROCS=`expr $NUMBER_OF_NOT_RUNNING_PROCS + 1`
        NAMES_OF_NOT_RUNNING_PROCS="$NAMES_OF_NOT_RUNNING_PROCS $procname"
fi
if [ "x$pidinfo" = "x" ] ; then
	NUMBER_OF_NOT_RUNNING_PROCS=`expr $NUMBER_OF_NOT_RUNNING_PROCS + 1`
	NAMES_OF_NOT_RUNNING_PROCS="$NAMES_OF_NOT_RUNNING_PROCS $procname"
fi

pidfile=/opt/ctrust/server-60/var/dispatcher.pid
pid=`cat ${pidfile} | cut -f2 -d\:`
procname='DDisp'
pidinfo=`${SYSCHECK_HOME}/lib/proc_checker.sh $pid $procname` 
if [ $? -ne 0 ] ; then
        NUMBER_OF_NOT_RUNNING_PROCS=`expr $NUMBER_OF_NOT_RUNNING_PROCS + 1`
        NAMES_OF_NOT_RUNNING_PROCS="$NAMES_OF_NOT_RUNNING_PROCS $procname"
fi

if [ "x$pidinfo" = "x" ] ; then
	NUMBER_OF_NOT_RUNNING_PROCS=`expr $NUMBER_OF_NOT_RUNNING_PROCS + 1`
	NAMES_OF_NOT_RUNNING_PROCS="$NAMES_OF_NOT_RUNNING_PROCS $procname"
fi


pidfile=/opt/ctrust/server-60/var/eserver.pid
pid=`cat ${pidfile} | cut -f2 -d\:`
procname='DEnt'
pidinfo=`${SYSCHECK_HOME}/lib/proc_checker.sh $pid $procname` 
if [ $? -ne 0 ] ; then
        NUMBER_OF_NOT_RUNNING_PROCS=`expr $NUMBER_OF_NOT_RUNNING_PROCS + 1`
        NAMES_OF_NOT_RUNNING_PROCS="$NAMES_OF_NOT_RUNNING_PROCS $procname"
fi

if [ "x$pidinfo" = "x" ] ; then
	NUMBER_OF_NOT_RUNNING_PROCS=`expr $NUMBER_OF_NOT_RUNNING_PROCS + 1`
	NAMES_OF_NOT_RUNNING_PROCS="$NAMES_OF_NOT_RUNNING_PROCS $procname"
fi


if [ $NUMBER_OF_NOT_RUNNING_PROCS -gt 0 ] ; then
        printlogmess $ERROR $RSA_AXM_ERRNO_3 "$RSA_AXM_DESCR_2" $NAMES_OF_NOT_RUNNING_PROCS
	exit 2
else
        printlogmess $INFO $RSA_AXM_ERRNO_1 "$RSA_AXM_DESCR_1"
	exit 0
fi

