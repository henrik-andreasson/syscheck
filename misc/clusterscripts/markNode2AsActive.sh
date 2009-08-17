#!/bin/sh



#Script that marks the primary node as active by setting the contents
#in the /tmp/activeNode.txt flag

# Set default home if not already set.
SYSCHECK_HOME=${SYSCHECK_HOME:-"/usr/local/syscheck"}

## Import common definitions ##
. $SYSCHECK_HOME/resources.sh

rm $ACTIVENODE_FILE

echo "Node2" > $ACTIVENODE_FILE

