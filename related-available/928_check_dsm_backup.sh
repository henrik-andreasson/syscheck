#!/bin/bash

SYSCHECK_HOME="${SYSCHECK_HOME:-/opt/syscheck}" # use default if  unset
if [ ! -f ${SYSCHECK_HOME}/syscheck.sh ] ; then
  echo "Can't find $SYSCHECK_HOME/syscheck.sh"
  exit
fi

if [ ! -f ${SYSCHECK_HOME}/syscheck.sh ] ; then echo "Can't find $SYSCHECK_HOME/syscheck.sh" ;exit ; fi

# Import common resources
source $SYSCHECK_HOME/config/syscheck-scripts.conf

# script name, used when integrating with nagios/icinga
SCRIPTNAME=dsm_backup

# uniq ID of script (please use in the name of this file also for convinice for finding next availavle number)
SCRIPTID=928

# how many info/warn/error messages
NO_OF_ERR=3
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

# Check logfile with grep
egrep -q "${DATE} ..:..:.. ${SERACH_STRING}" ${LOGFILE}
RC=$?
if [ ${RC} != 0 ]
then
LAST=`egrep "${SERACH_STRING}" ${LOGFILE}|awk '{print $1,$2}'|tail -1`
dsm=FAIL
fi
if [ "x$dsm" = "xFAIL" ] ; then
    printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   "$ERROR" "${ERRNO[2]}" "${DESCR[2]} $LAST"
else
    printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   "$INFO" "${ERRNO[1]}" "${DESCR[1]} "
fi
