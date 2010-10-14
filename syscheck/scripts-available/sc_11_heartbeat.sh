#!/bin/sh 

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

