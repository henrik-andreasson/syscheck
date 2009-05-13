#!/bin/sh
# File containing COMMON definitions, use local script for local definitions !!!!
# IMPORTANT, This file might be Very sensitive and contain PIN codes and passwords.
# Make only readable by root.

### General settings ###
SYSCHECK_VERSION=

# Script Location
SYSCHECK_HOME=${SYSCHECK_HOME:-"/usr/local/syscheck"}
export SYSCHECK_HOME
PATH=$SYSCHECK_HOME:$PATH


# use the printlog function
. $SYSCHECK_HOME/lib/printlogmess.sh

# get definitions for EJBCA
if [ -f /etc/ejbca/environment ] ; then
	. /etc/ejbca/environment
fi

# cap message length to ...
MESSAGELENGTH=160

export LD_LIBRARY_PATH=/usr/local/pcsc/lib/

# System name is name of the overall system that is monitored.
SYSTEMNAME=PKI

# Username used for no-passphrase ssh login
SSH_USER=jboss


## Language ##
#select you lang (choose from files in lang/)
SYSCHECK_LANG=english

# save status to a file values: 1 or 0
# will create a file in <syscheck>/var/last_status
SAVELASTSTATUS=1

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
CANAME[0]="eIDCA" 
CAPIN[0]="1111"
CANAME[1]="eSignCA"
CAPIN[1]="1111"
CANAME[2]="MSDomainLogonCA"
CAPIN[2]="1111"
CANAME[3]="ServerCA"
CAPIN[3]="1111"


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
MYSQL_BIN=/usr/bin/mysql

# path to mysqladmin
MYSQLADMIN_BIN=/usr/bin/mysqladmin

#Path to mysqldump binary
MYSQLDUMP_BIN=/usr/bin/mysqldump

#Password for Mysql root
MYSQLROOT_PASSWORD="foo123"



### CLUSTER SCRIPT RESOURCES ###
#Depending if the scripts is running as a cluster or standalone
#might different levels with different errorcodes be reported.
#Comment and uncomment the levels you want to change

#Path do clusterscript directory
CLUSTERSCRIPT_HOME=$SYSCHECK_HOME/misc/clusterscripts

#Path do ejbcascript directory
EJBCASCRIPT_HOME=$SYSCHECK_HOME/misc/ejbca


#IP address or hostname to primary and secondary cluster nodes.
THIS_NODE=NODE2
# master node
HOSTNAME_NODE1=192.168.158.151
# slave node
HOSTNAME_NODE2=192.168.158.171

#The virtual interface has to be the same interface as $HOSTNAME_NODEX 
HOSTNAME_VIRTUAL=192.168.0.10
NETMASK_VIRTUAL=255.255.255.0
IF_VIRTUAL="eth0:0"


# Indicates if the datasources in JBoss should be failed over.
# Useful to set to false on OCSP-responders, if thay should always run against their local databases.
# Anything other than false means true
DO_DATASOURCE_FAILOVER=true

#Path to file indicating which db node that currently is master
ACTIVENODE_FILE=/tmp/activeNode.txt

