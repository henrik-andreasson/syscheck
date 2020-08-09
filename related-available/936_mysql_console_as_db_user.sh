#!/bin/bash

SYSCHECK_HOME="${SYSCHECK_HOME:-/opt/syscheck}" # use default if  unset
if [ ! -f ${SYSCHECK_HOME}/syscheck.sh ] ; then
  echo "Can't find $SYSCHECK_HOME/syscheck.sh"
  exit
fi

if [ ! -f ${SYSCHECK_HOME}/syscheck.sh ] ; then echo "Can't find $SYSCHECK_HOME/syscheck.sh" ;exit ; fi

## Import common definitions ##
source $SYSCHECK_HOME/config/related-scripts.conf

# script name, used when integrating with nagios/icinga
SCRIPTNAME=mysql_user_console

# uniq ID of script (please use in the name of this file also for convinice for finding next availavle number)
SCRIPTID=936

# how many info/warn/error messages
NO_OF_ERR=0
initscript $SCRIPTID $NO_OF_ERR

default_script_getopt $*


$MYSQL_BIN $DB_NAME -h $HOSTNAME_NODE1 -u ${DB_USER} --password=${DB_PASSWORD}
