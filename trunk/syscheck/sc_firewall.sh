#!/bin/bash

# Skript that checks that the firewall haven't been turned off.

# Set default home if not already set.
SYSCHECK_HOME=${SYSCHECK_HOME:-"/usr/local/syscheck"}

# Import common resources
. $SYSCHECK_HOME/resources.sh

$IPTABLES_BIN -L > /tmp/iptables.out

FIREWALLFAILED="0"

#Check that no chain have policy accept.
if grep -q "(policy ACCEPT)" /tmp/iptables.out 
then
      printlogmess $FWALL_LEVEL_1 $FWALL_ERRNO_1 "$FWALL_DESCR_1"  
      FIREWALLFAILED="1"
else
  #Check that the ruleset seems ok.
  if ! grep -q "$IPTABLES_RULE1" /tmp/iptables.out
  then
      printlogmess $FWALL_LEVEL_2 $FWALL_ERRNO_2 "$FWALL_DESCR_2"
      FIREWALLFAILED="1"
  fi
fi

if [ "$FIREWALLFAILED" -ne "1" ]
then 
      printlogmess $FWALL_LEVEL_3 $FWALL_ERRNO_3 "$FWALL_DESCR_3"
fi

rm /tmp/iptables.out

