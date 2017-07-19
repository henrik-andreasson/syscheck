#!/bin/bash 

# Set SYSCHECK_HOME if not already set.

# 1. First check if SYSCHECK_HOME is set then use that
if [ "x${SYSCHECK_HOME}" = "x" ] ; then
# 2. Check if /etc/syscheck.conf exists then source that (put SYSCHECK_HOME=/path/to/syscheck in ther)
    if [ -e /etc/syscheck.conf ] ; then 
	source /etc/syscheck.conf 
    else
# 3. last resort use default path
	SYSCHECK_HOME="/usr/local/syscheck"
    fi
fi

if [ ! -f ${SYSCHECK_HOME}/syscheck.sh ] ; then echo "$0: Can't find syscheck.sh in SYSCHECK_HOME ($SYSCHECK_HOME)" ;exit ; fi

# uniq ID of script (please use in the name of this file also for convinice for finding next availavle number)
SCRIPTID=23

# Index is used to uniquely identify one test done by the script (a harddrive, crl or cert)
SCRIPTINDEX=00

## Import common definitions ##
. $SYSCHECK_HOME/config/syscheck-scripts.conf

getlangfiles $SCRIPTID ;
getconfig $SCRIPTID

RSA_AXM_ERRNO_1=01
RSA_AXM_ERRNO_2=02
RSA_AXM_ERRNO_3=03


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
pid=$(cat ${pidfile} 2>/dev/null | cut -f2 -d\: )
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
pid=$(cat ${pidfile} 2>/dev/null | cut -f2 -d\: )
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
pid=$(cat ${pidfile} 2>/dev/null | cut -f2 -d\: )
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

SCRIPTINDEX=$(addOneToIndex $SCRIPTINDEX)

if [ $NUMBER_OF_NOT_RUNNING_PROCS -gt 0 ] ; then
        printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   $ERROR $RSA_AXM_ERRNO_3 "$RSA_AXM_DESCR_2" $NAMES_OF_NOT_RUNNING_PROCS
	exit 2
else
        printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   $INFO $RSA_AXM_ERRNO_1 "$RSA_AXM_DESCR_1"
	exit 0
fi

