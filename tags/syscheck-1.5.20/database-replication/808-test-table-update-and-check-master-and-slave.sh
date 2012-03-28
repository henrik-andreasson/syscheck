#!/bin/sh

#Script that creates a test table on the master database.
#the table is created in the EJBCA database and contains a int columnt test
#with the value on 1.
#
# mzbradm 110726 Update with two Variabels that is used in the script SYSCHECK_HOME/script-avalible/sc_30_check_sync.sh

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
. $SYSCHECK_HOME/config/database-replication.conf


newval=`perl -e 'print time'`
echo "cleaning and inserting new val: $newval into HOSTNAME_NODE1:$HOSTNAME_NODE1"
echo "delete from test"                   | $MYSQL_BIN $DB_NAME -u ${DB_USER} --password=${DB_PASSWORD} -h $HOSTNAME_NODE1
echo "insert into test set value=$newval" | $MYSQL_BIN $DB_NAME -u ${DB_USER} --password=${DB_PASSWORD} -h $HOSTNAME_NODE1
sleep 1

# Create sqlscript
echo "SELECT value from test;">/tmp/select.sql
echo "SELECT max(updateTime) from CertificateData;">/tmp/select1.sql
# Check the value in table test
VALUE_NODE1=`$MYSQL_BIN $DB_NAME -h $HOSTNAME_NODE1 -u ${DB_USER} --password=${DB_PASSWORD} </tmp/select.sql`
export VALUE_NODE1 
echo "values from $HOSTNAME_NODE1"
echo $VALUE_NODE1
VALUE_NODE2=`$MYSQL_BIN $DB_NAME -h $HOSTNAME_NODE2 -u ${DB_USER} --password=${DB_PASSWORD} </tmp/select.sql`
echo "values from $HOSTNAME_NODE2"
echo $VALUE_NODE2
export VALUE_NODE1 VALUE_NODE2

# Get time when table CertificateData was last updated
LASTUPD_NODE1=`$MYSQL_BIN $DB_NAME -h $HOSTNAME_NODE1 -u ${DB_USER} --password=${DB_PASSWORD} </tmp/select1.sql`
LASTUPD_NODE1=`echo $LASTUPD_NODE1 |awk '{print $2/1000}'`
LASTUPD_NODE1=`perl -e "print scalar(localtime($LASTUPD_NODE1))"|awk '{print $3,$2,$4,$5}'`
LASTUPD_NODE2=`$MYSQL_BIN $DB_NAME -h $HOSTNAME_NODE2 -u ${DB_USER} --password=${DB_PASSWORD} </tmp/select1.sql`
LASTUPD_NODE2=`echo $LASTUPD_NODE2 |awk '{print $2/1000}'`
LASTUPD_NODE2=`perl -e "print scalar(localtime($LASTUPD_NODE2))"|awk '{print $3,$2,$4,$5}'`
echo "Lastupdate in CertificateData on $HOSTNAME_NODE1 $LASTUPD_NODE1"
echo "Lastupdate in CertificateData on $HOSTNAME_NODE2 $LASTUPD_NODE2"
