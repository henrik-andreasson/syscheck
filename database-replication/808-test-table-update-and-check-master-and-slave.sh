#!/bin/sh

#Script that creates a test table on the master database.
#the table is created in the EJBCA database and contains a int columnt test
#with the value on 1.
#

# Set default home if not already set.
SYSCHECK_HOME=${SYSCHECK_HOME:-"/usr/local/syscheck"}

## Import common definitions ##
. $SYSCHECK_HOME/resources.sh


newval=`perl -e 'print time'`
echo "cleaning and inserting new val: $newval"
echo "delete from test" | $MYSQL_BIN $DB_NAME -h $HOSTNAME_NODE1 -u ${DB_USER} --password=${DB_PASSWORD}
echo "insert into test set value=$newval" | $MYSQL_BIN $DB_NAME -h $HOSTNAME_NODE1 -u ${DB_USER} --password=${DB_PASSWORD}

sleep 1
echo "values from $HOSTNAME_NODE1"
echo "SELECT value from test;" | $MYSQL_BIN $DB_NAME -h $HOSTNAME_NODE1 -u ${DB_USER} --password=${DB_PASSWORD}
echo "values from $HOSTNAME_NODE2"
echo "SELECT value from test;" | $MYSQL_BIN $DB_NAME -h $HOSTNAME_NODE2 -u ${DB_USER} --password=${DB_PASSWORD}
