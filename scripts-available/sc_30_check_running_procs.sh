#!/bin/bash

SYSCHECK_HOME="${SYSCHECK_HOME:-/opt/syscheck}" # use default if  unset
if [ ! -f ${SYSCHECK_HOME}/syscheck.sh ] ; then
  echo "Can't find $SYSCHECK_HOME/syscheck.sh"
  exit
fi

if [ ! -f ${SYSCHECK_HOME}/syscheck.sh ] ; then echo "Can't find $SYSCHECK_HOME/syscheck.sh" ;exit ; fi

## Import common definitions ##
source $SYSCHECK_HOME/config/syscheck-scripts.conf

# script name, used when integrating with nagios/icinga
SCRIPTNAME=running_processes

# uniq ID of script (please use in the name of this file also for convinice for finding next availavle number)
SCRIPTID=30

# how many info/warn/error messages
NO_OF_ERR=3
initscript $SCRIPTID $NO_OF_ERR

default_script_getopt $*

# main part of script

for (( i = 0 ;  i < ${#PROCNAME[@]} ; i++ )) ; do

    SCRIPTINDEX=$(addOneToIndex $SCRIPTINDEX)
    pidinfo=`${SYSCHECK_HOME}/lib/proc_checker.sh ${PIDFILE[$i]} ${PROCNAME[$i]}`
    if [ "x$pidinfo" = "x" ] ; then

	# try restart
	if [ "x${RESTARTCMD[$i]}" = "x" ] ; then
	    # no restart cmd defined
	    printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[3]} -d "${DESCR[3]}" -1 "${PROCNAME[$i]}"
	    continue
	fi

	SCRIPTINDEX=$(addOneToIndex $SCRIPTINDEX)
	FOO=$(${RESTARTCMD[$i]} 2>&1)

	if [ $? -eq 0 ] ; then
	# log restart success
            printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $WARN -e ${ERRNO[2]} -d "${DESCR[2]}" -1 "${PROCNAME[$i]}"
	else
	# log restart fail
            printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[3]} -d "${DESCR[3]}" -1 "${PROCNAME[$i]}"
	fi
    else
        printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $INFO -e ${ERRNO[1]} -d "${DESCR[1]}" -1 "${PROCNAME[$i]}"
    fi


done
