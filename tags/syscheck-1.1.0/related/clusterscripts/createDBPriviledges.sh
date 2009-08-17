#!/bin/sh

#Scripts that creates replication privilegdes for the slave db to the master.

# Set default home if not already set.
SYSCHECK_HOME=${SYSCHECK_HOME:-"/usr/local/syscheck"}

## Import common definitions ##
. $SYSCHECK_HOME/resources.sh


# Copy the hostfiles
cp $CLUSTERSCRIPT_HOME/createPriviledgesNode1.sql.templ $CLUSTERSCRIPT_HOME/createPriviledgesNode1.sql
perl -pi -e "s/HOSTNAME_NODE1/$HOSTNAME_NODE1/g" $CLUSTERSCRIPT_HOME/createPriviledgesNode1.sql
perl -pi -e "s/HOSTNAME_NODE2/$HOSTNAME_NODE2/g" $CLUSTERSCRIPT_HOME/createPriviledgesNode1.sql
perl -pi -e "s/HOSTNAME_VIRTUAL/$HOSTNAME_VIRTUAL/g" $CLUSTERSCRIPT_HOME/createPriviledgesNode1.sql
perl -pi -e "s/DBREP_USER/$DBREP_USER/g" $CLUSTERSCRIPT_HOME/createPriviledgesNode1.sql
perl -pi -e "s/DBREP_PASSWORD/$DBREP_PASSWORD/g" $CLUSTERSCRIPT_HOME/createPriviledgesNode1.sql
perl -pi -e "s/DB_USER/$DB_USER/g" $CLUSTERSCRIPT_HOME/createPriviledgesNode1.sql
perl -pi -e "s/DB_PASSWORD/$DB_PASSWORD/g" $CLUSTERSCRIPT_HOME/createPriviledgesNode1.sql

cp $CLUSTERSCRIPT_HOME/createPriviledgesNode2.sql.templ $CLUSTERSCRIPT_HOME/createPriviledgesNode2.sql
perl -pi -e "s/HOSTNAME_NODE1/$HOSTNAME_NODE1/g" $CLUSTERSCRIPT_HOME/createPriviledgesNode2.sql
perl -pi -e "s/HOSTNAME_NODE2/$HOSTNAME_NODE2/g" $CLUSTERSCRIPT_HOME/createPriviledgesNode2.sql
perl -pi -e "s/HOSTNAME_VIRTUAL/$HOSTNAME_VIRTUAL/g" $CLUSTERSCRIPT_HOME/createPriviledgesNode2.sql
perl -pi -e "s/DB_USER/$DB_USER/g" $CLUSTERSCRIPT_HOME/createPriviledgesNode2.sql
perl -pi -e "s/DB_PASSWORD/$DB_PASSWORD/g" $CLUSTERSCRIPT_HOME/createPriviledgesNode2.sql


scp $CLUSTERSCRIPT_HOME/createPriviledgesNode1.sql $SSH_USER@$HOSTNAME_NODE1:/tmp/createPriviledgesNode1.sql
ssh $SSH_USER@$HOSTNAME_NODE1 "$MYSQL_BIN -u root --password='$MYSQLROOT_PASSWORD' < /tmp/createPriviledgesNode1.sql"
ssh $SSH_USER@$HOSTNAME_NODE1 "rm /tmp/createPriviledgesNode1.sql"

$MYSQL_BIN -u root --password="$MYSQLROOT_PASSWORD" < $CLUSTERSCRIPT_HOME/createPriviledgesNode2.sql 
