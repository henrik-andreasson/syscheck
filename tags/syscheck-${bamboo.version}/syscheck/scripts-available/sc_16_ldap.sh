#!/bin/bash
# Script that checks if the OpenLDAP ldap server is running.

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

# uniq ID of script (please use in the name of this file also for convinice for finding next availavle number)
SCRIPTID=16

# Index is used to uniquely identify one test done by the script (a harddrive, crl or cert)
SCRIPTINDEX=00


## Import common definitions ##
. $SYSCHECK_HOME/config/syscheck-scripts.conf

getlangfiles $SCRIPTID
getconfig $SCRIPTID

ERRNO_1=01
ERRNO_2=02


# help
if [ "x$1" = "x--help" ] ; then
    echo "$0 $HELP"
    echo "$ERRNO_1/$DESCR_1 - $HELP_1"
    echo "$ERRNO_2/$DESCR_2 - $HELP_2"
    exit
elif [ "x$1" = "x-s" -o  "x$1" = "x--screen" ] ; then
    PRINTTOSCREEN=1
fi

SCRIPTINDEX=$(addOneToIndex $SCRIPTINDEX)
proc=`$SYSCHECK_HOME/lib/proc_checker.sh $pidfile $procname` 
if [ "x$proc" = "x" ] ; then
	printlogmess ${SCRIPTID} ${SCRIPTINDEX}   "$ERROR" "$ERRNO_2" "$DESCR_2"
else
	printlogmess ${SCRIPTID} ${SCRIPTINDEX}   "$INFO" "$ERRNO_1" "$DESCR_1"
fi

