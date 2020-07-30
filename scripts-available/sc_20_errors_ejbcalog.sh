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
NO_OF_ERR=4
initscript $SCRIPTID $NO_OF_ERR

default_script_getopt $*

# main part of script

SCRIPTINDEX=$(addOneToIndex $SCRIPTINDEX)

if [ ! -f $EEL_SERVER_LOG_FILE ] ; then
    printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $WARN -e ${ERRNO[3]} -d "${DESCR[3]}" -1 "$EEL_SERVER_LOG_FILE"
    exit
fi

SCRIPTINDEX=$(addOneToIndex $SCRIPTINDEX)

export EEL_SERVER_LOG_FILE
export EEL_SERVER_LOG_LASTPOSITION

NEWERRORS=$(${SYSCHECK_HOME}/lib/tail_errors_from_ejbca_log.py --logfile "${EEL_SERVER_LOG_FILE}" --positionfile "${EEL_SERVER_LOG_LASTPOSITION}" 2>/dev/null)

declare -a errorsExceptIgnores

IFS=$'\n'
for line in ${NEWERRORS} ; do
  ignore=0
  for ignoreline in "${IGNORE[@]}"; do
#    echo "ignore: $ignoreline line: $line"
    ignorematch=$(echo "$line" | grep "$ignoreline")
    if [ "x${ignorematch}" != "x" ]; then
      ignore=1
    fi
  done
  if [ "x$ignore" != "x1" ] ; then
    errorsExceptIgnores+=("$line")
  fi
done

if [ "x$NEWERRORS" == "x" ]; then
    printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $INFO -e ${ERRNO[1]} -d "${DESCR[1]}"
else
    printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x "0" -l $ERROR -e ${ERRNO[2]} -d "${DESCR[2]}" -1 "${#errorsExceptIgnores[@]}"

    for errorline in ${errorsExceptIgnores[@]} ; do
      SCRIPTINDEX=$(addOneToIndex $SCRIPTINDEX)
      printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[4]} -d "${DESCR[4]}" -1 "${errorline}"
    done
fi
