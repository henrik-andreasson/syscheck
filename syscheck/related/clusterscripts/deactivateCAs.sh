#!/bin/sh

#Script that test a connection against a test table on the master database.
#This is the main script that should be runned as a cron-job.

# Set default home if not already set.
SYSCHECK_HOME=${SYSCHECK_HOME:-"/usr/local/syscheck"}

## Import common definitions ##
. $SYSCHECK_HOME/resources.sh

cd $EJBCA_HOME
for (( i = 0 ;  i < ${#CANAME[@]} ; i++ ))
do

  echo "Deactivating CA :  ${CANAME[$i]} on node $HOSTNAME_NODE2"
  bin/ejbca.sh ca deactivateca ${CANAME[$i]} 

done

