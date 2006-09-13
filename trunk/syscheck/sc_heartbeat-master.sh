#!/bin/sh 

# Set default home if not already set.
SYSCHECK_HOME=${SYSCHECK_HOME:-"/usr/local/syscheck"}

# Import common resources
. $SYSCHECK_HOME/resources.sh

ip addr list eth0 > /tmp/ipaddrlist.txt

#Check that no chain have policy accept.
if grep -q "$HOSTNAME_VIRTUAL" /tmp/ipaddrlist.txt
then
      printlogmess $HAMAS_LEVEL_1 $HAMAS_ERRNO_1 "$HAMAS_DESCR_1"
else
      printlogmess $HAMAS_LEVEL_2 $HAMAS_ERRNO_2 "$HAMAS_DESCR_2"
fi

rm /tmp/ipaddrlist.txt
