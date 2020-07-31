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

default_script_getopt $*

# main part of script


if [ ! -f $SYSCHECK_HOME/database-replication/808-test-table-update-and-check-master-and-slave.sh ] ; then
	printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l "$ERROR" -e "${ERRNO[2]}" -d "${DESCR[2]} missing script"
	exit
fi

SCRIPTINDEX=$(addOneToIndex $SCRIPTINDEX)
echo "This script is broken"
exit
NODE1=`echo $VALUE_NODE1|awk '{print $2}'`
NODE2=`echo $VALUE_NODE2|awk '{print $2}'`
if [ $NODE1 != $NODE2 ] ;  then
	printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l "$ERROR" -e "${ERRNO[2]}" -d "${DESCR[2]} $LASTUPD_NODE1 /$LASTUPD_NODE2 $SYNCDATE"
else
	printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l "$INFO"  -e "${ERRNO[1]}" -d "${DESCR[1]}"
fi
