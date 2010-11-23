#!/bin/sh 

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
SCRIPTID=300

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

    pidinfo=`${SYSCHECK_HOME}/lib/proc_checker.sh ${PIDFILE[$i]} ${PROCNAME[$i]}` 
    if [ "x$pidinfo" = "x" ] ; then

	# try restart 
	if [ "x${RESTARTCMD[$i]}" = "x" ] ; then
	    # no restart cmd defined
	    printlogmess ${LEVEL[3]} ${ERRNO[3]} "${DESCR[3]}" ${PROCNAME[$i]}
	    continue
	fi

	eval ${RESTARTCMD[$i]}
	
	if [ $? -eq 0 ] ; then
	# log restart success
            printlogmess ${LEVEL[1]} ${ERRNO[1]} "${DESCR[1]}" ${PROCNAME[$i]}
	else
	# log restart fail
            printlogmess  ${LEVEL[2]} ${ERRNO[2]} "${DESCR[2]}" ${PROCNAME[$i]}
	fi
    else
        printlogmess ${LEVEL[0]} ${ERRNO[0]} "${DESCR[0]}" ${PROCNAME[$i]}
	printtoscreen "proc $i: ${PROCNAME[$i]} is running"
    fi


done

