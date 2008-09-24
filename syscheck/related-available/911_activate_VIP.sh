#!/bin/sh

# Script will bring VIP online and make DefaultGateway aware of ARP change.

# Set default home if not already set.
SYSCHECK_HOME=${SYSCHECK_HOME:-"/usr/local/syscheck"}


## Import common definitions ##
. $SYSCHECK_HOME/resources.sh

# uniq ID of script (please use in the name of this file also for convinice for finding next availavle number)
SCRIPTID=911

getlangfiles $SCRIPTID ;

ERRNO_1="${SCRIPTID}1"
ERRNO_2="${SCRIPTID}2"
ERRNO_3="${SCRIPTID}3"

### config ###

ROUTE=/sbin/route
IP=/sbin/ip
IFCONFIG=/sbin/ifconfig
IP_GATEWAY=`$ROUTE -n | awk '/0.0.0.0/'| awk '{print $2}' |awk '!/0.0.0.0/'` 
PING=/bin/ping


PRINTTOSCREEN=
if [ "x$1" = "x-h" -o "x$1" = "x--help" ] ; then
	echo "$ACTVIP_HELP"
	echo "$ERRNO_1/$ACTVIP_DESCR_1 - $ACTVIP_HELP_1"
	echo "$ERRNO_2/$ACTVIP_DESCR_2 - $ACTVIP_HELP_2"
	echo "$ERRNO_3/$ACTVIP_DESCR_3 - $ACTVIP_HELP_3"
	echo "${SCREEN_HELP}"
	exit
elif [ "x$1" = "x-s" -o  "x$1" = "x--screen" -o \
    "x$2" = "x-s" -o  "x$2" = "x--screen"   ] ; then
    PRINTTOSCREEN=1
    shift
fi 

$IFCONFIG ${IF_VIRTUAL}:0 inet ${HOSTNAME_VIRTUAL} netmask ${NETMASK_VIRTUAL} up
#$IP address add $HOSTNAME_VIRTUAL/$NETMASK_VIRTUAL dev $IF_VIRTUAL
#$IFCONFIG $IF_VIRTUAL add $HOSTNAME_VIRTUAL netmask $HOSTNAME_VIRTUAL
if [ $? -eq 0 ] ; then 
    printlogmess $INFO $ERRNO_1 "$ACTVIP_DESCR_1" "$?" 
else
    printlogmess $ERROR $ERRNO_3 "$ACTVIP_DESCR_3" "$?" 
fi


$PING -I $HOSTNAME_VIRTUAL -c 4 $IP_GATEWAY 
if [ $? -eq 0 ] ; then 
    printlogmess $ERROR $ERRNO_1 "$ACTVIP_DESCR_1" "$?" 
else
    printlogmess $ERROR $ERRNO_3 "$ACTVIP_DESCR_3" "$?" 
fi

# Test tools
#ifconfig eth0 | awk '/inet addr/' | awk '{print $2}' | sed 's/addr://g'
# route -n  | awk '/0.0.0.0/'| awk '{print $2}' |awk '!/0.0.0.0/'
