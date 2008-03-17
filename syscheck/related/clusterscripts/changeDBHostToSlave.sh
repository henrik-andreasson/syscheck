#!/bin/sh



#Script that copies the hostfiles to all the nodes indicating that
#the slave should be used as db host
#
#First it marks the slave mysql database as master.


#Set default home if not already set.
SYSCHECK_HOME=${SYSCHECK_HOME:-"/usr/local/syscheck"}

## Import common definitions ##
. $SYSCHECK_HOME/resources.sh


$MYSQL_BIN -u root --password="$MYSQLROOT_PASSWORD" < $CLUSTERSCRIPT_HOME/makeMaster.sql

# Copy the hostfiles
cp $CLUSTERSCRIPT_HOME/ejbca-ds-node2.xml.templ $CLUSTERSCRIPT_HOME/ejbca-ds-node2.xml
perl -pi -e "s/HOSTNAME_NODE2/$HOSTNAME_NODE2/g" $CLUSTERSCRIPT_HOME/ejbca-ds-node2.xml
perl -pi -e "s/DB_USER/$DB_USER/g" $CLUSTERSCRIPT_HOME/ejbca-ds-node2.xml
perl -pi -e "s/DB_PASSWORD/$DB_PASSWORD/g" $CLUSTERSCRIPT_HOME/ejbca-ds-node2.xml

# Fail over JBoss datasource
if [ "$DO_DATASOURCE_FAILOVER" == "false" ] ; then
  echo Info: Not failing over JBoss datasources because DO_DATASOURCE_FAILOVER=false.
else
  cp $CLUSTERSCRIPT_HOME/ejbca-ds-node2.xml $JBOSS_HOME/server/default/deploy/ejbca-ds.xml
  chown jboss:jboss $JBOSS_HOME/server/default/deploy/ejbca-ds.xml 
  scp $CLUSTERSCRIPT_HOME/ejbca-ds-node2.xml $SSH_USER@$HOSTNAME_NODE1:$JBOSS_HOME/server/default/deploy/ejbca-ds.xml
  ssh $SSH_USER@$HOSTNAME_NODE1 chown jboss:jboss $JBOSS_HOME/server/default/deploy/ejbca-ds.xml
  
  # Re-deploy to re-read the new datasource
  cp $EJBCA_HOME/dist/ejbca.ear $JBOSS_HOME/server/default/deploy/ejbca.ear
  chown jboss:jboss $JBOSS_HOME/server/default/deploy/ejbca.ear
  scp $EJBCA_HOME/dist/ejbca.ear $SSH_USER@$HOSTNAME_NODE1:$JBOSS_HOME/server/default/deploy/ejbca.ear
  ssh $SSH_USER@$HOSTNAME_NODE1 chown jboss:jboss $JBOSS_HOME/server/default/deploy/ejbca.ear

  sleep 20
  $CLUSTERSCRIPT_HOME/activateCAs.sh  
fi
