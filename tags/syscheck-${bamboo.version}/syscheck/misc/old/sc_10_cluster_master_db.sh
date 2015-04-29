#!/bin/bash

# Skript that checks that the primary database node is active and that both JBoss works against the same database.

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
. $SYSCHECK_HOME/config/syscheck-scripts.conf

SCRIPTID=10

getlangfiles $SCRIPTID
getconfig $SCRIPTID

CLU_ERRNO_1=${SCRIPTID}01
CLU_ERRNO_2=${SCRIPTID}02
CLU_ERRNO_3=${SCRIPTID}03

# help
if [ "x$1" = "x--help" ] ; then
    echo "$0 $CLU_HELP"
    echo "$CLU_ERRNO_1/$CLU_DESCR_1 - $CLU_HELP_1"
    echo "$CLU_ERRNO_2/$CLU_DESCR_2 - $CLU_HELP_2"
    echo "$CLU_ERRNO_3/$CLU_DESCR_3 - $CLU_HELP_3"
    exit
elif [ "x$1" = "x-s" -o  "x$1" = "x--screen"  ] ; then
    PRINTTOSCREEN=1
fi


#Check that the primary node is active 
if grep -q "Node1" $ACTIVENODE_FILE 
then
      printlogmess ${SCRIPTID} ${SCRIPTINDEX}   $INFO $CLU_ERRNO_1 "$CLU_DESCR_1"  
else
      printlogmess ${SCRIPTID} ${SCRIPTINDEX}   $ERROR $CLU_ERRNO_2 "$CLU_DESCR_2"
fi

# TODO HARDCODED PATHs
scp -o ConnectTimeout=10 -q $SSH_USER@$HOSTNAME_NODE1:/usr/local/jboss/server/default/deploy/ejbca-ds.xml /tmp/node1EjbcaDS.xml
diff -s /tmp/node1EjbcaDS.xml /usr/local/jboss/server/default/deploy/ejbca-ds.xml > /tmp/diffres.txt

if grep -q "are identical" /tmp/diffres.txt
then
      printlogmess ${SCRIPTID} ${SCRIPTINDEX}   $INFO $CLU_ERRNO_3 "$CLU_DESCR_3"
else
      printlogmess ${SCRIPTID} ${SCRIPTINDEX}   $ERROR $CLU_ERRNO_4 "$CLU_DESCR_4"
fi

rm /tmp/node1EjbcaDS.xml
rm /tmp/diffres.txt
 

