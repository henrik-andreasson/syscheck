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
SCRIPTNAME=diskusage

# uniq ID of script (please use in the name of this file also for convinice for finding next availavle number)
SCRIPTID=41

# how many info/warn/error messages
NO_OF_ERR=3
initscript $SCRIPTID $NO_OF_ERR

default_script_getopt $*


OUTPUT='/tmp/rahealth.log'

cd /tmp
if [ ! -f "${CHECKTOOL_PATH}/${CHECKTOOL}" ] ; then
        printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e "${ERRNO[3]}" "$DESCR_3"
fi

runres=$(${CHECKTOOL_PATH}/${CHECKTOOL} -c ${CHECKTOOL_PATH}/verify-factoryra.properties > $OUTPUT 2>&1 )
SCRIPTINDEX=$(addOneToIndex $SCRIPTINDEX)
FULLOUTPUT=$(cat $OUTPUT)
CLIENT_OKOUTPUT=$(cat $OUTPUT | egrep "Client Certificate: VALID")
REQ_OKOUTPUT=$(cat $OUTPUT | egrep "Request Verification: OK")
SERVER_OKOUTPUT=$(cat $OUTPUT | egrep "Server Certificate: VALID")
if [ "x$CLIENT_OKOUTPUT" != "x" ]; then
       printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $INFO -e  ${ERRNO[1]} "${DESCR[1]}" "$CLIENT_OKOUTPUT"
else
       ERROROUTPUT=$(cat $OUTPUT | head -2 )
       printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e  ${ERRNO[2]} "${DESCR[2]}" "$ERROROUTPUT"
fi
SCRIPTINDEX=$(addOneToIndex $SCRIPTINDEX)
if [ "x$REQ_OKOUTPUT" != "x" ]; then
       printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $INFO -e  ${ERRNO[1]} "${DESCR[1]}" "$REQ_OKOUTPUT"
else
       REQ_ERROROUTPUT=$(cat $OUTPUT |grep Error|sed 's/<faultstring>/ faultstring /;s/<\/faultstring>/ \/faultstring /;s/.*faultstring \(.*\)\/faultstring/\1/')
       printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[2]} "${DESCR[2]}" "$REQ_ERROROUTPUT"
fi
SCRIPTINDEX=$(addOneToIndex $SCRIPTINDEX)
if [ "x$SERVER_OKOUTPUT" != "x" ]; then
       printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $INFO -e ${ERRNO[1]} "${DESCR[1]}" "$SERVER_OKOUTPUT"
else
       ERROROUTPUT=$(cat $OUTPUT | head -2 )
       printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[2]} "${DESCR[2]}" "$ERROROUTPUT"
fi

rm $OUTPUT
