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
SCRIPTNAME=ejbca

# uniq ID of script (please use in the name of this file also for convinice for finding next availavle number)
SCRIPTID=02

# how many info/warn/error messages
NO_OF_ERR=3
initscript $SCRIPTID $NO_OF_ERR

default_script_getopt $*

# main part of script

URL="http://${EJBCA_HOSTNAME}:8080/ejbca/publicweb/healthcheck/ejbcahealth"

OUTPUT='/tmp/ejbcahealth.log'
rm -f $OUTPUT

cd /tmp
if [ "x${CHECKTOOL}" = "xwget" ] ; then
        ${CHECKTOOL} "${URL}" -T ${EJBCA_TIMEOUT} -t 1 -O $OUTPUT 2>/dev/null
elif [ "x${CHECKTOOL}" = "xcurl" ] ; then

        result=$( ${CHECKTOOL} "${URL}" --silent --show-error --max-time ${EJBCA_TIMEOUT} --max-time ${EJBCA_TIMEOUT} --retry 1 --output $OUTPUT 2>&1)
        if [ $? -ne 0 ] ; then
                printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[2]} -d "${DESCR[2]}" -1 "$result"
                exit
        fi

else
        printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[3]} -d "${DESCR[3]}"
fi

SCRIPTINDEX=$(addOneToIndex $SCRIPTINDEX)

FULLOUTPUT=$(cat $OUTPUT)
OKOUTPUT=$(cat $OUTPUT | grep ALLOK )
ERROROUTPUT=$(cat $OUTPUT | grep ERROR)

if [ "x$OKOUTPUT" != "x" ]; then
       printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $INFO -e ${ERRNO[1]} -d "${DESCR[1]}" -1 "$FULLOUTPUT"
elif [ "x$ERROROUTPUT" != "x" ]; then
       printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[2]} -d "${DESCR[2]}" -1 "$FULLOUTPUT"
elif [ "x$FULLOUTPUT" = "x" ] ; then
	printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[4]} -d "${DESCR[4]}" -1 "$FULLOUTPUT"
else
	printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[4]} -d "${DESCR[4]}" -1 "$FULLOUTPUT"
fi

rm -f $OUTPUT
