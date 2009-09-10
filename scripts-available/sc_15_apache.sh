#!/bin/bash
# Script that checks if the Apache webserver is running.


# Set default home if not already set.
SYSCHECK_HOME=${SYSCHECK_HOME:-"/usr/local/syscheck"}

## Import common definitions ##
. $SYSCHECK_HOME/resources.sh

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

