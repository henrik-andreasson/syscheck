#!/bin/bash

# Skript that checks that the firewall haven't been turned off.

# Set default home if not already set.
SYSCHECK_HOME=${SYSCHECK_HOME:-"/usr/local/syscheck"}

# Import common resources
. $SYSCHECK_HOME/resources.sh


#Check that the primary node is active 
if grep -q "Node1" $ACTIVENODE_FILE 
then
      printlogmess $CLU_LEVEL_1 $CLU_ERRNO_1 "$CLU_DESCR_1"  
else
      printlogmess $CLU_LEVEL_2 $CLU_ERRNO_2 "$CLU_DESCR_2"
fi

scp -q $SSH_USER@$HOSTNAME_NODE1:/usr/local/jboss/server/default/deploy/ejbca-ds.xml /tmp/node1EjbcaDS.xml
diff -s /tmp/node1EjbcaDS.xml /usr/local/jboss/server/default/deploy/ejbca-ds.xml > /tmp/diffres.txt

if grep -q "are identical" /tmp/diffres.txt
then
      printlogmess $CLU_LEVEL_3 $CLU_ERRNO_3 "$CLU_DESCR_3"
else
      printlogmess $CLU_LEVEL_4 $CLU_ERRNO_4 "$CLU_DESCR_4"
fi

rm /tmp/node1EjbcaDS.xml
rm /tmp/diffres.txt
 

