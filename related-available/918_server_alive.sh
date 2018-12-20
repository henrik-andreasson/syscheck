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

set -e 



# Import common resources
source $SYSCHECK_HOME/config/related-scripts.conf

SCRIPTID=918
SCRIPTINDEX=00

getlangfiles $SCRIPTID
getconfig $SCRIPTID

ERRNO_1=${SCRIPTID}1 # machine has called in as it's supposed to.
ERRNO_2=${SCRIPTID}2 # machine has not called in within error limit
ERRNO_3=${SCRIPTID}3 # machine has not called in within warn limit  
  
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

	LASTLOGTS=`grep -ni "1903.*${HOST[$i]}" ${LOGFILECURRENT} ${LOGFILELAST} | tail -1 |  awk '{print $7,$8}'`
	if [ "x$LASTLOGTS" != "x" ] ;then
		MINUTES_SINCE_LASTLOG=`${SYSCHECK_HOME}/lib/cmp_syslog_dates.pl "$LASTLOGTS" | awk '{print $1}'`

		if [ ${MINUTES_SINCE_LASTLOG} -gt ${TIME_BEFORE_ERROR} ] ; then
			printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   $ERROR ${ERRNO_2} "$SCALIVE_SRV_DESCR_2" ${HOST[$i]} ${MINUTES_SINCE_LASTLOG}
		elif [ ${MINUTES_SINCE_LASTLOG} -gt ${TIME_BEFORE_WARN} ] ; then		
	    		printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   $WARN ${ERRNO_3} "$SCALIVE_SRV_DESCR_3" ${HOST[$i]} ${MINUTES_SINCE_LASTLOG}
		else
			printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   $INFO ${ERRNO_1} "$SCALIVE_SRV_DESCR_1" ${HOST[$i]} ${MINUTES_SINCE_LASTLOG}
		fi
	else
		printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   $ERROR ${ERRNO_2} "$SCALIVE_SRV_DESCR_2" ${HOST[$i]}
	fi
	
        
done

