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
SCRIPTNAME=ntp

# uniq ID of script (please use in the name of this file also for convinice for finding next availavle number)
SCRIPTID=17

# how many info/warn/error messages
NO_OF_ERR=5
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

checkntp () {
	NTPSERVER=$1
	SCRIPTINDEX=$2
	if [ "x${NTPSERVER}" = "x" ] ; then
		printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   $ERROR ${ERRNO[5]} "${DESCR[5]}" "ntpserver not set"
		return
	fi


	XNTPDPID=`ps -ef | grep ntpd | grep -v grep | awk '{print $2}'`
	if [ x"$XNTPDPID" = "x" ]; then
		printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   $ERROR ${ERRNO[2]} "${DESCR[2]}"
		exit
	fi

	# Get information about ntp
        result=$( ${NTPBIN} -np 2>&1| grep ${NTPSERVER} | egrep '^\*' )
	if [ "x${result}" != "x" ] ; then
		synchost=$(echo $result | awk '{print $1}')
		syncoffset=$(echo $result | awk '{print $8}')
		STATUS="$synchost $syncoffset"
	fi
}

# check with the IP:s of all ntp servers

# default is to asume that no server is in sync
# then we loop over all servers until we find one in sync
STATUS="no server is in sync"

for (( i = 0 ;  i < ${#NTPSERVER[@]} ; i++ )) ; do
    checkntp ${NTPSERVER[$i]} $SCRIPTINDEX
done

SCRIPTINDEX=$(addOneToIndex $SCRIPTINDEX)

if [ "x${STATUS}" == "xno server is in sync" ] ; then
        printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   $ERROR ${ERRNO[3]} "${DESCR[3]}" "$STATUS" "$synchost" "$syncoffset"
else
        printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   $INFO ${ERRNO[1]} "${DESCR[1]}" "$STATUS" "$synchost" "$syncoffset"
fi
