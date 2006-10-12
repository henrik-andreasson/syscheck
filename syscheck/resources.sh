#!/bin/sh
# File containing message resources and help function.
# Help resources are defined by subsystem that is checked
# IMPORTANT, This file might be Very sensitive and contain PIN codes and passwords.
# Make only readable by root.

#Script Location
SYSCHECK_HOME=/usr/local/syscheck
export SYSCHECK_HOME
PATH=$SYSCHECK_HOME:$PATH

# System name is name of the overall system that is supervised.
SYSTEMNAME=PKI

#Depending if the scripts is running as a cluster or standalone
#might different levels with different errorcodes be reported.
#Comment and uncomment the levels you want to change

#DISKUSAGE RESOURCES
DU_DESCR_1="FAIL - Diskusage exceeded (%s is %s percent used: Limit is %s percent)"
DU_ERRNO_1="0101"
DU_LEVEL_1="E"
#DU_ERRNO_1="0102"
#DU_LEVEL_1="W"
DU_DESCR_2="OK - Diskusage ok (%s is %s percent used: Limit is %s percent)"
DU_ERRNO_2="0103"
DU_LEVEL_2="I"

#EJBCA RESOURCES
#Hostname to check, default (localhost)
EJBCA_HOSTNAME=localhost

ECA_DESCR_1="OK - EJBCA : %s"
ECA_ERRNO_1="0201"
ECA_LEVEL_1="I"
ECA_DESCR_2="FAIL - EJBCA : %s"
ECA_ERRNO_2="0202"
ECA_LEVEL_2="E"
#ECA_ERRNO_2="0203"
#ECA_LEVEL_2="W"
ECA_DESCR_3="FAIL - EJBCA : Application Server is unavailable"
ECA_ERRNO_3="0304"
ECA_LEVEL_3="E"
#ECA_ERRNO_3="0305"
#ECA_LEVEL_3="W"

#MEMORY RESOURCES
MEM_DESCR_1="FAIL - Memory limit exceded (Memory is %s KB used: Limit is %s KB)"
MEM_ERRNO_1="0301"
MEM_LEVEL_1="E"
#MEM_ERRNO_1="0302"
#MEM_LEVEL_1="W"
MEM_DESCR_2="OK - Memory limit ok (Memory is %s KB used: Limit is %s KB)"
MEM_ERRNO_2="0303"
MEM_LEVEL_2="I"
MEM_DESCR_3="FAIL - Swap limit exceded (Swap is %s KB used: Limit is %s KB)"
MEM_ERRNO_3="0304"
MEM_LEVEL_3="E"
#MEM_ERRNO_3="0305"
#MEM_LEVEL_3="W"
MEM_DESCR_4="OK - Swap limit ok (Swap is %s KB used: Limit is %s KB)"
MEM_ERRNO_4="0306"
MEM_LEVEL_4="I"


#PCSC LIST READERS RESOURCES
# number of expected pcsc-readers, any other number will send an error message !
PCSC_NUMBER_OF_READERS=1
PCL_DESCR_1="OK - Right number of attatched pcsc-readers (%s)"
PCL_ERRNO_1="0401"
PCL_LEVEL_1="I"
PCL_DESCR_2="FAIL - Wrong number of attached pcsc-readers (%s)"
PCL_ERRNO_2="0402"
PCL_LEVEL_2="E"
#PCL_ERRNO_2="0403"
#PCL_LEVEL_2="W"

#PCSC RESOURCES
PCSCD_DESCR_1="OK - pcscd is running"
PCSCD_ERRNO_1="0501"
PCSCD_LEVEL_1="I"
PCSCD_DESCR_2="FAIL - pcscd is NOT running"
PCSCD_ERRNO_2="0502"
PCSCD_LEVEL_2="E"
#PCSCD_ERRNO_2="0503"
#PCSCD_LEVEL_2="W"

#RAID CHECK RESOURCES
RAID_DESCR_1="OK - Disc Array is OK %s"
RAID_ERRNO_1="0601"
RAID_LEVEL_1="I"
RAID_DESCR_2="FAIL - Disc Array is not OK %s"
RAID_ERRNO_2="0602"
RAID_LEVEL_2="E"
#RAID_ERRNO_2="0603"
#RAID_LEVEL_2="W"

#SYSLOG RESOURCES
SLOG_DESCR_1="FAIL -  heartbeat loggmessage did not come throu syslog"
SLOG_ERRNO_1="0701"
SLOG_LEVEL_1="E"
#SLOG_ERRNO_1="0702"
#SLOG_LEVEL_1="W"
SLOG_DESCR_2="FAIL - no pid file found and syslog not found in ps-table"
SLOG_ERRNO_2="0703"
SLOG_LEVEL_2="E"
#SLOG_ERRNO_2="0704"
#SLOG_LEVEL_2="W"
SLOG_DESCR_3="FAIL - syslog is not running"
SLOG_ERRNO_3="0705"
SLOG_LEVEL_3="E"
#SLOG_ERRNO_3="0706"
#SLOG_LEVEL_3="W"
SLOG_DESCR_4="OK - Syslog is running and delivers messages"
SLOG_ERRNO_4="0707"
SLOG_LEVEL_4="I"

