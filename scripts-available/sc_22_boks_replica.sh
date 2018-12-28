#!/bin/bash

SYSCHECK_HOME="${SYSCHECK_HOME:-/opt/syscheck}" # use default if  unset
if [ ! -f ${SYSCHECK_HOME}/syscheck.sh ] ; then
  echo "Can't find $SYSCHECK_HOME/syscheck.sh"
  exit
fi

if [ ! -f ${SYSCHECK_HOME}/syscheck.sh ] ; then echo "Can't find $SYSCHECK_HOME/syscheck.sh" ;exit ; fi

## Import common definitions ##
source $SYSCHECK_HOME/config/syscheck-scripts.conf

# script name, used when integrating with nagios/icinga
SCRIPTNAME=boks

# uniq ID of script (please use in the name of this file also for convinice for finding next availavle number)
SCRIPTID=22

# how many info/warn/error messages
NO_OF_ERR=2
initscript $SCRIPTID $NO_OF_ERR

# get command line arguments
INPUTARGS=`/usr/bin/getopt --options "hsvc" --long "help,screen,verbose,cert" -- "$@"`
if [ $? != 0 ] ; then schelp ; fi
#echo "TEMP: >$TEMP<"
eval set -- "$INPUTARGS"

while true; do
  case "$1" in
    -s|--screen  ) PRINTTOSCREEN=1; shift;;
    -v|--verbose ) PRINTVERBOSESCREEN=1 ; shift;;
    -c|--cert )   CERTFILE=$2; shift 2;;
    -h|--help )   schelp;exit;shift;;
    --) break;;
  esac
done

# main part of script

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
        printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   $ERROR $BOKS_REPLICA_ERRNO[2] "$BOKS_REPLICA_DESCR[2]" $NAMES_OF_NOT_RUNNING_PROCS
	exit 2
else
        printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   $INFO $BOKS_REPLICA_ERRNO[1] "$BOKS_REPLICA_DESCR[1]"
	exit 0
fi
