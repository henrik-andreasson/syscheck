#!/bin/bash

# Skript that checks that the firewall haven't been turned off.

# Set default home if not already set.
SYSCHECK_HOME=${SYSCHECK_HOME:-"/usr/local/syscheck"}

## Import common definitions ##
. $SYSCHECK_HOME/resources.sh

## Local definitions ##

SCRIPTID=09

getlangfiles $SCRIPTID
getconfig $SCRIPTID

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

rule1check=`grep "$IPTABLES_RULE1" $IPTABLES_TMP_FILE`
if [ "x$rule1check" = "x" ] ; then
      FIREWALLFAILED=1
fi

# 
rule2check=`grep "$IPTABLES_RULE2" $IPTABLES_TMP_FILE`
if [ "x$rule2check" != "x" ] ; then
      FIREWALLFAILED=1
fi

if [ "$FIREWALLFAILED" = 1 ] ; then 
	printlogmess $ERROR $FWALL_ERRNO_1 "$FWALL_DESCR_1"
else
	printlogmess $INFO $FWALL_ERRNO_3 "$FWALL_DESCR_3"
fi

rm $IPTABLES_TMP_FILE

