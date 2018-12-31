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
SCRIPTNAME=syscheck

# uniq ID of script (please use in the name of this file also for convinice for finding next availavle number)
SCRIPTID=00

# how many info/warn/error messages
NO_OF_ERR=0
initscript $SCRIPTID $NO_OF_ERR

PATH=$SYSCHECK_HOME:$PATH

export PATH

PRINTTOSCREEN=${PRINTTOSCREEN:-0}
PRINTVERBOSESCREEN=${PRINTVERBOSESCREEN:-0}

# get command line arguments
INPUTARGS=`/usr/bin/getopt --options "hsvct" --long "help,screen,verbose,testall" -- "$@"`
if [ $? != 0 ] ; then schelp ; fi
eval set -- "$INPUTARGS"

while true; do
  case "$1" in
    -s|--screen  ) PRINTTOSCREEN=1; shift;;
    -v|--verbose ) PRINTVERBOSESCREEN=1 ; shift;;
    -t|--testall ) TESTALL=1 ; shift;;
    -h|--help )   schelp;exit;shift;;
    --) break;;
  esac
done

export PRINTTOSCREEN
export PRINTVERBOSESCREEN
export SAVELASTSTATUS

if [ "x$TESTALL" == "x1" ] ; then
  for file in ${SYSCHECK_HOME}/scripts-available/sc_* ; do
  	$file
  done
  exit
fi

rm -f ${SYSCHECK_HOME}/var/last_status
date > ${SYSCHECK_HOME}/var/last_status
for file in ${SYSCHECK_HOME}/scripts-enabled/sc_* ; do
	$file
done

# run the filter command
if [ "x${FILTER_SYSCHECK_AFTER_RUN}" = "x1" ] ; then
	${SYSCHECK_HOME}/related-enabled/929_filter_syscheck_messages.sh
fi

# transfer syscheck status to remote machine
if [ "x${SEND_SYSCHECK_RESULT_TO_REMOTE_MACHINE_AFTER_FILTER}" = "x1" ] ;then
	${SYSCHECK_HOME}/related-enabled/930_send_filtered_result_to_remote_machine.sh
fi

# transfer syscheck status as a message
if [ "x${SEND_SYSCHECK_RESULT_AS_MESSAGE}" = "x1" ] ;then
	${SYSCHECK_HOME}/related-enabled/932_send_result_as_message.sh
fi
