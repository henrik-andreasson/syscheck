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

URL="http://${EJBCA_HOSTNAME}:8080/ejbca/publicweb/healthcheck/ejbcahealth"

OUTPUT='/tmp/ejbcahealth.log'
rm -f $OUTPUT

cd /tmp
if [ "x${CHECKTOOL}" = "xwget" ] ; then
        ${CHECKTOOL} "${URL}" -T ${EJBCA_TIMEOUT} -t 1 -O $OUTPUT 2>/dev/null
elif [ "x${CHECKTOOL}" = "xcurl" ] ; then

        result=$( ${CHECKTOOL} "${URL}" --silent --show-error --connect-timeout ${EJBCA_TIMEOUT} --max-time ${EJBCA_TIMEOUT} --retry 1 --output $OUTPUT 2>&1)
        if [ $? -ne 0 ] ; then
                printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX} $ERROR ${ERRNO[2]} "${DESCR[2]}" "$result"
                exit
        fi

else
        printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   $ERROR ${ERRNO[3]} "${DESCR[3]}"
fi

SCRIPTINDEX=$(addOneToIndex $SCRIPTINDEX)

FULLOUTPUT=$(cat $OUTPUT)
OKOUTPUT=$(cat $OUTPUT | grep ALLOK )
ERROROUTPUT=$(cat $OUTPUT | grep ERROR)

if [ "x$OKOUTPUT" != "x" ]; then
       printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX} $INFO ${ERRNO[1]} "${DESCR[1]}" "$FULLOUTPUT"
elif [ "x$ERROROUTPUT" != "x" ]; then
       printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX} $ERROR ${ERRNO[2]} "${DESCR[2]}" "$FULLOUTPUT"
elif [ "x$FULLOUTPUT" = "x" ] ; then
	printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   $ERROR ${ERRNO[4]} "${DESCR[4]}" $FULLOUTPUT
else
	printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   $ERROR ${ERRNO[4]} "${DESCR[4]}" $FULLOUTPUT
fi

rm -f $OUTPUT
