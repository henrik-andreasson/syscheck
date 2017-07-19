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
SCRIPTID=22

# Index is used to uniquely identify one test done by the script (a harddrive, crl or cert)
SCRIPTINDEX=00

## Import common definitions ##
. $SYSCHECK_HOME/config/syscheck-scripts.conf

getlangfiles $SCRIPTID
getconfig $SCRIPTID

BOKS_REPLICA_ERRNO_1=01
BOKS_REPLICA_ERRNO_2=02
BOKS_REPLICA_ERRNO_3=03


# help
if [ "x$1" = "x--help" ] ; then
    echo "$0 $BOKS_REPLICA_HELP"
    echo "$BOKS_REPLICA_ERRNO_1/$BOKS_REPLICA_DESCR_1 - $BOKS_REPLICA_HELP_1"
    echo "$BOKS_REPLICA_ERRNO_2/$BOKS_REPLICA_DESCR_2 - $BOKS_REPLICA_HELP_2"
    exit
elif [ "x$1" = "x-s" -o  "x$1" = "x--screen"  ] ; then
    PRINTTOSCREEN=1
fi


NUMBER_OF_NOT_RUNNING_PROCS=0
NAMES_OF_NOT_RUNNING_PROCS=""

pidfile=/var/opt/boksm/LCK/servc4
procname=boks_servc
pidinfo=`${SYSCHECK_HOME}/lib/proc_checker.sh $pidfile $procname` 
if [ "x$pidinfo" = "x" ] ; then
	NUMBER_OF_NOT_RUNNING_PROCS=`expr $NUMBER_OF_NOT_RUNNING_PROCS + 1`
	NAMES_OF_NOT_RUNNING_PROCS="$NAMES_OF_NOT_RUNNING_PROCS $procname"
fi

pidfile=/var/opt/boksm/LCK/clntd
procname=boks_clntd
pidinfo=`${SYSCHECK_HOME}/lib/proc_checker.sh $pidfile $procname` 
if [ "x$pidinfo" = "x" ] ; then
	NUMBER_OF_NOT_RUNNING_PROCS=`expr $NUMBER_OF_NOT_RUNNING_PROCS + 1`
	NAMES_OF_NOT_RUNNING_PROCS="$NAMES_OF_NOT_RUNNING_PROCS $procname"
fi


pidfile=/var/opt/boksm/LCK/boks_init
procname=boks_init
pidinfo=`${SYSCHECK_HOME}/lib/proc_checker.sh $pidfile $procname` 
if [ "x$pidinfo" = "x" ] ; then
	NUMBER_OF_NOT_RUNNING_PROCS=`expr $NUMBER_OF_NOT_RUNNING_PROCS + 1`
	NAMES_OF_NOT_RUNNING_PROCS="$NAMES_OF_NOT_RUNNING_PROCS $procname"
fi



procname="boks_bridge.*servm.r"
pidinfo=`${SYSCHECK_HOME}/lib/proc_checker.sh 0 $procname` 
if [ "x$pidinfo" = "x" ] ; then
	NUMBER_OF_NOT_RUNNING_PROCS=`expr $NUMBER_OF_NOT_RUNNING_PROCS + 1`
	NAMES_OF_NOT_RUNNING_PROCS="$NAMES_OF_NOT_RUNNING_PROCS $procname"
fi


procname="boks_bridge.*servc.s"
pidinfo=`${SYSCHECK_HOME}/lib/proc_checker.sh 0 $procname` 
if [ "x$pidinfo" = "x" ] ; then
	NUMBER_OF_NOT_RUNNING_PROCS=`expr $NUMBER_OF_NOT_RUNNING_PROCS + 1`
	NAMES_OF_NOT_RUNNING_PROCS="$NAMES_OF_NOT_RUNNING_PROCS $procname"
fi


procname="boks_bridge.*servc.r"
pidinfo=`${SYSCHECK_HOME}/lib/proc_checker.sh 0 $procname` 
if [ "x$pidinfo" = "x" ] ; then
	NUMBER_OF_NOT_RUNNING_PROCS=`expr $NUMBER_OF_NOT_RUNNING_PROCS + 1`
	NAMES_OF_NOT_RUNNING_PROCS="$NAMES_OF_NOT_RUNNING_PROCS $procname"
fi


procname="boks_bridge.*master.s"
pidinfo=`${SYSCHECK_HOME}/lib/proc_checker.sh 0 $procname` 
if [ "x$pidinfo" = "x" ] ; then
	NUMBER_OF_NOT_RUNNING_PROCS=`expr $NUMBER_OF_NOT_RUNNING_PROCS + 1`
	NAMES_OF_NOT_RUNNING_PROCS="$NAMES_OF_NOT_RUNNING_PROCS $procname"
fi


procname="boks_authd"
pidinfo=`${SYSCHECK_HOME}/lib/proc_checker.sh 0 $procname` 
if [ "x$pidinfo" = "x" ] ; then
	NUMBER_OF_NOT_RUNNING_PROCS=`expr $NUMBER_OF_NOT_RUNNING_PROCS + 1`
	NAMES_OF_NOT_RUNNING_PROCS="$NAMES_OF_NOT_RUNNING_PROCS $procname"
fi


procname="boks_csspd"
pidinfo=`${SYSCHECK_HOME}/lib/proc_checker.sh 0 $procname` 
if [ "x$pidinfo" = "x" ] ; then
	NUMBER_OF_NOT_RUNNING_PROCS=`expr $NUMBER_OF_NOT_RUNNING_PROCS + 1`
	NAMES_OF_NOT_RUNNING_PROCS="$NAMES_OF_NOT_RUNNING_PROCS $procname"
fi


procname="boks_udsqd"
pidinfo=`${SYSCHECK_HOME}/lib/proc_checker.sh 0 $procname` 
if [ "x$pidinfo" = "x" ] ; then
	NUMBER_OF_NOT_RUNNING_PROCS=`expr $NUMBER_OF_NOT_RUNNING_PROCS + 1`
	NAMES_OF_NOT_RUNNING_PROCS="$NAMES_OF_NOT_RUNNING_PROCS $procname"
fi



SCRIPTINDEX=$(addOneToIndex $SCRIPTINDEX)

if [ $NUMBER_OF_NOT_RUNNING_PROCS -gt 0 ] ; then
        printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   $ERROR $BOKS_REPLICA_ERRNO_3 "$BOKS_REPLICA_DESCR_2" $NAMES_OF_NOT_RUNNING_PROCS
	exit 2
else
        printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   $INFO $BOKS_REPLICA_ERRNO_1 "$BOKS_REPLICA_DESCR_1"
	exit 0
fi

