#!/bin/bash 

# To use this script you have to configure ip-addresses, netmask and interface in $SYSCHECK_HOME/config/syscheck-scripts.conf.
# If you want this script to be run by cron you have to generate ssh keys with no password and add the id_rsa.pub to .ssh/authorized_keys on both nodes.

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

# uniq ID of script (please use in the name of this file also for convinice for finding next availavle number)
SCRIPTID=28

# Index is used to uniquely identify one test done by the script (a harddrive, crl or cert)
SCRIPTINDEX=00


getlangfiles $SCRIPTID
getconfig $SCRIPTID

ERRNO_1=01
ERRNO_2=02
ERRNO_3=03
ERRNO_4=04

# help
if [ "x$1" = "x--help" ] ; then
    echo "$0 $HELP"
    echo "$ERRNO_1/$DESCR_1 - $HELP_1"
    echo "$ERRNO_2/$DESCR_2 - $HELP_2"
    echo "$ERRNO_3/$DESCR_3 - $HELP_3"
    echo "$ERRNO_4/$DESCR_4 - $HELP_4"
    exit
elif [ "x$1" = "x-s" -o  "x$1" = "x--screen"  ] ; then
    PRINTTOSCREEN=1
fi

SCRIPTINDEX=$(addOneToIndex $SCRIPTINDEX)
CHECK_VIP_NODE1=`${SYSCHECK_HOME}/related-enabled/915_remote_command_via_ssh.sh ${HOSTNAME_NODE1} "${IFCONFIG} | grep ${HOSTNAME_VIRTUAL}" ${SSH_USER} ${SSH_KEY} | awk '{print $2}' | sed 's/addr\://g'`
CHECK_VIP_NODE2=`${SYSCHECK_HOME}/related-enabled/915_remote_command_via_ssh.sh ${HOSTNAME_NODE2} "${IFCONFIG} | grep ${HOSTNAME_VIRTUAL}" ${SSH_USER} ${SSH_KEY} | awk '{print $2}' | sed 's/addr\://g'`

if [ "$CHECK_VIP_NODE1" = "${HOSTNAME_VIRTUAL}" -a "$CHECK_VIP_NODE2" = "${HOSTNAME_VIRTUAL}" ] ; then
	printlogmess ${SCRIPTID} ${SCRIPTINDEX}   $ERROR $ERRNO_3 "$DESCR_3"
elif [ "$CHECK_VIP_NODE1" = "${HOSTNAME_VIRTUAL}" ] ; then
	printlogmess ${SCRIPTID} ${SCRIPTINDEX}   $INFO $ERRNO_1 "$DESCR_1"
elif [ "$CHECK_VIP_NODE2" = "${HOSTNAME_VIRTUAL}" ] ; then
	printlogmess ${SCRIPTID} ${SCRIPTINDEX}   $INFO $ERRNO_2 "$DESCR_2"
fi

SCRIPTINDEX=$(addOneToIndex $SCRIPTINDEX)
if [ ! "$NODE1" = "${HOSTNAME_VIRTUAL}" -a ! "$CHECK_VIP_NODE2" = "${HOSTNAME_VIRTUAL}" ] ; then
	printlogmess ${SCRIPTID} ${SCRIPTINDEX}   $ERROR $ERRNO_4 "$DESCR_4"
fi
