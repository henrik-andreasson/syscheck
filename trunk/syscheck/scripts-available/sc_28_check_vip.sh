#!/bin/sh 

# To use this script you have to configure ip-addresses, netmask and interface in $SYSCHECK_HOME/resources.sh.
# If you want this script to be run by cron you have to generate ssh keys with no password and add the id_rsa.pub to .ssh/authorized_keys on both nodes.

# Set default home if not already set.
SYSCHECK_HOME=${SYSCHECK_HOME:-"/usr/local/syscheck"}

## Import common definitions ##
. $SYSCHECK_HOME/resources.sh

SCRIPTID=28

getlangfiles $SCRIPTID ;

ERRNO_1=${SCRIPTID}01
ERRNO_2=${SCRIPTID}02
ERRNO_3=${SCRIPTID}03
ERRNO_4=${SCRIPTID}04

# help
if [ "x$1" = "x--help" ] ; then
    echo "$0 $HELP"
    echo "$ERRNO_1/$CHECK_VIP_DESCR_1 - $CHECK_VIP_HELP_1"
    echo "$ERRNO_2/$CHECK_VIP_DESCR_2 - $CHECK_VIP_HELP_2"
    echo "$ERRNO_3/$CHECK_VIP_DESCR_3 - $CHECK_VIP_HELP_3"
    echo "$ERRNO_4/$CHECK_VIP_DESCR_4 - $CHECK_VIP_HELP_4"
    exit
elif [ "x$1" = "x-s" -o  "x$1" = "x--screen"  ] ; then
    PRINTTOSCREEN=1
fi

CHECK_VIP_NODE1=`ssh ${SSH_USER}@${HOSTNAME_NODE1} ip addr list | grep $HOSTNAME_VIRTUAL | awk '{print $2}' | cut -d "/" -f1`
CHECK_VIP_NODE2=`ssh ${SSH_USER}@${HOSTNAME_NODE2} ip addr list | grep $HOSTNAME_VIRTUAL | awk '{print $2}' | cut -d "/" -f1`

if [ ! -z "$CHECK_VIP_NODE1" -a ! -z "$CHECK_VIP_NODE2" ] ; then
	printlogmess $ERROR $ERRNO_3 "$CHECK_VIP_DESCR_3"
elif [ ! -z $CHECK_VIP_NODE1 ] ; then
	printlogmess $INFO $ERRNO_1 "$CHECK_VIP_DESCR_1"
elif [ ! -z $CHECK_VIP_NODE2 ] ; then
	printlogmess $INFO $ERRNO_2 "$CHECK_VIP_DESCR_2"
fi

if [ -z "$CHECK_VIP_NODE1" -a -z "$CHECK_VIP_NODE2" ] ; then
	printlogmess $ERROR $ERRNO_4 "$CHECK_VIP_DESCR_4"
fi
