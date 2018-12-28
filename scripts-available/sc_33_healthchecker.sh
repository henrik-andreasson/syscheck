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
SCRIPTNAME=healthcheck

# uniq ID of script (please use in the name of this file also for convinice for finding next availavle number)
SCRIPTID=33

# how many info/warn/error messages
NO_OF_ERR=2
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

PRINTFULL=0
if [ "x$1" = "x-f" -o  "x$1" = "x--full"  ] ; then
    shift
    PRINTFULL=1
fi



for (( i = 0 ;  i < ${#HEALTHCHECKURL[@]} ; i++ )) ; do
        SCRIPTINDEX=$(addOneToIndex $SCRIPTINDEX)

	if [ "x${PRINTFULL}" = "x1" ] ; then
		printtoscreen "Checking ${HEALTHCHECKURL_FULL[$i]}"
	fi
	if [ "x${CHECKTOOL}" = "xwget" ] ; then
	        STATUS=$(${CHECKTOOL} ${HEALTHCHECKURL[$i]} -T ${TIMEOUT} -t 1 2>/dev/null)
		if [ "x${PRINTFULL}" = "x1" ] ; then
			FULLSTATUS=$(${CHECKTOOL} ${HEALTHCHECKURL_FULL[$i]} -T ${TIMEOUT} -t 1 2>/dev/null)
			printtoscreen ${FULLSTATUS}
		fi
	elif [ "x${CHECKTOOL}" = "xcurl" ] ; then
	        STATUS=$(${CHECKTOOL} ${HEALTHCHECKURL[$i]} --connect-timeout ${TIMEOUT} --retry 1 2>/dev/null)
		if [ "x${PRINTFULL}" = "x1" ] ; then
	        	FULLSTATUS=$(${CHECKTOOL} ${HEALTHCHECKURL_FULL[$i]} --connect-timeout ${TIMEOUT} --retry 1 2>/dev/null)
			printtoscreen ${FULLSTATUS}
		fi
	else
	        printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX} $ERROR ${ERRNO[3]} "${DESCR[3]}"
	fi

	if [ "x$STATUS" != "xALLOK" ] ; then
		printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX} $ERROR ${ERRNO[2]} "${DESCR[2]}" "${HEALTHCHECK_APP[$i]}" "$STATUS"
	else
		printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX} $INFO  ${ERRNO[1]} "${DESCR[1]}" "${HEALTHCHECK_APP[$i]}"
	fi

	if [ "x${PRINTFULL}" = "x1" ] ; then
		printtoscreen "----"
	fi




done
