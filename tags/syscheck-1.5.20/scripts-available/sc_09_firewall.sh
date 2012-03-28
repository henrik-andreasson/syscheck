#!/bin/bash

# Skript that checks that the firewall haven't been turned off.

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

$IPTABLES_BIN -L -n> $IPTABLES_TMP_FILE

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

