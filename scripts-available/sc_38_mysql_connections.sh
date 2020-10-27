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
SCRIPTNAME=mysql_connections

# uniq ID of script (please use in the name of this file also for convinice for finding next availavle number)
SCRIPTID=38

# how many info/warn/error messages
NO_OF_ERR=5

initscript $SCRIPTID $NO_OF_ERR

default_script_getopt $*

# main part of script

threads_connected=$(mysqladmin extended-status | grep "Threads_connected" | awk '{print $4}')
if [ "x${threads_connected}" = "x" ] ; then
  printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e "${ERRNO[2]}" -d "${DESCR[2]}" -1 "${threads_connected}"
  exit
fi

max_connections=$(mysqladmin variables | grep "| max_connections"  | awk '{print $4}')
if [ "x${max_connections}" = "x" ] ; then
  printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e "${ERRNO[3]}" -d "${DESCR[3]}" -1 "${max_connections}"
  exit
fi

SCRIPTINDEX=$(addOneToIndex $SCRIPTINDEX)

percent_used=$((100 * ${threads_connected} / ${max_connections}))
if [ ${percent_used} -gt "${ERROR_PERCENT}" ]; then
  printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e "${ERRNO[4]}" -d "${DESCR[4]}" -1 "${threads_connected}" -2 "${max_connections}" -3 "${percent_used}"
elif [ ${percent_used} -gt "${WARN_PERCENT}" ]; then
  printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e "${ERRNO[5]}" -d "${DESCR[5]}" -1 "${threads_connected}" -2 "${max_connections}" -3 "${percent_used}"
else
  printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $INFO -e ${ERRNO[1]} -d "${DESCR[1]}" -1 "${threads_connected}" -2 "${max_connections}" -3 "${percent_used}"
fi
