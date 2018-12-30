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

default_script_getopt $*

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
	        printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[3]} -d "${DESCR[3]}"
	fi

	if [ "x$STATUS" != "xALLOK" ] ; then
		printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[2]} -d "${DESCR[2]}" -1 "${HEALTHCHECK_APP[$i]}" -2 "$STATUS"
	else
		printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -s ${SCRIPTINDEX} -l $INFO  -e ${ERRNO[1]} -d "${DESCR[1]}" -1 "${HEALTHCHECK_APP[$i]}"
	fi

	if [ "x${PRINTFULL}" = "x1" ] ; then
		printtoscreen "----"
	fi




done
