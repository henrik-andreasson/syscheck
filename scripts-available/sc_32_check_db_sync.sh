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
SCRIPTNAME=db_sync

# uniq ID of script (please use in the name of this file also for convinice for finding next availavle number)
SCRIPTID=32

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


if [ ! -f $SYSCHECK_HOME/database-replication/808-test-table-update-and-check-master-and-slave.sh ] ; then
	printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX} "$ERROR" "${ERRNO[2]}" "${DESCR[2]} missing script, database-replication/808-test-table-update-and-check-master-and-slave.sh"
	exit
fi

SCRIPTINDEX=$(addOneToIndex $SCRIPTINDEX)
. $SYSCHECK_HOME/database-replication/808-test-table-update-and-check-master-and-slave.sh >/dev/null
NODE1=`echo $VALUE_NODE1|awk '{print $2}'`
NODE2=`echo $VALUE_NODE2|awk '{print $2}'`
if [ $NODE1 != $NODE2 ] ;  then
	SYNCDATE=`perl -e "print scalar(localtime($NODE2))"|awk '{print $3,$2,$4,$5}'`
	printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   "$ERROR" "${ERRNO[2]}" "${DESCR[2]} $LASTUPD_NODE1 /$LASTUPD_NODE2 $SYNCDATE"
else
	printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   "$INFO" "${ERRNO[1]}" "${DESCR[1]}"
fi
