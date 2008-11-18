#!/bin/sh

# Script will bring VIP online and make DefaultGateway aware of ARP change.


# Set default home if not already set.
SYSCHECK_HOME=${SYSCHECK_HOME:-"/usr/local/syscheck"}


## Import common definitions ##
. $SYSCHECK_HOME/resources.sh

# uniq ID of script (please use in the name of this file also for convinice for finding next availavle number)
SCRIPTID=911

getlangfiles $SCRIPTID 
getconfig $SCRIPTID 

ERRNO_1="${SCRIPTID}1"
ERRNO_2="${SCRIPTID}2"
ERRNO_3="${SCRIPTID}3"



PRINTTOSCREEN=
if [ "x$1" = "x-h" -o "x$1" = "x--help" ] ; then
	echo "$DEACTVIP_HELP"
	echo "$ERRNO_1/$DEACTVIP_DESCR_1 - $DEACTVIP_HELP_1"
	echo "$ERRNO_2/$DEACTVIP_DESCR_2 - $DEACTVIP_HELP_2"
	echo "$ERRNO_3/$DEACTVIP_DESCR_3 - $DEACTVIP_HELP_3"
	echo "${SCREEN_HELP}"
	exit
elif [ "x$1" = "x-s" -o  "x$1" = "x--screen" -o \
    "x$2" = "x-s" -o  "x$2" = "x--screen"   ] ; then
    PRINTTOSCREEN=1
    shift
fi 


$IFCONFIG ${IF_VIRTUAL}:0 down
#$IP address del $HOSTNAME_VIRTUAL/$NETMASK_VIRTUAL dev $IF_VIRTUAL
if [ $? -eq 0 ] ; then 
    printlogmess $INFO $ERRNO_1 "$DEACTVIP_DESCR_1" "$?" 
else
    printlogmess $ERROR $ERRNO_3 "$DEACTVIP_DESCR_3" "$?" 
fi

#ifconfig $IF_VIRTUAL del $HOSTNAME_VIRTUAL
