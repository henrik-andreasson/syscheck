#!/bin/sh



#Script that creates a test table on the master database.
#the table is created in the EJBCA database and contains a int columnt test
#with the value on 1.
#

# Set default home if not already set.
SYSCHECK_HOME=${SYSCHECK_HOME:-"/usr/local/syscheck"}

## Import common definitions ##
. $SYSCHECK_HOME/resources.sh


# Copy the hostfiles
scp $CLUSTERSCRIPT_HOME/createTestTable.sql $SSH_USER@$HOSTNAME_NODE1:/tmp/createTestTable.sql
ssh $SSH_USER@$HOSTNAME_NODE1 "$MYSQL_BIN -u root --password='$MYSQLROOT_PASSWORD' < /tmp/createTestTable.sql"
 
