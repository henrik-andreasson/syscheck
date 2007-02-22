#!/bin/sh
# File containing message resources and help function.
# Help resources are defined by subsystem that is checked
# IMPORTANT, This file might be Very sensitive and contain PIN codes and passwords.
# Make only readable by root.

#Script Location
SYSCHECK_HOME=/usr/local/syscheck
export SYSCHECK_HOME
PATH=$SYSCHECK_HOME:$PATH

# use the printlog function
. $SYSCHECK_HOME/lib/printlogmess.sh

# select you lang (choose from files in lang/)
SYSCHECK_LANG=english

# source the specified lang
. ${SYSCHECK_HOME}/lang/syscheck.${SYSCHECK_LANG}

# System name is name of the overall system that is supervised.
SYSTEMNAME=PKI

#Depending if the scripts is running as a cluster or standalone
#might different levels with different errorcodes be reported.
#Comment and uncomment the levels you want to change


#EJBCA RESOURCES
#Hostname to check, default (localhost)
EJBCA_HOSTNAME=localhost

#CRL CHECK RESOURCES
#CRL Fetch URL
CRLFETCH_URL=TODO

# Variable indication the maximum age of the CRL i hours.
HOURTHRESHOLD=24

#FIREWALL CHECK RESOURCES
#IPTABLES_BIN=/usr/sbin/iptables
IPTABLES_BIN=/sbin/iptables

#Rules to check that it exists.
IPTABLES_RULE1="DROP       all  --  anywhere             anywhere            state INVALID"

#CLUSTER SCRIPT RESOURCES

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

#Path to EJBCA
EJBCA_HOME=/usr/local/ejbca 

#Path to mysql binary
MYSQL_BIN=/usr/local/mysql/bin/mysql

#Path to mysqldump binary
MYSQLDUMP_BIN=/usr/local/mysql/bin/mysqldump

#Password for Mysql root
MYSQLROOT_PASSWORD="foo123"

#Path to active jboss config
JBOSS_HOME=/usr/local/jboss

#Path to file indicating which db node that currently is master
ACTIVENODE_FILE=/tmp/activeNode.txt

#Application server database user and password
DB_USER=ejbca
DB_PASSWORD="foo123"

#Database replication user and password 
DBREP_USER=ejbcarep
DBREP_PASSWORD="foo123"

#Username used for no-passphrase ssh login
SSH_USER=jboss

# Backup resources
BACKUPFILE=/var/backup/ejbcabackup
BACKUPFILE_NFAST=/var/backup/nfastbackup

#ACTIVATE CA RESOURCES
#List indicating CAs to activate, should contain a list of caname and PIN separated by space.  
CANAME[0]="test" 
CAPIN[0]="1903"
#CANAME[1]="test2"
#CAPIN[1]="1023"



