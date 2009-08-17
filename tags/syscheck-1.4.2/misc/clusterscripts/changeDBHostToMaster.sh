#!/bin/sh


#Script that copies the hostfiles to all the nodes indicating that
#the primary node should be used as db host
#
#First it marks the primary mysql database as master.
#
#First check ../resources.sg to set environment
#A ssh connection with no password protected keys have to be set up to
#the primary node.
#
# Set default home if not already set.
SYSCHECK_HOME=${SYSCHECK_HOME:-"/usr/local/syscheck"}

## Import common definitions ##
. $SYSCHECK_HOME/resources.sh


$MYSQLDUMP_BIN -u root --password="$MYSQLROOT_PASSWORD" ejbca > /tmp/ejbcaSlaveDB.sql
scp /tmp/ejbcaSlaveDB.sql $SSH_USER@$HOSTNAME_NODE1:/tmp/ejbcaSlaveDB.sql
rm /tmp/ejbcaSlaveDB.sql

scp $CLUSTERSCRIPT_HOME/recreateEJBCADB.sql $SSH_USER@$HOSTNAME_NODE1:/tmp/recreateEJBCADB.sql
ssh $SSH_USER@$HOSTNAME_NODE1 "$MYSQL_BIN -u root --password='$MYSQLROOT_PASSWORD' -D ejbca < /tmp/ejbcaSlaveDB.sql"
scp $CLUSTERSCRIPT_HOME/resetMaster.sql $SSH_USER@$HOSTNAME_NODE1:/tmp/resetMaster.sql
ssh $SSH_USER@$HOSTNAME_NODE1 "$MYSQL_BIN -u root --password='$MYSQLROOT_PASSWORD' -D ejbca < /tmp/resetMaster.sql"
ssh $SSH_USER@$HOSTNAME_NODE1 rm -f /tmp/ejbcaSlaveDB.sql


cp $CLUSTERSCRIPT_HOME/makeSlave.sql.templ $CLUSTERSCRIPT_HOME/makeSlave.sql
perl -pi -e "s/HOSTNAME_NODE1/$HOSTNAME_NODE1/g" $CLUSTERSCRIPT_HOME/makeSlave.sql
perl -pi -e "s/DBREP_USER/$DBREP_USER/g" $CLUSTERSCRIPT_HOME/makeSlave.sql
perl -pi -e "s/DBREP_PASSWORD/$DBREP_PASSWORD/g" $CLUSTERSCRIPT_HOME/makeSlave.sql


$MYSQL_BIN -u root --password="$MYSQLROOT_PASSWORD" < $CLUSTERSCRIPT_HOME/makeSlave.sql

# Copy the hostfiles
cp $CLUSTERSCRIPT_HOME/ejbca-ds-node1.xml.templ $CLUSTERSCRIPT_HOME/ejbca-ds-node1.xml
perl -pi -e "s/HOSTNAME_NODE1/$HOSTNAME_NODE1/g" $CLUSTERSCRIPT_HOME/ejbca-ds-node1.xml
perl -pi -e "s/DB_USER/$DB_USER/g" $CLUSTERSCRIPT_HOME/ejbca-ds-node1.xml
perl -pi -e "s/DB_PASSWORD/$DB_PASSWORD/g" $CLUSTERSCRIPT_HOME/ejbca-ds-node1.xml

# Fail over JBoss datasource
if [ "$DO_DATASOURCE_FAILOVER" == "false" ] ; then
  echo Info: Not failing over JBoss datasources because DO_DATASOURCE_FAILOVER=false.
else
  cp $CLUSTERSCRIPT_HOME/ejbca-ds-node1.xml $JBOSS_HOME/server/default/deploy/ejbca-ds.xml 
  chown jboss:jboss $JBOSS_HOME/server/default/deploy/ejbca-ds.xml 
  scp $CLUSTERSCRIPT_HOME/ejbca-ds-node1.xml $SSH_USER@$HOSTNAME_NODE1:$JBOSS_HOME/server/default/deploy/ejbca-ds.xml
  ssh $SSH_USER@$HOSTNAME_NODE1 chown jboss:jboss $JBOSS_HOME/server/default/deploy/ejbca-ds.xml
  
  # Re-deploy to re-read the new datasource
  cp $EJBCA_HOME/dist/ejbca.ear $JBOSS_HOME/server/default/deploy/ejbca.ear
  chown jboss:jboss  $JBOSS_HOME/server/default/deploy/ejbca.ear
  scp $EJBCA_HOME/dist/ejbca.ear $SSH_USER@$HOSTNAME_NODE1:$JBOSS_HOME/server/default/deploy/ejbca.ear
  ssh $SSH_USER@$HOSTNAME_NODE1 chown jboss:jboss  $JBOSS_HOME/server/default/deploy/ejbca.ear
fi


# Finally mark the primary node as active again.
$CLUSTERSCRIPT_HOME/markNode1AsActive.sh
 
