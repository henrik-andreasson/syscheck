#!/bin/sh 

# Set default home if not already set.
SYSCHECK_HOME=${SYSCHECK_HOME:-"/usr/local/syscheck"}

# uniq ID of script (please use in the name of this file also for convinice for finding next availavle number)
SCRIPTID=24

## Import common definitions ##
. $SYSCHECK_HOME/resources.sh

getlangfiles $SCRIPTID ;
getconfig $SCRIPTID

WEBLOGIC_ERRNO_1=${SCRIPTID}01
WEBLOGIC_ERRNO_2=${SCRIPTID}02
WEBLOGIC_ERRNO_3=${SCRIPTID}03


# help
if [ "x$1" = "x--help" ] ; then
    echo "$0 $WEBLOGIC_HELP"
    echo "$WEBLOGIC_ERRNO_1/$WEBLOGIC_DESCR_1 - $WEBLOGIC_HELP_1"
    echo "$WEBLOGIC_ERRNO_2/$WEBLOGIC_DESCR_2 - $WEBLOGIC_HELP_2"
    exit
elif [ "x$1" = "x-s" -o  "x$1" = "x--screen"  ] ; then
    PRINTTOSCREEN=1
fi


NUMBER_OF_NOT_RUNNING_PROCS=0
NAMES_OF_NOT_RUNNING_PROCS=""

pidfile=/opt/wls/user_projects/domains/amem1/weblogic.pid
procname='startWebLogic.sh'
pidinfo=`${SYSCHECK_HOME}/lib/proc_checker.sh $pidfile $procname` 
if [ $? -ne 0 ] ; then 
        NUMBER_OF_NOT_RUNNING_PROCS=`expr $NUMBER_OF_NOT_RUNNING_PROCS + 1`
        NAMES_OF_NOT_RUNNING_PROCS="$NAMES_OF_NOT_RUNNING_PROCS $procname"
fi
if [ "x$pidinfo" = "x" ] ; then
	NUMBER_OF_NOT_RUNNING_PROCS=`expr $NUMBER_OF_NOT_RUNNING_PROCS + 1`
	NAMES_OF_NOT_RUNNING_PROCS="$NAMES_OF_NOT_RUNNING_PROCS $procname"
fi


procname='Dweblogic'
pidinfo=`${SYSCHECK_HOME}/lib/proc_checker.sh - $procname` 
if [ $? -ne 0 ] ; then 
        NUMBER_OF_NOT_RUNNING_PROCS=`expr $NUMBER_OF_NOT_RUNNING_PROCS + 1`
        NAMES_OF_NOT_RUNNING_PROCS="$NAMES_OF_NOT_RUNNING_PROCS $procname"
fi
if [ "x$pidinfo" = "x" ] ; then
	NUMBER_OF_NOT_RUNNING_PROCS=`expr $NUMBER_OF_NOT_RUNNING_PROCS + 1`
	NAMES_OF_NOT_RUNNING_PROCS="$NAMES_OF_NOT_RUNNING_PROCS $procname"
fi


if [ $NUMBER_OF_NOT_RUNNING_PROCS -gt 0 ] ; then
        printlogmess $ERROR $WEBLOGIC_ERRNO_3 "$WEBLOGIC_DESCR_2" "$NAMES_OF_NOT_RUNNING_PROCS"
	exit 2
else
        printlogmess $INFO $WEBLOGIC_ERRNO_1 "$WEBLOGIC_DESCR_1"
	exit 0
fi