#CRL CHECK RESOURCES
#CRL Fetch URL
CRLFETCH_URL=TODO

# Variable indication the maximum age of the CRL i hours.
HOURTHRESHOLD=24

CRL_DESCR_1="FAIL -  CRL %s creation have failed"
CRL_ERRNO_1="0801"
CRL_LEVEL_1="E"
CRL_DESCR_2="OK -  CRL %s is updated"
CRL_ERRNO_2="0802"
CRL_LEVEL_2="I"

#FIREWALL CHECK RESOURCES
IPTABLES_BIN=/usr/sbin/iptables
#Rules to check that it exists.
IPTABLES_RULE1="DROP       all  --  anywhere             anywhere            state INVALID"

FWALL_DESCR_1="FAIL -  Firewall seems to be turned off."
FWALL_ERRNO_1="0901"
FWALL_LEVEL_1="E"
FWALL_DESCR_2="FAIL -  Firewall doesn't seem to have the correct ruleset configured."
FWALL_ERRNO_2="0902"
FWALL_LEVEL_2="E"
FWALL_DESCR_3="OK - Firewall is up and configured properly"
FWALL_ERRNO_3="0903"
FWALL_LEVEL_3="I"

#CLUSTER SCRIPT RESOURCES

#Path do clusterscript directory
CLUSTERSCRIPT_HOME=$SYSCHECK_HOME/clusterscripts

#IP address or hostname to primary and secondary cluster nodes.
HOSTNAME_NODE1=192.168.0.11
HOSTNAME_NODE2=192.168.0.12

#The virual IP address or hostname used by the cluster
HOSTNAME_VIRTUAL=192.168.0.15

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

CLU_DESCR_1="OK - Primary Node is Master Database."
CLU_ERRNO_1="1001"
CLU_LEVEL_1="I"
CLU_DESCR_2="FAIL - Secondary Node is Master Database, schedule a resync!"
CLU_ERRNO_2="1002"
CLU_LEVEL_2="W"
CLU_DESCR_3="OK - JBoss Database settings match between clusters."
CLU_ERRNO_3="1003"
CLU_LEVEL_3="I"
CLU_DESCR_4="FAIL - SEVERE JBoss Db settings doesn't match, possible dataloss."
CLU_ERRNO_4="1004"
CLU_LEVEL_4="E"



#HEARTBEAT RESOURCES
HA_DESCR_1="OK - heartbeat is running"
HA_ERRNO_1="1101"
HA_LEVEL_1="I"
HA_DESCR_2="FAIL - heartbeat is NOT running"
HA_ERRNO_2="1102"
HA_LEVEL_2="W"

#HEARTBEAT MASTER RESOURCES
HAMAS_DESCR_1="OK - heartbeat is running on the master node."
HAMAS_ERRNO_1="1301"
HAMAS_LEVEL_1="I"
HAMAS_DESCR_2="FAIL - heartbeat is seem to have been failed over to slave."
HAMAS_ERRNO_2="1302"
HAMAS_LEVEL_2="W"


#MYSQL RESOURCES
MYSQL_DESCR_1="OK - mysql is running"
MYSQL_ERRNO_1="1201"
MYSQL_LEVEL_1="I"
MYSQL_DESCR_2="FAIL - mysql is NOT running"
MYSQL_ERRNO_2="1202"
MYSQL_LEVEL_2="E"
#MYSQL_ERRNO_2="1203"
#MYSQL_LEVEL_2="W"

#MYSQL BACKUP RESOURCES
#Name and location of backupfiles (a date ending and .sql will be appended)
BACKUPFILE=/var/backup/ejbcabackup

BAK_DESCR_1="OK - Database backup of EJBCA was successful"
BAK_ERRNO_1="1401"
BAK_LEVEL_1="I"
BAK_DESCR_2="FAIL - Database backup of EJBCA was unsuccessful"
BAK_ERRNO_2="1402"
BAK_LEVEL_2="E"

#NTP RESOURCES
NTP_DESCR_1="OK - XNTPD is up running"
NTP_ERRNO_1="1501"
NTP_LEVEL_1="I"
NTP_DESCR_2="FAIL -  XNTPD is NOT running."
NTP_ERRNO_2="1502"
NTP_LEVEL_2="E"
NTP_DESCR_3="OK - XNTPD can synchronize to servers"
NTP_ERRNO_3="1503"
NTP_LEVEL_3="I"
NTP_DESCR_4="FAIL -  XNTPD can NOT synchronize to servers."
NTP_ERRNO_4="1504"
NTP_LEVEL_4="E"

#TSA RESOURCES
#Hostname to check, default (localhost)
TSA_HOSTNAME=localhost

