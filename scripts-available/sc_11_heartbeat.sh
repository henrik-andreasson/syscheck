#!/bin/sh 

# Set default home if not already set.
SYSCHECK_HOME=${SYSCHECK_HOME:-"/usr/local/syscheck"}

## Import common definitions ##
. $SYSCHECK_HOME/resources.sh

SCRIPTID=11

getlangfiles $SCRIPTID
getconfig $SCRIPTID

HA_ERRNO_1=${SCRIPTID}01
HA_ERRNO_2=${SCRIPTID}02
HA_ERRNO_3=${SCRIPTID}03

# help
if [ "x$1" = "x--help" ] ; then
    echo "$0 $HA_HELP"
    echo "$HA_ERRNO_1/$HA_DESCR_1 - $HA_HELP_1"
    echo "$HA_ERRNO_2/$HA_DESCR_2 - $HA_HELP_2"
    exit
elif [ "x$1" = "x-s" -o  "x$1" = "x--screen"  ] ; then
    PRINTTOSCREEN=1
fi

# TODO check name of heartbeat
pid=`$SYSCHECK_HOME/lib/proc_checker.sh $pidfile /usr/sbin/heartbeat` 
if [ "x$pid" = "x" ] ; then
    printlogmess $ERROR $HA_ERRNO_2 "$HA_DESCR_2"  
    exit 3
else
    printlogmess $INFO $HA_ERRNO_1 "$HA_DESCR_1"
fi

