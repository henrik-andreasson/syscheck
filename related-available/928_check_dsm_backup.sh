#!/bin/bash
# 				sc_31_check_dsm_backup.sh - Script that checks if last dsm backup go OK


# Set SYSCHECK_HOME if not already set.

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
. $SYSCHECK_HOME/config/syscheck-scripts.conf

# uniq ID of script (please use in the name of this file also for convinice for finding next availavle number)
SCRIPTID=928
SCRIPTINDEX=00

DSM_ERRNO_1=${SCRIPTID}01
DSM_ERRNO_2=${SCRIPTID}02

getlangfiles $SCRIPTID
getconfig $SCRIPTID
test -z "$PRINTTOSCREEN" && PRINTTOSCREEN=0


# help
if [ "x$1" = "x--help" ] ; then
    echo "$0 $DSM_HELP"
    echo "$DSM_ERRNO_1/$DSM_DESCR_1 - $DSM_HELP_1"
    echo "$DSM_ERRNO_2/$DSM_DESCR_2 - $DSM_HELP_2"
    exit
elif [ "x$1" = "x-s" -o  "x$1" = "x--screen"  ] ; then
    PRINTTOSCREEN=1
fi

# Check logfile with grep
egrep -q "${DATE} ..:..:.. ${SERACH_STRING}" ${LOGFILE}
RC=$?
if [ ${RC} != 0 ]
then
LAST=`egrep "${SERACH_STRING}" ${LOGFILE}|awk '{print $1,$2}'|tail -1`
dsm=FAIL
fi
if [ "x$dsm" = "xFAIL" ] ; then
    printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   "$ERROR" "$DSM_ERRNO_2" "$DSM_DESCR_2 $LAST"
else
    printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   "$INFO" "$DSM_ERRNO_1" "$DSM_DESCR_1 "
fi

