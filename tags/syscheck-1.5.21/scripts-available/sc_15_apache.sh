#!/bin/bash
# Script that checks if the Apache webserver is running.

# Set SYSCHECK_HOME if not already set.

# 1. First check if SYSCHECK_HOME is set then use that
if [ "x${SYSCHECK_HOME}" = "x" ] ; then
# 2. Check if /etc/syscheck.conf exists then source that (put SYSCHECK_HOME=/path/to/syscheck in ther)
    if [ -e /etc/syscheck.conf ] ; then 
	source /etc/syscheck.conf 
    else
# 3. last resort use default path
	SYSCHECK_HOME="/usr/local/syscheck"
    fi
fi

if [ ! -f ${SYSCHECK_HOME}/syscheck.sh ] ; then echo "$0: Can't find syscheck.sh in SYSCHECK_HOME ($SYSCHECK_HOME)" ;exit ; fi





## Import common definitions ##
. $SYSCHECK_HOME/config/syscheck-scripts.conf

# uniq ID of script (please use in the name of this file also for convinice for finding next availavle number)
SCRIPTID=15

APA_ERRNO_1=${SCRIPTID}01
APA_ERRNO_2=${SCRIPTID}02

getlangfiles $SCRIPTID
getconfig $SCRIPTID

# help
if [ "x$1" = "x--help" ] ; then
    echo "$0 $APA_HELP"
    echo "$APA_ERRNO_1/$APA_DESCR_1 - $APA_HELP_1"
    echo "$APA_ERRNO_2/$APA_DESCR_2 - $APA_HELP_2"
    exit
elif [ "x$1" = "x-s" -o  "x$1" = "x--screen"  ] ; then
    PRINTTOSCREEN=1
fi

proc=`$SYSCHECK_HOME/lib/proc_checker.sh $pidfile $procname` 

# Sends an error to syslog if x"$proc" is not xhttpd.
if [ "x$proc" = "x" ] ; then
    printlogmess "$ERROR" "$APA_ERRNO_2" "$APA_DESCR_2"
else
    printlogmess "$INFO" "$APA_ERRNO_1" "$APA_DESCR_1"
fi

