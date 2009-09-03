#!/bin/sh
# Set default home if not already set.
SYSCHECK_HOME=${SYSCHECK_HOME:-"/usr/local/syscheck"}

## Import common definitions ##
. $SYSCHECK_HOME/resources.sh


# Fail over JBoss datasource
if [ "$DO_DATASOURCE_FAILOVER" == "false" ] ; then
  echo Info: Not failing over JBoss datasources because DO_DATASOURCE_FAILOVER=false.
  exit

fi


if [ "x$1" = "xnode1" ] ; then
	HOSTNAME_NODE=$HOSTNAME_NODE1
elif [ "x$1" = "xnode2" ] ; then
	HOSTNAME_NODE=$HOSTNAME_NODE2
else
	echo "arg1 must be the node to enter in the ds conf (node1 or node2)"
	exit
fi


cat <<__EOT__>$JBOSS_HOME/server/default/deploy/ejbca-ds.xml
<?xml version="1.0" encoding="UTF-8"?>

<!--

This is the template used to configure ejbca datasource with the appropriate database
You need to drop your jdbc driver in /usr/local/jboss/server/default/lib

Customize at will as this is mainly for development.

$Id: ejbca-ds-node1.xml.templ,v 1.1 2006-10-30 17:14:44 kinneh Exp $

 -->

<datasources>
   <local-tx-datasource>

      <!-- The jndi name of the DataSource, it is prefixed with java:/ -->
      <!-- Datasources are not available outside the virtual machine -->
      <jndi-name>EjbcaDS</jndi-name>

      <connection-url>jdbc:mysql://${HOSTNAME_NODE}:3306/${DB_NAME}</connection-url>

      <!-- The driver class -->
      <driver-class>com.mysql.jdbc.Driver</driver-class>

      <!-- The login and password -->
      <user-name>${DB_USER}</user-name>
      <password>${DB_PASSWORD}</password>

      <!--example of how to specify class that determines if exception means connection should be destroyed-->
      <!--exception-sorter-class-name>org.jboss.resource.adapter.jdbc.vendor.DummyExceptionSorter</exception-sorter-class-name-->

      <!-- this will be run before a managed connection is removed from the pool for use by a client-->
      <!--<check-valid-connection-sql>select * from something</check-valid-connection-sql> -->

      <!-- The minimum connections in a pool/sub-pool. Pools are lazily constructed on first use -->
      <min-pool-size>5</min-pool-size>

      <!-- The maximum connections in a pool/sub-pool -->
      <max-pool-size>20</max-pool-size>

      <!-- The time before an unused connection is destroyed -->
      <!-- NOTE: This is the check period. It will be destroyed somewhere between 1x and 2x this timeout after last use -->
      <!-- Note for HSQLDB! - If you have problems, set to 0 to disable idle connection removal, HSQLDB has a problem with not reaping threads on closed connections -->
      <idle-timeout-minutes>5</idle-timeout-minutes>

      <!-- sql to call when connection is created
        <new-connection-sql>some arbitrary sql</new-connection-sql>
      -->

      <!-- sql to call on an existing pooled connection when it is obtained from pool
         <check-valid-connection-sql>some arbitrary sql</check-valid-connection-sql>
      -->

      <!-- example of how to specify a class that determines a connection is valid before it is handed out from the pool
         <valid-connection-checker-class-name>org.jboss.resource.adapter.jdbc.vendor.DummyValidConnectionChecker</valid-connection-checker-class-name>
      -->

      <!-- Whether to check all statements are closed when the connection is returned to the pool,
           this is a debugging feature that should be turned off in production -->
      <track-statements/>

   </local-tx-datasource>

</datasources>
__EOT__
if [ $? -eq 0 ] ; then
	echo "ejbca-ds.xml in jboss switched host to ${HOSTNAME_NODE}"
	echo "remember to restart jboss when you want the change to take effect"
else
	echo "failed to change ejbca-ds.xml in jboss"
fi
