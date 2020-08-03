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
SCRIPTNAME=sql_select

# uniq ID of script (please use in the name of this file also for convinice for finding next availavle number)
SCRIPTID=18

# how many info/warn/error messages
NO_OF_ERR=2
initscript $SCRIPTID $NO_OF_ERR
getconfig "mariadb"

default_script_getopt $*

# main part of script

SCRIPTINDEX=$(addOneToIndex $SCRIPTINDEX)
status=$(echo "SELECT * FROM $DB_TEST_TABLE LIMIT 1"|$MYSQL_BIN $DB_NAME -u root --password=$MYSQLROOT_PASSWORD 2>&1 > /dev/null)
if [ $? -ne 0 ] ; then
    printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[2]} -d "${DESCR[2]}"
    exit 3
else
    printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $INFO -e ${ERRNO[1]} -d "${DESCR[1]}"
fi
