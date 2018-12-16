#!/bin/bash

# 1. First check if SYSCHECK_HOME is set then use that
if [ "x${SYSCHECK_HOME}" = "x" ] ; then
# 2. Check if /etc/syscheck.conf exists then source that (put SYSCHECK_HOME=/path/to/syscheck in ther)
    if [ -e /etc/syscheck.conf ] ; then
	     source /etc/syscheck.conf
    else
# 3. last resort use default path
	     SYSCHECK_HOME="/opt/syscheck"
    fi
fi

if [ ! -f ${SYSCHECK_HOME}/syscheck.sh ] ; then echo "$0: Can't find syscheck.sh in SYSCHECK_HOME ($SYSCHECK_HOME)" ;exit ; fi

## Import common definitions ##
source $SYSCHECK_HOME/config/syscheck-scripts.conf

# scriptname used to map and explain scripts in icinga and other
SCRIPTNAME=healthcheck

# uniq ID of script (please use in the name of this file also for convinice for finding next availavle number)
SCRIPTID=33

# Index is used to uniquely identify one test done by the script (a harddrive, crl or cert)
SCRIPTINDEX=00

getlangfiles $SCRIPTID
getconfig $SCRIPTID

ERRNO_1=01
ERRNO_2=02
ERRNO_3=03


if [ "x$1" = "x-h" -o "x$1" = "x--help" ] ; then
        echo "$ECA_HELP"
        echo "$ERRNO_1/$DESCR_1 - $HELP_1"
        echo "$ERRNO_2/$DESCR_2 - $HELP_2"
        echo "$ERRNO_3/$DESCR_3 - $HELP_3"
        echo "${SCREEN_HELP}"
        exit
elif [ "x$1" = "x-s" -o  "x$1" = "x--screen"  ] ; then
    shift
    PRINTTOSCREEN=1
fi

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
	        printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX} $ERROR $ERRNO_3 "$DESCR_3"
	fi

	if [ "x$STATUS" != "xALLOK" ] ; then
		printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX} $ERROR $ERRNO_2 "$DESCR_2" "${HEALTHCHECK_APP[$i]}" "$STATUS"
	else
		printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX} $INFO  $ERRNO_1 "$DESCR_1" "${HEALTHCHECK_APP[$i]}"
	fi

	if [ "x${PRINTFULL}" = "x1" ] ; then
		printtoscreen "----"
	fi

done
