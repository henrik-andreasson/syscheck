#!/bin/bash

# Set SYSCHECK_HOME if not already set.

# 1. First check if SYSCHECK_HOME is set then use that
if [ "x${SYSCHECK_HOME}" = "x" ] ; then
# 2. Check if /etc/syscheck.conf exists then source that (put SYSCHECK_HOME=/path/to/syscheck in ther)
    if [ -e /etc/syscheck.conf ] ; then 
	source /etc/syscheck.conf 
    else
# 3. last resort use default path
	SYSCHECK_HOME="/usr/local/syscheck"
    fi
fi

if [ ! -f ${SYSCHECK_HOME}/syscheck.sh ] ; then echo "$0: Can't find syscheck.sh in SYSCHECK_HOME ($SYSCHECK_HOME)" ;exit ; fi




## Import common definitions ##
. $SYSCHECK_HOME/config/database-replication.conf


# Fail over JBoss datasource
if [ "$DO_DATASOURCE_FAILOVER" == "false" ] ; then
  echo Info: Not failing over JBoss datasources because DO_DATASOURCE_FAILOVER=false.
  exit

fi

# uniq ID of script (please use in the name of this file also for convinice for finding next availavle number)
SCRIPTID=816

# Index is used to uniquely identify one test done by the script (a harddrive, crl or cert)
SCRIPTINDEX=00


if [ "x$1" = "xnode1" ] ; then
	HOSTNAME_NODE=$HOSTNAME_NODE1
elif [ "x$1" = "xnode2" ] ; then
	HOSTNAME_NODE=$HOSTNAME_NODE2
else
	echo "arg1 must be the node to enter in the ds conf (node1 or node2)"
	exit
fi
RET=0

#      <connection-url>jdbc:mysql://${HOSTNAME_NODE}:3306/${DB_NAME}</connection-url>
perl -pi -e "s#connection-url>jdbc:mysql:.*connection-url#connection-url>jdbc:mysql://${HOSTNAME_NODE}:3306/${DB_NAME}</connection-url#gio" ${JBOSS_HOME}/server/default/deploy/ejbca-ds.xml
grep ${HOSTNAME_NODE} ${JBOSS_HOME}/server/default/deploy/ejbca-ds.xml || RET=1

#      <user-name>${DB_USER}</user-name>
perl -pi -e "s#user-name.*user-name#user-name>${DB_USER}</user-name#gio" ${JBOSS_HOME}/server/default/deploy/ejbca-ds.xml
grep ${DB_USER}  ${JBOSS_HOME}/server/default/deploy/ejbca-ds.xml || RET=2

#      <password>${DB_PASSWORD}</password>
perl -pi -e "s#password.*password#password>${DB_PASSWORD}</password#gio" ${JBOSS_HOME}/server/default/deploy/ejbca-ds.xml
grep ${DB_PASSWORD} ${JBOSS_HOME}/server/default/deploy/ejbca-ds.xml || RET=3

if [ ! -x ${EJBCA_HOME}/conf/database.properties ] ; then
	cp ${EJBCA_HOME}/conf/database.properties.sample ${EJBCA_HOME}/conf/database.properties 
else
	RET=10
fi

perl -pi -e \"s/#database.name=mysql/database.name=mysql/\" ${EJBCA_HOME}/conf/database.properties
grep "^database.name=mysql/$" ${EJBCA_HOME}/conf/database.properties || RET=4

perl -pi -e \"s/#datasource.mapping=mySQL/datasource.mapping=mySQL/\" ${EJBCA_HOME}/conf/database.properties
grep "^datasource.mapping=mySQL$" ${EJBCA_HOME}/conf/database.properties || RET=5


perl -pi -e \"s/#database.url=jdbc:mysql:\/\/127.0.0.1:3306\/ejbca$/database.url=jdbc:mysql:\/\/${HOSTNAME_NODE}:3306\/${mysqlejbcadbname}/\" ${EJBCA_HOME}/conf/database.properties
grep "database.url.*${HOSTNAME_NODE}" ${EJBCA_HOME}/conf/database.properties || RET=6

perl -pi -e \"s/#database.driver=com.mysql.jdbc.Driver/database.driver=com.mysql.jdbc.Driver/\" ${EJBCA_HOME}/conf/database.properties
grep "^database.driver=com.mysql.jdbc.Driver$" ${EJBCA_HOME}/conf/database.properties || RET=7

perl -pi -e \"s/#database.username=ejbca/database.username=${mysqlejbcauser}/\" ${EJBCA_HOME}/conf/database.properties
grep "database.username=${mysqlejbcauser}" ${EJBCA_HOME}/conf/database.properties || RET=8

perl -pi -e \"s/#database.password=ejbca/database.password=${mysqlejbcapass}/\" ${EJBCA_HOME}/conf/database.properties
grep "database.password=${mysqlejbcapass}" ${EJBCA_HOME}/conf/database.properties || RET=9


SCRIPTINDEX=$(addOneToIndex $SCRIPTINDEX)
if [ $RET -eq 0 ] ; then
	printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   $INFO $ERRNO_1 "$DESCR_1"
else
	printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   $ERROR $ERRNO_2 "$DESCR_2" $RET
fi
