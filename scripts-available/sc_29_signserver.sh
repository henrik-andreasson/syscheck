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
SCRIPTNAME=signserver

# uniq ID of script (please use in the name of this file also for convinice for finding next availavle number)
SCRIPTID=29

# how many info/warn/error messages
NO_OF_ERR=3
initscript $SCRIPTID $NO_OF_ERR

default_script_getopt $*

# main part of script

OUTPUT='/tmp/signserverhealth.log'
URL="http://$SIGNSERVER_HOSTNAME:8080/signserver/healthcheck/signserverhealth"

SCRIPTINDEX=$(addOneToIndex $SCRIPTINDEX)
cd /tmp
if [ "x${CHECKTOOL}" = "xwget" ] ; then
        ${CHECKTOOL} ${URL} -T ${GET_TIMEOUT} -t 1 -O $OUTPUT 2>/dev/null
elif [ "x${CHECKTOOL}" = "xcurl" ] ; then
        ${CHECKTOOL} ${URL} --connect-timeout ${GET_TIMEOUT} --retry 1 --output $OUTPUT 2>/dev/null
else
        printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[3]} -d "${DESCR[3]}"
	exit
fi

FULLOUTPUT=$(cat $OUTPUT)
OKOUTPUT=$(cat $OUTPUT | grep ALLOK)
ERROROUTPUT=$(cat $OUTPUT | grep ERROR)

SCRIPTINDEX=$(addOneToIndex $SCRIPTINDEX)
if [ "x$OKOUTPUT" != "x" ]; then
       printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $INFO -e ${ERRNO[1]} -d "${DESCR[1]}" -1 "$FULLOUTPUT"
elif [ "x$ERROROUTPUT" != "x" ]; then
       printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[2]} -d "${DESCR[2]}" -1 "$FULLOUTPUT"
fi

rm $OUTPUT
