#!/bin/sh
# File containing COMMON definitions, use local script for local definitions !!!!
# IMPORTANT, This file might be Very sensitive and contain PIN codes and passwords.
# Make only readable by root.

### General settings ###
SYSCHECK_VERSION=1.3

# Script Location
SYSCHECK_HOME=${SYSCHECK_HOME:-"/usr/local/syscheck"}
export SYSCHECK_HOME
PATH=$SYSCHECK_HOME:$PATH

DATE=`date +'%Y-%m-%d_%H.%m.%S'`

# use the printlog function
. $SYSCHECK_HOME/lib/printlogmess.sh

# get definitions for EJBCA
if [ -f /etc/ejbca/environment ] ; then
	. /etc/ejbca/environment
fi

# System name is name of the overall system that is monitored.
SYSTEMNAME=PKI

# Username used for no-passphrase ssh login
SSH_USER=jboss


## Language ##
#select you lang (choose from files in lang/)
SYSCHECK_LANG=english

# source the lang func
. ${SYSCHECK_HOME}/lib/lang.sh

# source the config func
. ${SYSCHECK_HOME}/lib/config.sh

### EJBCA settings ###
#Path to EJBCA
EJBCA_HOME=/usr/local/ejbca 

#Path to active jboss config
JBOSS_HOME=/usr/local/jboss

# List indicating CAs to activate, should contain a list of caname and PIN separated by space.  
# Also used for handling CRLs.
CANAME[0]="test" 
CAPIN[0]="1903"
#uncomment to activate more CA:s
#CANAME[1]="test2"
#CAPIN[1]="1023"
#CANAME[2]="test2"
#CAPIN[2]="1023"


### Application server database user and password ###
# Example:
# For EJBCA you should have DB_NAME=ejbca and DB_TEST_TABLE=CertificateData
# For ExtRA you should have DB_NAME=messages and DB_TEST_TABLE=message
DB_NAME=ejbca
DB_USER=ejbca
DB_PASSWORD="foo123"
DB_TEST_TABLE=CertificateData


### Mysql ###
# Database replication user and password 
DBREP_USER=ejbcarep
DBREP_PASSWORD="foo123"

#Path to mysql binary
MYSQL_BIN=/usr/local/mysql/bin/mysql

#Path to mysqldump binary
MYSQLDUMP_BIN=/usr/local/mysql/bin/mysqldump

#Password for Mysql root
MYSQLROOT_PASSWORD="foo123"

#Name of the mysql backup file.
MYSQLBACKUPFILE=/var/backup/ejbcabackup
MYSQLBACKUPFULLFILENAME="${MYSQLBACKUPFILE}-${DATE}.sql"


### CLUSTER SCRIPT RESOURCES ###
#Depending if the scripts is running as a cluster or standalone
#might different levels with different errorcodes be reported.
#Comment and uncomment the levels you want to change

#Path do clusterscript directory
CLUSTERSCRIPT_HOME=$SYSCHECK_HOME/related/clusterscripts

#Path do ejbcascript directory
EJBCASCRIPT_HOME=$SYSCHECK_HOME/misc/ejbca


#IP address or hostname to primary and secondary cluster nodes.
HOSTNAME_NODE1=192.168.0.11
HOSTNAME_NODE2=192.168.0.12

#The virual IP address or hostname used by the cluster
HOSTNAME_VIRTUAL=192.168.0.15
NETMASK_VIRTUAL=255.255.255.0
IF_VIRTUAL=eth0


# Indicates if the datasources in JBoss should be failed over.
# Useful to set to false on OCSP-responders, if thay should always run against their local databases.
# Anything other than false means true
DO_DATASOURCE_FAILOVER=true

#Path to file indicating which db node that currently is master
ACTIVENODE_FILE=/tmp/activeNode.txt

