
#!/bin/bash

# Script that syncronises the primary node of the cluster with the 
# secondary one.
# Jboss should be in the same location on all the nodes set by JBOSS_HOME

#The user root  should have ssh keys set up with null password 
#to transfer files

#All output is directed to deploy.log

# Set default home if not already set.
SYSCHECK_HOME=${SYSCHECK_HOME:-"/usr/local/syscheck"}

## Import common definitions ##
. $SYSCHECK_HOME/resources.sh


echo "Syncronizing JBoss instances ...."
ssh $SSH_USER@$HOSTNAME_NODE1  rm -rf $JBOSS_HOME/server/default/conf
scp -r -p  $JBOSS_HOME/server/default/conf $SSH_USER@$HOSTNAME_NODE1:$JBOSS_HOME/server/default 
ssh $SSH_USER@$HOSTNAME_NODE1  rm -rf $JBOSS_HOME/server/default/deploy
scp -r -p $JBOSS_HOME/server/default/deploy $SSH_USER@$HOSTNAME_NODE1:$JBOSS_HOME/server/default 
ssh $SSH_USER@$HOSTNAME_NODE1  rm -rf $JBOSS_HOME/server/default/lib
scp -r -p $JBOSS_HOME/server/default/lib $SSH_USER@$HOSTNAME_NODE1:$JBOSS_HOME/server/default 

echo "Jboss Syncronized"

echo "Syncronizing PrimeCard ...."
ssh $SSH_USER@$HOSTNAME_NODE1 rm -rf $PRIMECARD_HOME/*.*
scp -r -p $PRIMECARD_HOME/* $SSH_USER@$HOSTNAME_NODE1:$PRIMECARD_HOME
#scp -r -p $PRIMECARD_HOME/*.* $SSH_USER@$HOSTNAME_NODE1:$PRIMECARD_HOME

echo "PrimeCard Syncronized"


