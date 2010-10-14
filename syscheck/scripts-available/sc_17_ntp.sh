#!/bin/bash
# Script to check if the NTP client is running and is synchronized.
# This script has been tested with the xntp rpm package on Suse Linux Enterprise Server 9.
# Add the servers in the end of the file.
# Usage:
# checkntp '<server name or ip address>'

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
SCRIPTID=17

getlangfiles $SCRIPTID
getconfig $SCRIPTID

NTP_ERRNO_1=${SCRIPTID}01
NTP_ERRNO_2=${SCRIPTID}02
NTP_ERRNO_3=${SCRIPTID}03
NTP_ERRNO_4=${SCRIPTID}04
NTP_ERRNO_5=${SCRIPTID}05


# help
if [ "x$1" = "x--help" ] ; then
    echo "$0 $NTP_HELP"
    echo "$NTP_ERRNO_1/$NTP_DESCR_1 - $NTP_HELP_1"
    echo "$NTP_ERRNO_2/$NTP_DESCR_2 - $NTP_HELP_2"
    echo "$NTP_ERRNO_3/$NTP_DESCR_3 - $NTP_HELP_3"
    echo "$NTP_ERRNO_4/$NTP_DESCR_4 - $NTP_HELP_4"
    echo "$NTP_ERRNO_5/$NTP_DESCR_5 - $NTP_HELP_5"
    exit
elif [ "x$1" = "x-s" -o  "x$1" = "x--screen" ] ; then
    PRINTTOSCREEN=1
fi

checkntp () {
	NTPSERVER=$1
	DATE=`date +'%Y-%m-%d.%H.%m.%S'`
	XNTPDPID=`ps -ef | grep ntpd | grep -v grep | awk '{print $2}'`
	if [ x"$XNTPDPID" = "x" ]; then
		printlogmess $ERROR $NTP_ERRNO_2 "$NTP_DESCR_2"
		exit
	fi	

	# todo make one row, and no tempfile
	STATUS=`${NTPBIN} -pn | grep ${NTPSERVER}`

	if [ "x${STATUS}" = "x" ]; then
		printlogmess $ERROR $NTP_ERRNO_3 "$NTP_DESCR_3" "$NTPSERVER" "$ERRCODE"
	else		
		printlogmess $INFO $NTP_ERRNO_1 "$NTP_DESCR_1" "$NTPSERVER"
	fi	
}


# check with the IP:s of all ntp servers

for (( i = 0 ;  i < ${#NTPHOST[@]} ; i++ )) ; do  
	checkntp "${NTPHOST[$i]}"
done
