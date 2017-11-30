#!/bin/bash

#Scripts that creates replication privilegdes for the slave db to the master.

# Set SYSCHECK_HOME if not already set.

# 1. First check if SYSCHECK_HOME is set then use that
if [ "x${SYSCHECK_HOME}" = "x" ] ; then
# 2. Check if /etc/syscheck.conf exists then source that (put SYSCHECK_HOME=/path/to/syscheck in ther)
    if [ -e /etc/syscheck.conf ] ; then 
	source /etc/syscheck.conf 
    else
# 3. last resort use default path
	SYSCHECK_HOME="/opt/syscheck"
    fi
fi

if [ ! -f ${SYSCHECK_HOME}/syscheck.sh ] ; then echo "$0: Can't find syscheck.sh in SYSCHECK_HOME ($SYSCHECK_HOME)" ;exit ; fi


# uniq ID of script (please use in the name of this file also for convinice for finding next availavle number)
SCRIPTID=813

# Index is used to uniquely identify one test done by the script (a harddrive, crl or cert)
SCRIPTINDEX=00


## Import common definitions ##
. $SYSCHECK_HOME/config/database-replication.conf

$MYSQL_BIN mysql -u root --password="$MYSQLROOT_PASSWORD" 

