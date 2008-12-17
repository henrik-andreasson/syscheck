#!/bin/sh 

# To use this script you have to configure ip-addresses, netmask and interface in $SYSCHECK_HOME/resources.sh.
# If you want this script to be run by cron you have to generate ssh keys with no password and add the id_rsa.pub to .ssh/authorized_keys on both nodes.

# Set default home if not already set.
SYSCHECK_HOME=${SYSCHECK_HOME:-"/usr/local/syscheck"}

## Import common definitions ##
. $SYSCHECK_HOME/resources.sh

SCRIPTID=28

getlangfiles $SCRIPTID
getconfig $SCRIPTID

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

CHECK_VIP_NODE1=`${SYSCHECK_HOME}/related-enabled/915_remote_command_via_ssh.sh ${HOSTNAME_NODE1} "ifconfig | grep ${HOSTNAME_VIRTUAL}" ${SSH_USER} | awk '{print $2}' | sed 's/addr\://g'`
CHECK_VIP_NODE2=`${SYSCHECK_HOME}/related-enabled/915_remote_command_via_ssh.sh ${HOSTNAME_NODE2} "ifconfig | grep ${HOSTNAME_VIRTUAL}" ${SSH_USER} | awk '{print $2}' | sed 's/addr\://g'`

if [ "$CHECK_VIP_NODE1" = "${HOSTNAME_VIRTUAL}" -a "$CHECK_VIP_NODE2" = "${HOSTNAME_VIRTUAL}" ] ; then
	printlogmess $ERROR $ERRNO_3 "$CHECK_VIP_DESCR_3"
elif [ "$CHECK_VIP_NODE1" = "${HOSTNAME_VIRTUAL}" ] ; then
	printlogmess $INFO $ERRNO_1 "$CHECK_VIP_DESCR_1"
elif [ "$CHECK_VIP_NODE2" = "${HOSTNAME_VIRTUAL}" ] ; then
	printlogmess $INFO $ERRNO_2 "$CHECK_VIP_DESCR_2"
fi

if [ ! "$CHECK_VIP_NODE1" = "${HOSTNAME_VIRTUAL}" -a ! "$CHECK_VIP_NODE2" = "${HOSTNAME_VIRTUAL}" ] ; then
	printlogmess $ERROR $ERRNO_4 "$CHECK_VIP_DESCR_4"
fi
