#!/bin/bash
# Script to check if the NTP client is running and is synchronized.
# This script has been tested with the xntp rpm package on Suse Linux Enterprise Server 9.
# Add the servers in the end of the file.
# Usage:
# checkntp '<server name or ip address>'

# Set default home if not already set.
SYSCHECK_HOME=${SYSCHECK_HOME:-"/usr/local/syscheck"}

# uniq ID of script (please use in the name of this file also for convinice for finding next availavle number)
SCRIPTID=17

## Import common definitions ##
. $SYSCHECK_HOME/resources.sh

NTP_ERRNO_1=${SCRIPTID}01
NTP_ERRNO_2=${SCRIPTID}02
NTP_ERRNO_3=${SCRIPTID}03


# help
if [ "x$1" = "x--help" ] ; then
    echo "$0 $NTP_HELP"
    echo "$NTP_ERRNO_1/$NTP_DESCR_1 - $NTP_HELP_1"
    echo "$NTP_ERRNO_2/$NTP_DESCR_2 - $NTP_HELP_2"
    echo "$NTP_ERRNO_3/$NTP_DESCR_3 - $NTP_HELP_3"
    exit
elif [ "x$1" = "x-s" -o  "x$1" = "x--screen" ] ; then
    PRINTTOSCREEN=1
fi


NTP_SERVERS=`grep '^server' /etc/ntp.conf  | awk  '{print $2}'`
i=0
for server in ${NTP_SERVERS} ; do
	IP_NTP_SERVERS[$i]=`host $server | grep address | awk '{print $4}'`
	i=`expr $i + 1`
done


trap mytrapfunc HUP KILL QUIT TERM

checkntp () {
	NTPSERVER=$1
	DATE=`date +'%Y-%m-%d'`
	XNTPDPID=`ps -ef | grep ntpd | grep -v grep | awk '{print $2}'`
	if [ x"$XNTPDPID" = "x" ]; then
		printlogmess $ERROR $NTP_ERRNO_2 "$NTP_DESCR_2"
		exit
	fi	
	NTPTEMPFILE='checkntpsync-'$DATE

	# todo make one row, and no tempfile
	ntpq -pn > /tmp/$NTPTEMPFILE
	NTPCHECK=`cat /tmp/$NTPTEMPFILE | grep $NTPSERVER`

	if [ x"$NTPCHECK" = "x" ]; then
		printlogmess $ERROR $NTP_ERRNO_3 "$NTP_DESCR_3" "$NTPSERVER"
		exit
	fi	
	printlogmess $INFO $NTP_ERRNO_1 "$NTP_DESCR_1" "$NTPSERVER"
}

mytrapfunc () {
	rm -f /tmp/$NTPTEMPFILE
	exit 1
}


# check with the IP:s of all ntp servers
for (( i = 0 ;  i < ${#IP_NTP_SERVERS[@]} ; i++ )) ; do
	checkntp ${IP_NTP_SERVERS[$i]}
done

