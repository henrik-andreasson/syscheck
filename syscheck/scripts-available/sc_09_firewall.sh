#!/bin/bash

# Skript that checks that the firewall haven't been turned off.

# Set default home if not already set.
SYSCHECK_HOME=${SYSCHECK_HOME:-"/usr/local/syscheck"}

# Import common resources
. $SYSCHECK_HOME/resources.sh

SCRIPTID=09

FWALL_ERRNO_1=${SCRIPTID}01
FWALL_ERRNO_2=${SCRIPTID}02
FWALL_ERRNO_3=${SCRIPTID}03

# help
if [ "x$1" = "x--help" ] ; then
    echo "$0 $FWALL_HELP"
    echo "$FWALL_ERRNO_1/$FWALL_DESCR_1 - $FWALL_HELP_1"
    echo "$FWALL_ERRNO_2/$FWALL_DESCR_2 - $FWALL_HELP_2"
    echo "$FWALL_ERRNO_3/$FWALL_DESCR_3 - $FWALL_HELP_3"
    exit
elif [ "x$1" = "x-s" -o  "x$1" = "x--screen"  ] ; then
    PRINTTOSCREEN=1
fi

IPTABLES_TMP_FILE="/tmp/iptables.out"

$IPTABLES_BIN -L > $IPTABLES_TMP_FILE

FIREWALLFAILED="0"

#Check that no chain have policy accept.
if grep -q "(policy ACCEPT)" $IPTABLES_TMP_FILE
then
      printlogmess $ERROR $FWALL_ERRNO_1 "$FWALL_DESCR_1"  
      FIREWALLFAILED="1"
else
  #Check that the ruleset seems ok.
  if ! grep -q "$IPTABLES_RULE1" $IPTABLES_TMP_FILE
  then
      printlogmess $ERROR $FWALL_ERRNO_2 "$FWALL_DESCR_2"
      FIREWALLFAILED="1"
  fi
fi

if [ "$FIREWALLFAILED" -ne "1" ]
then 
      printlogmess $INFO $FWALL_ERRNO_3 "$FWALL_DESCR_3"
fi

rm $IPTABLES_TMP_FILE

