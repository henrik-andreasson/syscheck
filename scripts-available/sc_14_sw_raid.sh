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

# Index is used to uniquely identify one test done by the script (a harddrive, crl or cert)
SCRIPTINDEX=00

getlangfiles $SCRIPTID
getconfig $SCRIPTID

ERRNO_1=01
ERRNO_2=02
ERRNO_3=03

if [ "x$1" = "x--help" -o "x$1" = "x-h" ] ; then
    echo -e "$0: $HELP"
    echo -e "$ERRNO_1 - $HELP_1" 
    echo -e "$ERRNO_2 - $HELP_2" 
    echo -e "$ERRNO_3 - $HELP_3" 
    
elif [ "x$1" = "x--screen" -o "x$1" = "x-s" ] ; then
	PRINTTOSCREEN=1
fi

swraidcheck () {
	ARRAY=$1
        DISC=$2
	SCRIPTINDEX=$3

        COMMAND=`mdadm --detail $ARRAY 2>&1| grep $DISC `

        STATUSactive=`echo $COMMAND | grep 'active sync' `
        STATUSfault=`echo $COMMAND | grep 'fault' `
        if [ "x$STATUSactive" != "x" ] ; then
		# ok
                printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   $INFO $ERRNO_1 "$DESCR_1" "$ARRAY / $DISC"
        elif [ "x$STATUSfault" != "x" ] ; then
		# fault
                printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   $ERROR $ERRNO_2 "$DESCR_2" "$ARRAY / $DISC ($COMMAND)"
        else
		# failed some other way
                printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   $ERROR $ERRNO_3 "$DESCR_3" "$ARRAY / $DISC ($COMMAND)"

        fi
}

for (( i = 0 ;  i < ${#MDDEV[@]} ; i++ )) ; do
    SCRIPTINDEX=$(addOneToIndex $SCRIPTINDEX)
    swraidcheck ${#MDDEV[$i]} ${#DDDEV[$i]} $SCRIPTINDEX
done


