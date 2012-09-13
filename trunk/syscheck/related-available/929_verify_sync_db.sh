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
SCRIPTID=929
SYNC_ERRNO_1=${SCRIPTID}01
SYNC_ERRNO_2=${SCRIPTID}02
SYNC_ERRNO_3=${SCRIPTID}03

PRINTTOSCREEN=0
getlangfiles $SCRIPTID
getconfig $SCRIPTID

# help
if [ "x$1" = "x--help" ] ; then
    echo "$0 $APA_HELP"
    echo "$SYNC_ERRNO_1/$SYNC_DESCR_1 - $SYNC_HELP_1"
    echo "$SYNC_ERRNO_2/$SYNC_DESCR_2 - $SYNC_HELP_2"
    echo "$SYNC_ERRNO_3/$SYNC_DESCR_3 - $SYNC_HELP_3"
    exit
elif [ "x$1" = "x-s" -o  "x$1" = "x--screen"  ] ; then
    PRINTTOSCREEN=1
fi

HASFAILED=0

######################################
#  Get Ip adress on masternodea and replica
#

# TODO hämta nya master enl mats nya skript. ..... MATS

eval MASTER="\$HOSTNAME_${THIS_NODE}"

if [ ${MASTER} = $HOSTNAME_NODE1 ]
then
    REPLICA=$HOSTNAME_NODE2
else
    REPLICA=$HOSTNAME_NODE1
fi

# get datetime "now - 10 minutes" in milliseconds
DATE_AGO_SEC="$(date --date='10 minutes ago' +%s)"
DATE_AGO_MILLISEC="${DATE_AGO_SEC}000"

######################################
# Count row in LogEntryData
#
echo "SELECT count(*) from LogEntryData where time < ${DATE_AGO};" >/tmp/select4.sql

DATELOGFILE=`perl -e "print scalar(localtime(${DATE_AGO_SEC}))"|awk '{print $3,$2,$4,$5}'`
COUNTRO_MASTER=`$MYSQL_BIN -N $DB_NAME -h $MASTER -u ${DB_USER} --password=${DB_PASSWORD} </tmp/select4.sql 2>/dev/null`
ERROR_MASTER=$?
if [ $ERROR_MASTER != 0 ] ; then
    printlogmess "$ERROR" "$SYNC_ERRNO_3" "$SYNC_DESCR_3 Master:${MASTER}"
    exit 1
fi
COUNTRO_MASTER_LINES=`echo $COUNTRO_MASTER|awk '{print $1}'`


COUNTRO_REPLICA=`$MYSQL_BIN -N $DB_NAME -h $REPLICA -u ${DB_USER} --password=${DB_PASSWORD} </tmp/select4.sql 2>/dev/null`
ERROR_REPLICA=$?
if [ $ERROR_REPLICA != 0 ] ; then
    printlogmess "$ERROR" "$SYNC_ERRNO_3" "$SYNC_DESCR_3 Replica:${REPLICA}"
    exit 1
fi
COUNTRO_REPLICA_LINES=`echo $COUNTRO_REPLICA|awk '{print $1}'`

if [ $COUNTRO_MASTER_LINES != $COUNTRO_REPLICA_LINES ] ; then
    printlogmess "$ERROR" "$SYNC_ERRNO_2" "$SYNC_DESCR_2 Count LogEntrydata Master: ${COUNTRO_MASTER_LINES}  Replica: ${COUNTRO_REPLICA_LINES}"
    HASFAILED=1
fi 

######################################
# Get time when table CertificateData and crldata was last updated
#
echo "SELECT max(updateTime) from CertificateData;">/tmp/select2.sql

LASTUPD_MASTER0=`$MYSQL_BIN $DB_NAME -h $MASTER -u ${DB_USER} --password=${DB_PASSWORD} </tmp/select2.sql 2>/dev/null`
LASTUPD_MASTER1=`echo $LASTUPD_MASTER0 |awk '{print $2/1000}'`
LASTUPD_MASTER=`perl -e "print scalar(localtime($LASTUPD_MASTER1))"|awk '{print $3,$2,$4,$5}'`

LASTUPD_REPLICA0=`$MYSQL_BIN $DB_NAME -h $REPLICA -u ${DB_USER} --password=${DB_PASSWORD} </tmp/select2.sql 2>/dev/null`
LASTUPD_REPLICA1=`echo $LASTUPD_REPLICA0 |awk '{print $2/1000}'`
LASTUPD_REPLICA=`perl -e "print scalar(localtime($LASTUPD_REPLICA1))"|awk '{print $3,$2,$4,$5}'`

