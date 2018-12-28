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

# get command line arguments
INPUTARGS=`/usr/bin/getopt --options "hsvc" --long "help,screen,verbose,cert" -- "$@"`
if [ $? != 0 ] ; then schelp ; fi
#echo "TEMP: >$TEMP<"
eval set -- "$INPUTARGS"

while true; do
  case "$1" in
    -s|--screen  ) PRINTTOSCREEN=1; shift;;
    -v|--verbose ) PRINTVERBOSESCREEN=1 ; shift;;
    -c|--cert )   CERTFILE=$2; shift 2;;
    -h|--help )   schelp;exit;shift;;
    --) break;;
  esac
done

# main part of script

for (( i = 0 ;  i < ${#PROCNAME[@]} ; i++ )) ; do

    SCRIPTINDEX=$(addOneToIndex $SCRIPTINDEX)
    pidinfo=`${SYSCHECK_HOME}/lib/proc_checker.sh ${PIDFILE[$i]} ${PROCNAME[$i]}`
    if [ "x$pidinfo" = "x" ] ; then

	# try restart
	if [ "x${RESTARTCMD[$i]}" = "x" ] ; then
	    # no restart cmd defined
	    printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   $ERROR ${ERRNO[3]} "${DESCR[3]}" ${PROCNAME[$i]}
	    continue
	fi

	SCRIPTINDEX=$(addOneToIndex $SCRIPTINDEX)
	eval ${RESTARTCMD[$i]}

	if [ $? -eq 0 ] ; then
	# log restart success
            printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   $WARN ${ERRNO[2]} "${DESCR[2]}" ${PROCNAME[$i]}
	else
	# log restart fail
            printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}    $ERROR ${ERRNO[3]} "${DESCR[3]}" ${PROCNAME[$i]}
	fi
    else
        printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   $INFO ${ERRNO[1]} "${DESCR[1]}" ${PROCNAME[$i]}
    fi


done
