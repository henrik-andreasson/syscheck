#!/bin/sh

#Script that creates a test table on the master database.
#the table is created in the EJBCA database and contains a int columnt test
#with the value on 1.
#

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
echo "cleaning and inserting new val: $newval"
echo "delete from test"                   | $MYSQL_BIN $DB_NAME -u ${DB_USER} --password=${DB_PASSWORD}
echo "insert into test set value=$newval" | $MYSQL_BIN $DB_NAME -u ${DB_USER} --password=${DB_PASSWORD}

sleep 1
echo "values from $HOSTNAME_NODE1"
echo "SELECT value from test;" | $MYSQL_BIN $DB_NAME -h $HOSTNAME_NODE1 -u ${DB_USER} --password=${DB_PASSWORD}
echo "values from $HOSTNAME_NODE2"
echo "SELECT value from test;" | $MYSQL_BIN $DB_NAME -h $HOSTNAME_NODE2 -u ${DB_USER} --password=${DB_PASSWORD}
