#!/bin/bash 

# Set SYSCHECK_HOME if not already set.

# 1. First check if SYSCHECK_HOME is set then use that
if [ "x${SYSCHECK_HOME}" = "x" ] ; then
# 2. Check if /etc/syscheck.conf exists then source that (put SYSCHECK_HOME=/path/to/syscheck in ther)
    if [ -e /etc/syscheck.conf ] ; then 
	source /etc/syscheck.conf 
    else
# 3. last resort use default path
	SYSCHECK_HOME="/opt/syscheck"
    fi
fi

if [ ! -f ${SYSCHECK_HOME}/syscheck.sh ] ; then echo "$0: Can't find syscheck.sh in SYSCHECK_HOME ($SYSCHECK_HOME)" ;exit ; fi




## Import common definitions ##
. $SYSCHECK_HOME/config/syscheck-scripts.conf

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
      printlogmess ${SCRIPTID} ${SCRIPTINDEX}   $INFO $HAMAS_ERRNO_1 "$HAMAS_DESCR_1"
else
      printlogmess ${SCRIPTID} ${SCRIPTINDEX}   $ERROR $HAMAS_ERRNO_2 "$HAMAS_DESCR_2"
fi

rm $HAMAS_IP_ADDR_LIST
