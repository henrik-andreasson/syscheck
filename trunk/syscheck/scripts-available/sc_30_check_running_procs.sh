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


# uniq ID of script (please use in the name of this file also for convinice for finding next availavle number)
SCRIPTID=30

# Index is used to uniquely identify one test done by the script (a harddrive, crl or cert)
SCRIPTINDEX=00

## Import common definitions ##
. $SYSCHECK_HOME/config/syscheck-scripts.conf

getlangfiles $SCRIPTID
getconfig $SCRIPTID


# help
if [ "x$1" = "x--help" ] ; then
    displayhelp
    exit
elif [ "x$1" = "x-s" -o  "x$1" = "x--screen"  ] ; then
    PRINTTOSCREEN=1
fi


for (( i = 0 ;  i < ${#PROCNAME[@]} ; i++ )) ; do

    SCRIPTINDEX=$(addOneToIndex $SCRIPTINDEX)
    pidinfo=`${SYSCHECK_HOME}/lib/proc_checker.sh ${PIDFILE[$i]} ${PROCNAME[$i]}` 
    if [ "x$pidinfo" = "x" ] ; then

	# try restart 
	if [ "x${RESTARTCMD[$i]}" = "x" ] ; then
	    # no restart cmd defined
	    printlogmess ${SCRIPTID} ${SCRIPTINDEX}   $ERROR $ERRNO_3 "$DESCR_3" ${PROCNAME[$i]}
	    continue
	fi

	SCRIPTINDEX=$(addOneToIndex $SCRIPTINDEX)	
	eval ${RESTARTCMD[$i]}

	if [ $? -eq 0 ] ; then
	# log restart success
            printlogmess ${SCRIPTID} ${SCRIPTINDEX}   $WARN $ERRNO_2 "$DESCR_2" ${PROCNAME[$i]}
	else
	# log restart fail
            printlogmess ${SCRIPTID} ${SCRIPTINDEX}    $ERROR $ERRNO_3 "$DESCR_3" ${PROCNAME[$i]}
	fi
    else
        printlogmess ${SCRIPTID} ${SCRIPTINDEX}   $INFO $ERRNO_1 "$DESCR_1" ${PROCNAME[$i]}
    fi


done

