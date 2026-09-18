#!/bin/bash

SYSCHECK_HOME="${SYSCHECK_HOME:-/opt/syscheck}" # use default if  unset
if [ ! -f ${SYSCHECK_HOME}/syscheck.sh ] ; then
  echo "Can't find $SYSCHECK_HOME/syscheck.sh"
  exit
fi

# Import common resources
source $SYSCHECK_HOME/config/related-scripts.conf

# script name, used when integrating with nagios/icinga
SCRIPTNAME=filter_syscheck_messages

# uniq ID of script (please use in the name of this file also for convinice for finding next availavle number)
SCRIPTID=929

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

SEND_ONLY_SCRIPT_IDS_FMT=$(echo ${SEND_ONLY_SCRIPT_IDS} | sed 's/ /|/g')

SCRIPTINDEX=$(addOneToIndex $SCRIPTINDEX)

# build beside the real file so a failed run leaves the last good one in place
# mktemp creates the file, so the redirect needs >| to get past noclobber
FILTERED_TMP=$(mktemp "${FILTERED_FILE}.XXXXXX")
egrep "^(${SEND_ONLY_SCRIPT_IDS_FMT})-" "${LOCAL_FILE}" >| "${FILTERED_TMP}"
EGREPRET=$?

# egrep returns 1 when nothing matched, which is a quiet period, not a failure
if [ "$EGREPRET" -eq 0 ] ; then
      mv -f "${FILTERED_TMP}" "${FILTERED_FILE}"
      printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $INFO -e ${ERRNO[1]} -d "${DESCR[1]}"
elif [ "$EGREPRET" -eq 1 ] ; then
      mv -f "${FILTERED_TMP}" "${FILTERED_FILE}"
      printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $INFO -e ${ERRNO[3]} -d "${DESCR[3]}" -1 "${SEND_ONLY_SCRIPT_IDS}"
else
      rm -f "${FILTERED_TMP}"
      printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[2]} -d "${DESCR[2]}"
fi
