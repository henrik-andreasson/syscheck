#!/bin/sh
# File containing COMMON defitions, use local script for local definitions !!!!
# IMPORTANT, This file might be Very sensitive and contain PIN codes and passwords.
# Make only readable by root.


### General settings ###

# Script Location
SYSCHECK_HOME=${SYSCHECK_HOME:-"/usr/local/syscheck"}
export SYSCHECK_HOME
PATH=$SYSCHECK_HOME:$PATH

# use the printlog function
. $SYSCHECK_HOME/lib/printlogmess.sh

# System name is name of the overall system that is supervised.
SYSTEMNAME=PKI

# Username used for no-passphrase ssh login
SSH_USER=jboss


## Language ##
#select you lang (choose from files in lang/)
SYSCHECK_LANG=english

# source the specified lang
. ${SYSCHECK_HOME}/lang/syscheck.${SYSCHECK_LANG}



### EJBCA settings ###
#Path to EJBCA
EJBCA_HOME=/usr/local/ejbca 

#Path to active jboss config
JBOSS_HOME=/usr/local/jboss

#List indicating CAs to activate, should contain a list of caname and PIN separated by space.  
CANAME[0]="test" 
CAPIN[0]="1903"
#uncomment to activate more CA:s
#CANAME[1]="test2"
#CAPIN[1]="1023"
#CANAME[2]="test2"
#CAPIN[2]="1023"


### Application server database user and password ###
DB_USER=ejbca
DB_PASSWORD="foo123"


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



### CLUSTER SCRIPT RESOURCES ###
#Depending if the scripts is running as a cluster or standalone
#might different levels with different errorcodes be reported.
#Comment and uncomment the levels you want to change

#Path do clusterscript directory
CLUSTERSCRIPT_HOME=$SYSCHECK_HOME/related/clusterscripts

#IP address or hostname to primary and secondary cluster nodes.
HOSTNAME_NODE1=192.168.0.11
HOSTNAME_NODE2=192.168.0.12

#The virual IP address or hostname used by the cluster
HOSTNAME_VIRTUAL=192.168.0.15

# Indicates if the datasources in JBoss should be failed over.
# Useful to set to false on OCSP-responders, if thay should always run against their local databases.
# Anything other than false means true
DO_DATASOURCE_FAILOVER=true

#Path to file indicating which db node that currently is master
ACTIVENODE_FILE=/tmp/activeNode.txt

