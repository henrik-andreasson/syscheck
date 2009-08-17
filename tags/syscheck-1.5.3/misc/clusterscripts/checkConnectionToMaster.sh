#!/bin/sh

#Script that test a connection against a test table on the master database.
#This is the main script that should be runned as a cron-job.

# Set default home if not already set.
SYSCHECK_HOME=${SYSCHECK_HOME:-"/usr/local/syscheck"}

## Import common definitions ##
. $SYSCHECK_HOME/resources.sh

# Start with checking that node1 is the active db node.
if grep -q Node1 $ACTIVENODE_FILE
then
  # Check that the Node1 database is OK.
  echo "Node1 is active"

  $MYSQL_BIN -u $DB_USER --password="$DB_PASSWORD" -h $HOSTNAME_NODE1 < $CLUSTERSCRIPT_HOME/testMaster.sql > /tmp/mysqlMasterTest.res

  if grep -q 1  /tmp/mysqlMasterTest.res
    then 
      echo "Master Database is OK"
    else 
      echo "Master Database is NOT OK, failing over to slave"
      $CLUSTERSCRIPT_HOME/changeDBHostToSlave.sh 
      $CLUSTERSCRIPT_HOME/markNode2AsActive.sh
  fi

  rm /tmp/mysqlMasterTest.res
else
  echo "Node2 (Slave) is active, test not performed"
fi
