#!/bin/bash
# Script that checks if the sync of Db works
# Use SYSCHECK_HOME/database-replication/808-test-table-update-and-check-master-and-slave.sh as source of information
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
SCRIPTID=32

# Index is used to uniquely identify one test done by the script (a harddrive, crl or cert)
SCRIPTINDEX=00


ERRNO_1=01
ERRNO_2=02

getlangfiles $SCRIPTID
getconfig $SCRIPTID

# help
if [ "x$1" = "x--help" ] ; then
    echo "$0 $HELP"
    echo "$ERRNO_1/$DESCR_1 - $HELP_1"
    echo "$ERRNO_2/$DESCR_2 - $HELP_2"
    exit
elif [ "x$1" = "x-s" -o  "x$1" = "x--screen"  ] ; then
    PRINTTOSCREEN=1
fi


if [ ! -f $SYSCHECK_HOME/database-replication/808-test-table-update-and-check-master-and-slave.sh ] ; then
	printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX} "$ERROR" "$ERRNO_2" "$DESCR_2 missing script, database-replication/808-test-table-update-and-check-master-and-slave.sh"
	exit
fi

SCRIPTINDEX=$(addOneToIndex $SCRIPTINDEX)
. $SYSCHECK_HOME/database-replication/808-test-table-update-and-check-master-and-slave.sh >/dev/null
NODE1=`echo $VALUE_NODE1|awk '{print $2}'`
NODE2=`echo $VALUE_NODE2|awk '{print $2}'`
if [ $NODE1 != $NODE2 ] ;  then
	SYNCDATE=`perl -e "print scalar(localtime($NODE2))"|awk '{print $3,$2,$4,$5}'`
	printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   "$ERROR" "$ERRNO_2" "$DESCR_2 $LASTUPD_NODE1 /$LASTUPD_NODE2 $SYNCDATE"
else
	printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   "$INFO" "$ERRNO_1" "$DESCR_1"
fi

