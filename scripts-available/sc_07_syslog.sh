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

# get command line arguments
INPUTARGS=`/usr/bin/getopt --options "hsv" --long "help,screen,verbose" -- "$@"`
if [ $? != 0 ] ; then schelp ; fi
#echo "TEMP: >$TEMP<"
eval set -- "$INPUTARGS"

while true; do
  case "$1" in
    -s|--screen  ) PRINTTOSCREEN=1; shift;;
    -v|--verbose ) PRINTVERBOSESCREEN=1 ; shift;;
    -h|--help )   schelp;exit;shift;;
    --) break;;
  esac
done

# main part of script


send_syslog_msg(){
	chkvalue="${RANDOM}_$$"
	logger -p local0.notice "$0, syscheck test message: $chkvalue"
	sleep 1
	tail -1000 $localsyslogfile | grep "$0, syscheck test message: $chkvalue"   > /dev/null
	if [ $? -ne 0 ] ; then
                printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   $ERROR ${ERRNO[1]} "${DESCR[1]}"
		exit 1;
	else
		printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   $INFO ${ERRNO[4]} "${DESCR[4]}"

	fi
}



syslog=$($SYSCHECK_HOME/lib/proc_checker.sh $pidfile $procname)

if [ "x$syslog" = "x" ] ; then
  printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   $ERROR ${ERRNO[3]} "${DESCR[3]}"
	exit 2;
fi

SCRIPTINDEX=$(addOneToIndex $SCRIPTINDEX)

send_syslog_msg
