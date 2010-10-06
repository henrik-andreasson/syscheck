#!/bin/sh 

# Set default home if not already set.
SYSCHECK_HOME=${SYSCHECK_HOME:-"/usr/local/syscheck"}

# uniq ID of script (please use in the name of this file also for convinice for finding next availavle number)
SCRIPTID=30

## Import common definitions ##
. $SYSCHECK_HOME/config/syscheck-scripts.conf

getlangfiles $SCRIPTID
getconfig $SCRIPTID

ERRNO_1=${SCRIPTID}01
ERRNO_2=${SCRIPTID}02
ERRNO_3=${SCRIPTID}03
ERRNO_4=${SCRIPTID}04


# help
if [ "x$1" = "x--help" ] ; then
    echo "$0 $HELP"
    echo "$ERRNO_1/$DESCR_1 - $HELP_1"
    echo "$ERRNO_2/$DESCR_2 - $HELP_2"
    echo "$ERRNO_3/$DESCR_3 - $HELP_3"
    echo "$ERRNO_4/$DESCR_4 - $HELP_4"
    exit
elif [ "x$1" = "x-s" -o  "x$1" = "x--screen"  ] ; then
    PRINTTOSCREEN=1
fi


for (( i = 0 ;  i < ${#PROCNAME[@]} ; i++ )) ; do

    pidinfo=`${SYSCHECK_HOME}/lib/proc_checker.sh ${PIDFILE[$i]} ${PROCNAME[$i]}` 
    if [ "x$pidinfo" = "x" ] ; then

	# try restart 
	if [ "x${RESTARTCMD[$i]}" = "x" ] ; then
	    printlogmess $ERROR $ERRNO_4 "$DESCR_4" ${PROCNAME[$i]}
	    continue
	fi

	eval ${RESTARTCMD[$i]}
	
	if [ $? -ne 0 ] ; then
	# log restart success
            printlogmess $INFO $ERRNO_1 "$DESCR_1" ${PROCNAME[$i]}
	else
	# log restart fail
            printlogmess $ERROR $ERRNO_3 "$DESCR_2" ${PROCNAME[$i]}
	fi
    else
	printtoscreen "proc $i: ${PROCNAME[$i]} is running, no action needed"
    fi


done

