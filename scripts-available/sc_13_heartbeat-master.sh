#!/bin/sh 

# Set default home if not already set.
SYSCHECK_HOME=${SYSCHECK_HOME:-"/usr/local/syscheck"}

## Import common definitions ##
. $SYSCHECK_HOME/resources.sh

SCRIPTID=13

getlangfiles $SCRIPTID
getconfig $SCRIPTID

HAMAS_ERRNO_1=${SCRIPTID}01
HAMAS_ERRNO_2=${SCRIPTID}02
HAMAS_ERRNO_3=${SCRIPTID}03

# help
if [ "x$1" = "x--help" ] ; then
    echo "$0 $HAMAS_HELP"
    echo "$HAMAS_ERRNO_1/$HAMAS_DESCR_1 - $HAMAS_HELP_1"
    echo "$HAMAS_ERRNO_2/$HAMAS_DESCR_2 - $HAMAS_HELP_2"
    exit
elif [ "x$1" = "x-s" -o  "x$1" = "x--screen"  ] ; then
    PRINTTOSCREEN=1
fi


/sbin/ip addr list $HAMAS_INTERFACE  > $HAMAS_IP_ADDR_LIST 2>/dev/null
if [ $? -ne 0 ] ; then
	/sbin/ifconfig $HAMAS_INTERFACE > $HAMAS_IP_ADDR_LIST
fi

#Check that no chain have policy accept.
if grep -q "$HOSTNAME_VIRTUAL" $HAMAS_IP_ADDR_LIST
then
      printlogmess $INFO $HAMAS_ERRNO_1 "$HAMAS_DESCR_1"
else
      printlogmess $ERROR $HAMAS_ERRNO_2 "$HAMAS_DESCR_2"
fi

rm $HAMAS_IP_ADDR_LIST
