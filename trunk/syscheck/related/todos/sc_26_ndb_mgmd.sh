#!/bin/sh 
procname=/usr/local/mysql/libexec/ndb_mgmd
status=0

# Set default home if not already set.
SYSCHECK_HOME=${SYSCHECK_HOME:-"/usr/local/syscheck"}

# Import common resources
. $SYSCHECK_HOME/resources.sh

pid=`ps -ef | grep $procname | grep -v grep | awk '{print $2}'` 

if [ "x$pid" = "x" ] ; then
	printlogmess $NDBM_LEVEL_2 $NDBM_ERRNO_2 "$NDBM_DESCR_2"  
else
	printlogmess $NDBM_LEVEL_1 $NDBM_ERRNO_1 "$NDBM_DESCR_1"
fi

