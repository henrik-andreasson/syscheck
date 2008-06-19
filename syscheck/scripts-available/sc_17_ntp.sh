#!/bin/bash
# Script to check if the NTP client is running and is synchronized.
# This script has been tested with the xntp rpm package on Suse Linux Enterprise Server 9.
# Add the servers in the end of the file.
# Usage:
# checkntp '<server name or ip address>'

# Set default home if not already set.
SYSCHECK_HOME=${SYSCHECK_HOME:-"/usr/local/syscheck"}

## Import common definitions ##
. $SYSCHECK_HOME/resources.sh


# uniq ID of script (please use in the name of this file also for convinice for finding next availavle number)
SCRIPTID=17

getlangfiles $SCRIPTID ;


ERRNO_1=${SCRIPTID}01
ERRNO_2=${SCRIPTID}02
ERRNO_3=${SCRIPTID}03
ERRNO_4=${SCRIPTID}04
ERRNO_5=${SCRIPTID}05

## local definitions ###
NTPBIN="/usr/sbin/ntpq"
NTPCONF="/etc/ntp.conf"

# help
if [ "x$1" = "x--help" ] ; then
    echo "$0 $NTP_HELP"
    echo "$ERRNO_1/$NTP_DESCR_1 - $NTP_HELP_1"
    echo "$ERRNO_2/$NTP_DESCR_2 - $NTP_HELP_2"
    echo "$ERRNO_3/$NTP_DESCR_3 - $NTP_HELP_3"
    echo "$ERRNO_4/$NTP_DESCR_4 - $NTP_HELP_4"
    echo "$ERRNO_5/$NTP_DESCR_5 - $NTP_HELP_5"
    exit
elif [ "x$1" = "x-s" -o  "x$1" = "x--screen" ] ; then
    PRINTTOSCREEN=1
fi


NTP_SERVERS=`grep '^server' ${NTPCONF} 2>/dev/null | awk  '{print $2}' `
if [ "x$NTP_SERVERS" = "x" ]; then
    printlogmess $ERROR $ERRNO_5 "$NTP_DESCR_5" 
    exit
fi	


i=0
for server in ${NTP_SERVERS} ; do
	IP_NTP_SERVERS[$i]=`host $server | grep address | awk '{print $4}'`
	i=`expr $i + 1`
done



checkntp () {
	NTPSERVER=$1
	DATE=`date +'%Y-%m-%d.%H.%m.%S'`
	XNTPDPID=`ps -ef | grep ntpd | grep -v grep | awk '{print $2}'`
	if [ x"$XNTPDPID" = "x" ]; then
		printlogmess $ERROR $NTP_ERRNO_2 "$NTP_DESCR_2"
		exit
	fi	
	NTPTEMPFILE='checkntpsync-'$DATE

	# todo make one row, and no tempfile
	${NTPBIN} -pn > /tmp/$NTPTEMPFILE 2>&1
	NTPCHECK=`cat /tmp/$NTPTEMPFILE | grep $NTPSERVER`

	if [ x"$NTPCHECK" = "x" ]; then
		printlogmess $ERROR $NTP_ERRNO_3 "$NTP_DESCR_3" "$NTPSERVER" "$ERRCODE"
		rm -f /tmp/$NTPTEMPFILE
		exit
	fi	
	printlogmess $INFO $NTP_ERRNO_1 "$NTP_DESCR_1" "$NTPSERVER"
}


# check with the IP:s of all ntp servers
for (( i = 0 ;  i < ${#IP_NTP_SERVERS[@]} ; i++ )) ; do
	checkntp ${IP_NTP_SERVERS[$i]}
done

