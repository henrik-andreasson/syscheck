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

# Import common resources
. $SYSCHECK_HOME/resources.sh

NTP_ERRNO_1=${SCRIPTID}01
NTP_ERRNO_2=${SCRIPTID}02
NTP_ERRNO_3=${SCRIPTID}03
NTP_ERRNO_4=${SCRIPTID}04


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


CHECKNTPRUNONCE=0

trap mytrapfunc HUP KILL QUIT TERM

checkntp () {
	DATE=`date +'%Y-%m-%d'`
	CHECKNTPRUN=`ps -ef | grep ntpd | grep -v grep | sed 's/\/usr\/sbin\///g' | awk '{print $8}'`
	XNTPDPID=`ps -ef | grep ntpd | grep -v grep | awk '{print $2}'`
	NTPTEMPFILE='checkntpsync-'$DATE
	NTPSERVER=( "$1" )

	ntpq -p > /tmp/$NTPTEMPFILE

	NTPCHECKTEMPFILE=`cat /tmp/$NTPTEMPFILE | grep -v LOCAL | grep -v remote | grep -v = | sed 's/*//g' | sed 's/=//g' | sed 's/+//g' | sed 's/-//g' | awk '{print $1}'`

	# This flag is set so that $CHECKNTPRUN will only run once (no need to have it run for every server defined, because we already now that it is running after the first time).
	while [ x"$CHECKNTPRUNONCE" = x"0" ]; do
		CHECKNTPRUNONCE=`expr $CHECKNTPRUNONCE \+ 1`
		if [ x"$CHECKNTPRUN" != xntpd ]; then
			printlogmess $ERROR $NTP_ERRNO_2 $NTP_DESCR_2
			exit 1
		else
			printlogmess $INFO $NTP_ERRNO_1 $NTP_DESCR_1
		fi
		echo
	done

	# Checks if the servers defined in the en of the file is in the list.
	for (( i = 0 ; i < ${#NTPSERVER[@]} ; i++ )) ; do
		if [ x"$NTPCHECKTEMPFILE" != x${NTPSERVER[$i]} ]; then
			printlogmess $ERROR $NTP_ERRNO_4 $NTP_DESCR_4 \(Server configured: ${NTPSERVER[$i]}\)
		else
			printlogmess $INFO $NTP_ERRNO_3 $NTP_DESCR_3 \(Server configured: ${NTPSERVER[$i]}\)
		fi	
	done
	#rm /tmp/$NTPTEMPFILE
}

mytrapfunc () {
	rm -f /tmp/$NTPTEMPFILE
	exit 1
}

# Add the ntp servers below.
# checkntp 'LOCAL(0)' # This is just for test, do not use the LOCAL(0) in production.

#remove when config:ed 
echo "script need config"
exit

checkntp ntp.company.com
