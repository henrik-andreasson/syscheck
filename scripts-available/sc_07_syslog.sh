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
SCRIPTNAME=syslog

# uniq ID of script (please use in the name of this file also for convinice for finding next availavle number)
SCRIPTID=07

# how many info/warn/error messages
NO_OF_ERR=4
initscript $SCRIPTID $NO_OF_ERR

default_script_getopt $*

# main part of script


send_syslog_msg(){
	chkvalue="${RANDOM}_$$"
	logger -p local0.notice "$0, syscheck test message: $chkvalue"
	sleep "${WAIT_TIME}"
	tail -1000 $localsyslogfile 2>&1 | grep "$0, syscheck test message: $chkvalue"  2>&1 > /dev/null
	if [ $? -ne 0 ] ; then
    printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[1]} -d "${DESCR[1]}"
		exit 1;
	else
		printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $INFO -e ${ERRNO[3]} -d "${DESCR[3]}"
	fi
}



syslog=$($SYSCHECK_HOME/lib/proc_checker.sh $pidfile $procname)

if [ "x$syslog" = "x" ] ; then
  printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[2]} -d "${DESCR[2]}"
	exit 2;
fi

SCRIPTINDEX=$(addOneToIndex $SCRIPTINDEX)

send_syslog_msg
