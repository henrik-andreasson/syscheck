#!/bin/bash

# Skript that checks that the primary database node is active and that both JBoss works against the same database.

# Set default home if not already set.
SYSCHECK_HOME=${SYSCHECK_HOME:-"/usr/local/syscheck"}

## Import common definitions ##
. $SYSCHECK_HOME/resources.sh

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
      printlogmess $INFO $CLU_ERRNO_1 "$CLU_DESCR_1"  
else
      printlogmess $ERROR $CLU_ERRNO_2 "$CLU_DESCR_2"
fi

# TODO HARDCODED PATHs
scp -o ConnectTimeout=10 -q $SSH_USER@$HOSTNAME_NODE1:/usr/local/jboss/server/default/deploy/ejbca-ds.xml /tmp/node1EjbcaDS.xml
diff -s /tmp/node1EjbcaDS.xml /usr/local/jboss/server/default/deploy/ejbca-ds.xml > /tmp/diffres.txt

if grep -q "are identical" /tmp/diffres.txt
then
      printlogmess $INFO $CLU_ERRNO_3 "$CLU_DESCR_3"
else
      printlogmess $ERROR $CLU_ERRNO_4 "$CLU_DESCR_4"
fi

rm /tmp/node1EjbcaDS.xml
rm /tmp/diffres.txt
 

