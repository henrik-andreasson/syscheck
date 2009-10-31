#!/bin/sh

#Script that creates a test table on the master database.
#the table is created in the EJBCA database and contains a int columnt test
#with the value on 1.
#

# Set default home if not already set.
SYSCHECK_HOME=${SYSCHECK_HOME:-"/usr/local/syscheck"}

## Import common definitions ##
. $SYSCHECK_HOME/resources.sh


$MYSQL_BIN $DB_NAME -h $HOSTNAME_NODE1 -u ${DB_USER} --password=${DB_PASSWORD}
