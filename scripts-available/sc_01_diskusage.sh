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
SCRIPTNAME=diskusage

# uniq ID of script (please use in the name of this file also for convinice for finding next availavle number)
SCRIPTID=01

# how many info/warn/error messages
NO_OF_ERR=3
initscript $SCRIPTID $NO_OF_ERR

# get command line arguments
INPUTARGS=`/usr/bin/getopt --options "hsvc" --long "help,screen,verbose" -- "$@"`
if [ $? != 0 ] ; then schelp ; fi
eval set -- "$INPUTARGS"

while true; do
  case "$1" in
    -s|--screen  ) PRINTTOSCREEN=1; shift;;
    -v|--verbose ) PRINTVERBOSESCREEN=1 ; shift;;
    -h|--help )   schelp;exit;shift;;
    --) break;;
  esac
done

# main part of script

diskusage () {
	FILESYSTEM=$1
	LIMIT=$2

	if [ "x${FILESYSTEM}" = "x" ] ; then
		printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX} $ERROR ${ERRNO[3]} "${DESCR[3]}" "No filesystem specified"
		return -1
	fi
	if [ "x${LIMIT}" = "x" ] ; then
		printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX} $ERROR ${ERRNO[3]} "${DESCR[3]}" "No limit specified"
		return -1
	fi

	DFPH=`df -Ph $FILESYSTEM 2>&1`

	if [ $retcode -ne 0 ] ; then
		printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX} $ERROR ${ERRNO[3]} "${DESCR[3]}" "$FILESYSTEM" "$DFPH"
	else

		PERCENT=`df -Ph $FILESYSTEM | grep -v Filesystem| awk '{print $5}' | sed 's/%//'`

		if [ $PERCENT -gt $LIMIT ] ; then
       	         	printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX} $ERROR ${ERRNO[2]} "${DESCR[2]}" "$FILESYSTEM" "$PERCENT" "$LIMIT"
		else
                	printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX} $INFO ${ERRNO[1]}  "${DESCR[1]}" "$FILESYSTEM" "$PERCENT" "$LIMIT"
		fi
	fi
}


for (( i = 0 ;  i < ${#FILESYSTEM[@]} ; i++ )) ; do
	SCRIPTINDEX=$(addOneToIndex $SCRIPTINDEX)
	diskusage ${FILESYSTEM[$i]}  ${USAGEPERCENT[$i]} ${SCRIPTINDEX}
done
