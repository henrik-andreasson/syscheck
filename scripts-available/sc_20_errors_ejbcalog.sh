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

default_script_getopt $*

# main part of script

if [ ! -f $EEL_SERVER_LOG_FILE ] ; then
    printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $WARN -e ${ERRNO[3]} -d "${DESCR[3]}" -1 "$EEL_SERVER_LOG_FILE"
    exit
fi

SCRIPTINDEX=$(addOneToIndex $SCRIPTINDEX)

export EEL_SERVER_LOG_FILE
export EEL_SERVER_LOG_LASTPOSITION

NEWERRORS=`${SYSCHECK_HOME}/lib/tail_errors_from_ejbca_log.pl 2>/dev/null`

if [ "x$NEWERRORS" = "x" ]; then
    printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $INFO -e ${ERRNO[1]} -d "${DESCR[1]}"
else
    SHORTMESS=`echo $NEWERRORS | perl -ane 'm/Comment : (.*)/, print "$1\n"'`
    printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[2]} -d "${DESCR[2]}" -1 "$SHORTMESS"
fi
