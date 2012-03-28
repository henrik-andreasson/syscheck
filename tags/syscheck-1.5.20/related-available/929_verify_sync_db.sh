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
Sub_DbsynkCheck(){
######################################
#  Get Ip adress on masternodea and replica
#

##THIS_NODE=NODE2

eval MASTER="\$HOSTNAME_${THIS_NODE}"

if [ ${MASTER} = $HOSTNAME_NODE1 ]
then
        REPLICA=$HOSTNAME_NODE2
else
         REPLICA=$HOSTNAME_NODE1
fi
##DATE_AGO=`expr \`date --date='2 days ago' +%s\` \* 1000`
DATE_AGO=`expr \`date --date='10 minutes ago' +%s\` \* 1000`
######################################
# Subrutin for errors
#
ERROR_MASTER=0
ERROR_REPLICA=0
FEL=0
sub_Error(){
if [ $1 != 0 ]
then
test ${ERROR_MASTER} != 0 && ERR_MSG="Can not connect to Master: $MASTER"
test ${ERROR_REPLICA} != 0 && ERR_MSG="Can not connect to Replica: $REPLICA"
test ${PRINTTOSCREEN} = 1 && echo ${ERR_MSG}
FEL=1
fi
}

######################################
# Create sqlscript
#
#select from LogEntryData where  time < ${DATE_AGO} limit 1;
#select count(*) from LogEntryData where  time < ${DATE_AGO};
echo "SELECT max(thisUpdate) from CRLData;">/tmp/select1.sql
echo " SELECT max(updateTime) from CertificateData;">/tmp/select2.sql
echo " SELECT max(time) from LogEntryData;">/tmp/select3.sql
echo "SELECT count(*) from LogEntryData where time < ${DATE_AGO};" >/tmp/select4.sql

######################################
# Count row in LogEntryData
#
DATEAGO=`echo ${DATE_AGO} |awk '{print $1/1000}'`
DATELOGFILE=`perl -e "print scalar(localtime($DATEAGO))"|awk '{print $3,$2,$4,$5}'`
COUNTRO_MASTER=`$MYSQL_BIN -N $DB_NAME -h $MASTER -u ${DB_USER} --password=${DB_PASSWORD} </tmp/select4.sql 2>/dev/null`
ERROR_MASTER=$?
sub_Error ${ERROR_MASTER}
test $FEL != 0 && return 1
COUNTRO_REPLICA=`$MYSQL_BIN -N $DB_NAME -h $REPLICA -u ${DB_USER} --password=${DB_PASSWORD} </tmp/select4.sql 2>/dev/null`
ERROR_REPLICA=$?
sub_Error ${ERROR_REPLICA}
test $FEL != 0 && return 1
######################################
# Get time when table CertificateData and crldata was last updated
#

LASTUPD_MASTER=`$MYSQL_BIN $DB_NAME -h $MASTER -u ${DB_USER} --password=${DB_PASSWORD} </tmp/select2.sql 2>/dev/null`
ERROR_MASTER=$?
sub_Error ${ERROR_MASTER}
test $FEL != 0 && return 1
LASTUPD_MASTER=`echo $LASTUPD_MASTER |awk '{print $2/1000}'`
LASTUPD_MASTER=`perl -e "print scalar(localtime($LASTUPD_MASTER))"|awk '{print $3,$2,$4,$5}'`
LASTUPD_REPLICA=`$MYSQL_BIN $DB_NAME -h $REPLICA -u ${DB_USER} --password=${DB_PASSWORD} </tmp/select2.sql 2>/dev/null`
ERROR_REPLICA=$?
sub_Error ${ERROR_REPLICA}
test $FEL != 0 && return 1
LASTUPD_REPLICA=`echo $LASTUPD_REPLICA |awk '{print $2/1000}'`
LASTUPD_REPLICA=`perl -e "print scalar(localtime($LASTUPD_REPLICA))"|awk '{print $3,$2,$4,$5}'`

LASTUPD_LOG_MASTER=`$MYSQL_BIN $DB_NAME -h $MASTER -u ${DB_USER} --password=${DB_PASSWORD} </tmp/select3.sql 2>/dev/null`
ERROR_MASTER=$?
sub_Error ${ERROR_MASTER}
test $FEL != 0 && return 1
LASTUPD_LOG_MASTER=`echo $LASTUPD_LOG_MASTER |awk '{print $2/1000}'`
LASTUPD_LOG_MASTER=`perl -e "print scalar(localtime($LASTUPD_LOG_MASTER))"|awk '{print $3,$2,$4,$5}'`
LASTUPD_LOG_REPLICA=`$MYSQL_BIN $DB_NAME -h $REPLICA -u ${DB_USER} --password=${DB_PASSWORD} </tmp/select3.sql 2>/dev/null`
ERROR_REPLICA=$?
sub_Error ${ERROR_REPLICA}
test $FEL != 0 && return 1
LASTUPD_LOG_REPLICA=`echo $LASTUPD_LOG_REPLICA |awk '{print $2/1000}'`
LASTUPD_LOG_REPLICA=`perl -e "print scalar(localtime($LASTUPD_LOG_REPLICA))"|awk '{print $3,$2,$4,$5}'`

LASTUPD_CRL_MASTER=`$MYSQL_BIN $DB_NAME -h $MASTER -u ${DB_USER} --password=${DB_PASSWORD} </tmp/select1.sql 2>/dev/null`
ERROR_MASTER=$?
sub_Error ${ERROR_MASTER}
test $FEL != 0 && return 1
LASTUPD_CRL_MASTER=`echo $LASTUPD_CRL_MASTER |awk '{print $2/1000}'`
LASTUPD_CRL_MASTER=`perl -e "print scalar(localtime($LASTUPD_CRL_MASTER))"|awk '{print $3,$2,$4,$5}'`
LASTUPD_CRL_REPLICA=`$MYSQL_BIN $DB_NAME -h $REPLICA -u ${DB_USER} --password=${DB_PASSWORD} </tmp/select1.sql 2>/dev/null`
####LASTUPD_CRL_REPLICA="ost 1319790003000"
ERROR_REPLICA=$?
sub_Error ${ERROR_REPLICA}
test $FEL != 0 && return 1
LASTUPD_CRL_REPLICA=`echo $LASTUPD_CRL_REPLICA |awk '{print $2/1000}'`
LASTUPD_CRL_REPLICA=`perl -e "print scalar(localtime($LASTUPD_CRL_REPLICA))"|awk '{print $3,$2,$4,$5}'`
}
START=1
Sub_DbsynkCheck