if [ "$LASTUPD_MASTER" != "$LASTUPD_REPLICA" ] ; then
    printlogmess "$ERROR" "$SYNC_ERRNO_2" "$SYNC_DESCR_2 CertificateData Master:${LASTUPD_MASTER} Replica:${LASTUPD_REPLICA}"
    HASFAILED=1
fi


######################################
# Get time when table  LogEntryData was last updated
#
echo "SELECT max(time) from LogEntryData;">/tmp/select3.sql
LASTUPD_LOG_MASTER0=`$MYSQL_BIN $DB_NAME -h $MASTER -u ${DB_USER} --password=${DB_PASSWORD} </tmp/select3.sql 2>/dev/null`
LASTUPD_LOG_MASTER1=`echo $LASTUPD_LOG_MASTER0 |awk '{print $2/1000}'`
LASTUPD_LOG_MASTER=`perl -e "print scalar(localtime($LASTUPD_LOG_MASTER1))"|awk '{print $3,$2,$4,$5}'`

LASTUPD_LOG_REPLICA0=`$MYSQL_BIN $DB_NAME -h $REPLICA -u ${DB_USER} --password=${DB_PASSWORD} </tmp/select3.sql 2>/dev/null`
LASTUPD_LOG_REPLICA1=`echo $LASTUPD_LOG_REPLICA0 |awk '{print $2/1000}'`
LASTUPD_LOG_REPLICA=`perl -e "print scalar(localtime($LASTUPD_LOG_REPLICA1))"|awk '{print $3,$2,$4,$5}'`

if [ "$LASTUPD_LOG_MASTER" != "$LASTUPD_LOG_REPLICA" ] ; then
    printlogmess "$ERROR" "$SYNC_ERRNO_2" "$SYNC_DESCR_2 MaxTime LogEntryData Master: ${LASTUPD_LOG_MASTER} Replica:${LASTUPD_LOG_REPLICA}"
    HASFAILED=1

fi

######################################
# get time when crldata was last updates
#
echo "SELECT max(thisUpdate) from CRLData;">/tmp/select1.sql
LASTUPD_CRL_MASTER0=`$MYSQL_BIN $DB_NAME -h $MASTER -u ${DB_USER} --password=${DB_PASSWORD} </tmp/select1.sql 2>/dev/null`
LASTUPD_CRL_MASTER1=`echo $LASTUPD_CRL_MASTER0 |awk '{print $2/1000}'`
LASTUPD_CRL_MASTER=`perl -e "print scalar(localtime($LASTUPD_CRL_MASTER1))"|awk '{print $3,$2,$4,$5}'`

LASTUPD_CRL_REPLICA0=`$MYSQL_BIN $DB_NAME -h $REPLICA -u ${DB_USER} --password=${DB_PASSWORD} </tmp/select1.sql 2>/dev/null`
LASTUPD_CRL_REPLICA1=`echo $LASTUPD_CRL_REPLICA0 |awk '{print $2/1000}'`
LASTUPD_CRL_REPLICA=`perl -e "print scalar(localtime($LASTUPD_CRL_REPLICA1))"|awk '{print $3,$2,$4,$5}'`

if [ "$LASTUPD_CRL_MASTER" != "$LASTUPD_CRL_REPLICA" ] ; then
    printlogmess "$ERROR" "$SYNC_ERRNO_2" "$SYNC_DESCR_2 CRLData Master: ${LASTUPD_CRL_MASTER} Replica:${LASTUPD_CRL_REPLICA}"
    HASFAILED=1

fi

if [ "x$HASFAILED" -eq "x0" ] ; then 
    printlogmess "$INFO" "$SYNC_ERRNO_1" "$SYNC_DESCR_1"
fi

if [ ${PRINTTOSCREEN} = 1 ] ; then 
    echo "MASTER:$MASTER"
    echo "REPLICA:$REPLICA"
    echo "$COUNTRO_MASTER row in table LogEntryData on $MASTER at $DATELOGFILE"
    echo "$COUNTRO_REPLICA row in table LogEntryData on $REPLICA at $DATELOGFILE"
    echo "Lastupdate in CertificateData on $MASTER $LASTUPD_MASTER"
    echo "Lastupdate in CertificateData on $REPLICA $LASTUPD_REPLICA"
    echo "Lastupdate in LogEntryData on $MASTER $LASTUPD_LOG_MASTER"
    echo "Lastupdate in LogEntryData on $REPLICA $LASTUPD_LOG_REPLICA"
    echo "Lastupdate in CRLData on $MASTER $LASTUPD_CRL_MASTER"
    echo "Lastupdate in CRLData on $REPLICA $LASTUPD_CRL_REPLICA"
fi
