#!/bin/bash

# Set SYSCHECK_HOME if not already set.

SYSCHECK_HOME="${SYSCHECK_HOME:-/opt/syscheck}" # use default if  unset
if [ ! -f ${SYSCHECK_HOME}/syscheck.sh ] ; then
  echo "Can't find $SYSCHECK_HOME/syscheck.sh"
  exit
fi

if [ ! -f ${SYSCHECK_HOME}/syscheck.sh ] ; then echo "Can't find $SYSCHECK_HOME/syscheck.sh" ;exit ; fi

## Import common definitions ##
. $SYSCHECK_HOME/config/syscheck-scripts.conf

PATH=$SYSCHECK_HOME:$PATH

export PATH

SCRIPTID=00

# how many info/warn/error messages
NO_OF_ERR=3
initscript $SCRIPTID $NO_OF_ERR


PRINTTOSCREEN=


TEMP=`/usr/bin/getopt --options ":h:s" --long "help,screen" -- "$@"`
if [ $? != 0 ] ; then help ; fi
eval set -- "$TEMP"

while true; do
  case "$1" in
    -s|--screen ) PRINTTOSCREEN=1; shift;;
    -h|--help )   schelp;shift;;
    --) break ;;
  esac
done

export PRINTTOSCREEN
export SAVELASTSTATUS

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