if [ $? != 0 ]
then
  if [ $ERROR_MASTER != 0 ]
  then
   printlogmess "$ERROR" "$SYNC_ERRNO_3" "$SYNC_DESCR_3 Master:${MASTER}"
   exit 1
  fi

  if [ $ERROR_REPLICA != 0 ]
  then
   printlogmess "$ERROR" "$SYNC_ERRNO_3" "$SYNC_DESCR_3 Replica:${REPLICA}"
   exit 1
  fi
fi

 

###echo $VALUE_NODE1 $VALUE_NODE2
NODE1=`echo $COUNTRO_MASTER|awk '{print $1}'`
NODE2=`echo $COUNTRO_REPLICA|awk '{print $1}'`

#############################
# For testing
##NODE2=0
##LASTUPD_NODE2="3 Sep 12:53:20 2011"

##########################################
# If row differ we have problemwith sync
#

 

if [ $NODE1 != $NODE2 ]
then
        if [ "$LASTUPD_CRL_MASTER" != "$LASTUPD_CRL_REPLICA" ]
        then
                sync=FAIL
                CHECK_CRL=YES
        fi
        if [ "$LASTUPD_LOG_MASTER" != "$LASTUPD_LOG_REPLICA" ]
        then
                sync=FAIL
                CHECK_LOG=YES
        fi
        if [ "$LASTUPD_MASTER" != "$LASTUPD_REPLICA" ]
        then
                sync=FAIL
                CHECK_=YES
        fi
fi

# Sends an error to syslog if x"$sync" is FAIL.
if [ "x$sync" = "xFAIL" ] ; then
    ##printlogmess "$ERROR" "$SYNC_ERRNO_2" "$SYNC_DESCR_2 $LASTUPD_CRL_MASTER /$LASTUPD_CRL_REPLICA Last sync:$SYNCDATE Last Certupdate on $REPLICA:$LASTUPD_REPLICA "
    printlogmess "$ERROR" "$SYNC_ERRNO_2" "Last update on Replica: $REPLICA : Crldata: $LASTUPD_CRL_REPLICA LOGS: $LASTUPD_LOG_REPLICA Cert:$LASTUPD_REPLICA "
else
    printlogmess "$INFO" "$SYNC_ERRNO_1" "$SYNC_DESCR_1"
fi
if [ ${PRINTTOSCREEN} = 1 ]
then
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