TSA_DESCR_1="OK - TSA : %s"
TSA_ERRNO_1="1601"
TSA_LEVEL_1="I"
TSA_DESCR_2="FAIL - TSA : %s"
TSA_ERRNO_2="1602"
TSA_LEVEL_2="E"
#TSA_ERRNO_2="1603"
#TSA_LEVEL_2="W"
TSA_DESCR_3="FAIL - TSA : Application Server is unavailable"
TSA_ERRNO_3="1604"
TSA_LEVEL_3="E"
#TSA_ERRNO_3="1605"
#TSA_LEVEL_3="W"

APA_DESCR_1="OK - Apache webserver is running"
APA_ERRNO_1="1701"
APA_LEVEL_1="I"
APA_DESCR_2="FAIL - Apache webserver is not running"
#APA_ERRNO_2="1702"
#APA_LEVEL_2="E"
APA_ERRNO_2="1703"
APA_LEVEL_2="W"


LDA_DESCR_1="OK - LDAP Directory is running"
LDA_ERRNO_1="1801"
LDA_LEVEL_1="I"
LDA_DESCR_2="FAIL - LDAP Directory is not running"
LDA_ERRNO_2="1802"
LDA_LEVEL_2="E"


#OCSP RESOURCES
#Hostname to check, default (localhost)
OCSP_HOSTNAME=localhost

OCP_DESCR_1="OK - OCSP : %s"
OCP_ERRNO_1="1901"
OCP_LEVEL_1="I"
OCP_DESCR_2="FAIL - OCSP : %s"
#OCP_ERRNO_2="1902"
#OCP_LEVEL_2="E"
OCP_ERRNO_2="1903"
OCP_LEVEL_2="W"
OCP_DESCR_3="FAIL - OCSP : Application Server is unavailable"
#OCP_ERRNO_3="1904"
#OCP_LEVEL_3="E"
ECA_ERRNO_3="0305"
ECA_LEVEL_3="W"

#MYSQL Cluster NDBD Resources
NDBD_DESCR_1="OK - ndbd is running"
NDBD_ERRNO_1="2501"
NDBD_LEVEL_1="I"
NDBD_DESCR_2="FAIL - ndbd is NOT running"
#NDBD_ERRNO_2="2502"
#NDBD_LEVEL_2="E"
NDBD_ERRNO_2="2503"
NDBD_LEVEL_2="W"


#MYSQL Cluster NDB Manager Resources
NDBM_DESCR_1="OK - ndb_mgmd is running"
NDBM_ERRNO_1="2601"
NDBM_LEVEL_1="I"
NDBM_DESCR_2="FAIL - ndb_mgmd is NOT running"
#NDBM_ERRNO_2="2602"
#NDBM_LEVEL_2="E"
NDBM_ERRNO_2="2603"
NDBM_LEVEL_2="W"

#DSS Resources
SIGNSERVER_HOME=/usr/local/signserver

DSS_DESCR_1="OK - Document SignServer is active"
DSS_ERRNO_1="2701"
DSS_LEVEL_1="I"
DSS_DESCR_2="FAIL - Document SignServer is NOT active"
#DSS_ERRNO_2="2702"
#DSS_LEVEL_2="E"
DSS_ERRNO_2="2703"
DSS_LEVEL_2="W"

#ACTIVATE CA RESOURCES
#List indicating CAs to activate, should contain a list of caname and PIN separated by space.  
CANAME[0]="test" 
CAPIN[0]="1903"
#CANAME[1]="test2"
#CAPIN[1]="1023"


# ex: printlogmess $SLOG_LEVEL_1 $SLOG_ERRNO_1 "$SLOG_DESCR_1"
printlogmess(){
	LEVEL=$1
	ERRNO=$2
	DESCR=$3
	shift 3	
	ARG1=$1
	ARG2=$2
	ARG3=$3
	ARG4=$4
	ARG5=$5
	ARG6=$6
	ARG7=$7
	ARG8=$8
	ARG9=$9

	DESCR_W_ARGS=`/usr/local/syscheck/printf.pl "$DESCR" "$ARG1" "$ARG2" "$ARG3" "$ARG4" "$ARG5" "$ARG6" "$ARG7" "$ARG8" "$ARG9"  `

	DATE=`date +"%Y%m%d %H:%M:%S"`
	HOST=`hostname `

	MESSAGE0="${HOST}: ${DESCR_W_ARGS}"
	MESSAGE=${MESSAGE0:0:79}

	if [ "x${LEVEL}" = "xI" ] ;then
		SYSLOGLEVEL="info"
	elif [ "x${LEVEL}" = "xW" ] ;then
		SYSLOGLEVEL="warning"
	elif [ "x${LEVEL}" = "xE" ] ;then
                SYSLOGLEVEL="err"
	else
		echo "wrong type of LEVEL (${LEVEL})"
		exit;	
	fi
	
	if [ "x$PRINTTOSCREEN" = "x" ] ; then
            logger -p local3.${SYSLOGLEVEL} "${LEVEL}-${ERRNO}-${SYSTEMNAME} ${DATE} ${MESSAGE}"
        else
            echo "${LEVEL}-${ERRNO}-${SYSTEMNAME} ${DATE} ${MESSAGE}"      
        fi  	 

}

