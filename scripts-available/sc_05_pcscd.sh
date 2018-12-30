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
SCRIPTNAME=pcscd

# uniq ID of script (please use in the name of this file also for convinice for finding next availavle number)
SCRIPTID=05

# how many info/warn/error messages
NO_OF_ERR=2
initscript $SCRIPTID $NO_OF_ERR

default_script_getopt $*

# main part of script

if [ -f $pidfile ] ; then
	pid=$(${SYSCHECK_HOME}/lib/proc_checker.sh $pidfile)
else
	pid=$(ps -ef | grep $procname | grep -v grep | awk '{print $2}')
fi


SCRIPTINDEX=$(addOneToIndex $SCRIPTINDEX)

if [ "x$pid" = "x" ] ; then
	printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[2]} -d "${DESCR[2]}"
else
	printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $INFO   -e ${ERRNO[1]} -d "${DESCR[1]}"
fi
