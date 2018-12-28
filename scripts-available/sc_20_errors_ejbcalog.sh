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
SCRIPTNAME=ejbcaerrorlog

# uniq ID of script (please use in the name of this file also for convinice for finding next availavle number)
SCRIPTID=20

# how many info/warn/error messages
NO_OF_ERR=3
initscript $SCRIPTID $NO_OF_ERR

# get command line arguments
INPUTARGS=`/usr/bin/getopt --options "hsvc" --long "help,screen,verbose,cert" -- "$@"`
if [ $? != 0 ] ; then schelp ; fi
#echo "TEMP: >$TEMP<"
eval set -- "$INPUTARGS"

while true; do
  case "$1" in
    -s|--screen  ) PRINTTOSCREEN=1; shift;;
    -v|--verbose ) PRINTVERBOSESCREEN=1 ; shift;;
    -c|--cert )   CERTFILE=$2; shift 2;;
    -h|--help )   schelp;exit;shift;;
    --) break;;
  esac
done

# main part of script

if [ ! -f $EEL_SERVER_LOG_FILE ] ; then
    printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   $WARN $EEL_ERRNO[3] "$EEL_DESCR[3]"  $EEL_SERVER_LOG_FILE
    exit
fi

SCRIPTINDEX=$(addOneToIndex $SCRIPTINDEX)

export EEL_SERVER_LOG_FILE
export EEL_SERVER_LOG_LASTPOSITION

NEWERRORS=`${SYSCHECK_HOME}/lib/tail_errors_from_ejbca_log.pl 2>/dev/null`

if [ "x$NEWERRORS" = "x" ]; then
    printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   $INFO $EEL_ERRNO[1] "$EEL_DESCR[1]"
else
    SHORTMESS=`echo $NEWERRORS | perl -ane 'm/Comment : (.*)/, print "$1\n"'`
    printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   $ERROR $EEL_ERRNO[2] "$EEL_DESCR[2]" "$SHORTMESS"
fi
