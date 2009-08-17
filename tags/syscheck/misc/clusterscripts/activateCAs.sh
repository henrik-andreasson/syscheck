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
  NAME=${CANAME[$i]}
  PIN=${CAPIN[$i]}
  
  echo "Activating CA :  $NAME on node $HOSTNAME_NODE2"
  cd $EJBCA_HOME;bin/ejbca.sh ca activateca $NAME $PIN
 
done

