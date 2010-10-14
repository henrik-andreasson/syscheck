#!/bin/bash

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
SCRIPTID=14

getlangfiles $SCRIPTID
getconfig $SCRIPTID

SW_RAID_ERRNO_1=${SCRIPTID}01
SW_RAID_ERRNO_2=${SCRIPTID}02
SW_RAID_ERRNO_3=${SCRIPTID}03

if [ "x$1" = "x--help" -o "x$1" = "x-h" ] ; then
    echo -e "$0: $SW_RAID_HELP"
    echo -e "$SW_RAID_ERRNO_1 - $SW_RAID_HELP_1" 
    echo -e "$SW_RAID_ERRNO_2 - $SW_RAID_HELP_2" 
    echo -e "$SW_RAID_ERRNO_3 - $SW_RAID_HELP_3" 
    
elif [ "x$1" = "x--screen" -o "x$1" = "x-s" ] ; then
	PRINTTOSCREEN=1
fi

swraidcheck () {
	ARRAY=$1
        DISC=$2

        COMMAND=`mdadm --detail $ARRAY 2>&1| grep $DISC `

        STATUSactive=`echo $COMMAND | grep 'active sync' `
        STATUSfault=`echo $COMMAND | grep 'fault' `
        if [ "x$STATUSactive" != "x" ] ; then
		# ok
                printlogmess $INFO $SW_RAID_ERRNO_1 "$SW_RAID_DESCR_1" "$ARRAY / $DISC"
        elif [ "x$STATUSfault" != "x" ] ; then
		# fault
                printlogmess $ERROR $SW_RAID_ERRNO_2 "$SW_RAID_DESCR_2" "$ARRAY / $DISC ($COMMAND)"
        else
		# failed some other way
                printlogmess $ERROR $SW_RAID_ERRNO_3 "$SW_RAID_DESCR_3" "$ARRAY / $DISC ($COMMAND)"

        fi
}

for (( i = 0 ;  i < ${#MDDEV[@]} ; i++ )) ; do
    swraidcheck ${#MDDEV[$i]} ${#DDDEV[$i]}
done


