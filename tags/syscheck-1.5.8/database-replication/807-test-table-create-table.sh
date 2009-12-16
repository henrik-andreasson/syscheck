#!/bin/sh

#Script that creates a test table on the master database.
#the table is created in the EJBCA database and contains a int columnt test
#with the value on 1.
#

# Set default home if not already set.
SYSCHECK_HOME=${SYSCHECK_HOME:-"/usr/local/syscheck"}

## Import common definitions ##
. $SYSCHECK_HOME/resources.sh


OUTFILE="$CLUSTERSCRIPT_HOME/tmp_create-test-table.sql"

echo "USE $DB_NAME;" > $OUTFILE
echo 'DROP TABLE IF EXISTS `test`;' >> $OUTFILE
echo "CREATE TABLE test (value INT);" >> $OUTFILE
echo "INSERT INTO test SET value='1';"  >> $OUTFILE

echo "creating the test table:"

$MYSQL_BIN $DB_NAME -u root --password=$MYSQLROOT_PASSWORD < $OUTFILE
rm $OUTFILE
