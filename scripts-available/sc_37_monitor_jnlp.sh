#!/bin/bash

SYSCHECK_HOME="${SYSCHECK_HOME:-/opt/syscheck}" # use default if  unset
if [ ! -f ${SYSCHECK_HOME}/syscheck.sh ] ; then
  echo "Can't find $SYSCHECK_HOME/syscheck.sh"
  exit
fi

## Import common definitions ##
source $SYSCHECK_HOME/config/syscheck-scripts.conf

# script name, used when integrating with nagios/icinga
SCRIPTNAME=jnlp_checker

# uniq ID of script (please use in the name of this file also for convinice for finding next availavle number)
SCRIPTID=37

# how many info/warn/error messages
NO_OF_ERR=3

initscript $SCRIPTID $NO_OF_ERR

default_script_getopt $*

# main part of script

OUTPUT="/tmp/internal-error.txt"

# clear before and after, a stale file would be read as this runs answer
rm -f "$OUTPUT"
trap 'rm -f "$OUTPUT"' EXIT

SCRIPTINDEX=$(addOneToIndex $SCRIPTINDEX)

if [ "x${CHECKTOOL}" = "xcurl" ] ; then
        ${CHECKTOOL} "${URL}" "${HEADER[@]}" --max-time ${CURL_TIMEOUT} --retry 1 --output $OUTPUT 2>/dev/null
else
        printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[3]} -d "${DESCR[3]}" -1 "${CHECKTOOL}"
        exit 1
fi

OKOUTPUT=$(cat $OUTPUT | grep "JNLP File generated" | sed 's/<!--//' | sed 's/-->//')
FULLOUTPUT=$(cat $OUTPUT | tr -d "\n")

if [ "x${OKOUTPUT}" != "x" ]; then
   printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $INFO -e ${ERRNO[1]} -d "${DESCR[1]}" -1 "$OKOUTPUT"
else
	 printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e "${ERRNO[2]}" -d "${DESCR[2]}" -1 "$FULLOUTPUT"
fi
