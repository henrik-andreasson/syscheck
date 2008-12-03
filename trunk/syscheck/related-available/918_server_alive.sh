#!/bin/bash

set -e 

SYSCHECK_HOME=${SYSCHECK_HOME:-"/usr/local/syscheck"}

# Import common resources
. $SYSCHECK_HOME/resources.sh

SCRIPTID=918
getlangfiles $SCRIPTID
getconfig $SCRIPTID

ERRNO_1=${SCRIPTID}1 # machine has called in as it's supposed to.
ERRNO_2=${SCRIPTID}2 # machine has not called in within warn limit  
ERRNO_3=${SCRIPTID}3 # machine has not called in within error limit
  
if [ "x$1" = "x--help" ] ; then
    echo "$SCALIVE_HELP"
    echo "$ERRNO_1/$SCALIVE_SRV_DESCR_1 - $SCALIVE_SRV_HELP_1"
    echo "$ERRNO_2/$SCALIVE_SRV_DESCR_2 - $SCALIVE_SRV_HELP_2"
    echo "$ERRNO_3/$SCALIVE_SRV_DESCR_3 - $SCALIVE_SRV_HELP_3"
    echo "${SCREEN_HELP}"
    exit
elif [ "x$1" = "x-s" -o  "x$1" = "x--screen"  ] ; then
    PRINTTOSCREEN=1
fi 

# loop tough all servers that should have reported in
for (( i = 0 ;  i < ${#HOST[@]} ; i++ )) ; do  

	LASTLOGTS=`grep -ni "9183.*${HOST[$i]}" ${LOGFILE} |  awk '{print $7,$8}'`
	MINUTES_SINCE_LASTLOG=`${SYSCHECK_HOME}/lib/cmp_syslog_dates.pl "$LASTLOGTS"`

	if [ ${MINUTES_SINCE_LASTLOG} -gt ${TIME_BEFORE_ERROR} ] ; then
		printlogmess $ERROR $ERRNO_2
	elif [ ${MINUTES_SINCE_LASTLOG} -gt ${TIME_BEFORE_WARN} ] ; then		
    	printlogmess $WARN $ERRNO_3
    else
		printlogmess $INFO $ERRNO_1
    fi
        
done

