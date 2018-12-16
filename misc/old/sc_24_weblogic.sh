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




# uniq ID of script (please use in the name of this file also for convinice for finding next availavle number)
SCRIPTID=24

## Import common definitions ##
source $SYSCHECK_HOME/config/syscheck-scripts.conf

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
        printlogmess ${SCRIPTID} ${SCRIPTINDEX}   $ERROR $WEBLOGIC_ERRNO_3 "$WEBLOGIC_DESCR_2" "$NAMES_OF_NOT_RUNNING_PROCS"
	exit 2
else
        printlogmess ${SCRIPTID} ${SCRIPTINDEX}   $INFO $WEBLOGIC_ERRNO_1 "$WEBLOGIC_DESCR_1"
	exit 0
fi

