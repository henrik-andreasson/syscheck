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

default_script_getopt $*

# main part of script

diskusage () {
	FILESYSTEM=$1
	ERRLIMIT=$2
  WARNLIMIT=$3
  SCRIPTINDEX=$4

	if [ "x${FILESYSTEM}" = "x" ] ; then
		printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[3]} -d "${DESCR[3]}" -1 "No filesystem specified"
		return -1
	fi
  if [ "x${ERRLIMIT}" = "x" ] ; then
		printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[3]} -d "${DESCR[3]}" -1 "No limit specified"
		return -1
	fi

  if [ "x${WARNLIMIT}" = "x" ] ; then
    WARNLIMIT="${ERRLIMIT}"
	fi

	DFPH=`df -Ph $FILESYSTEM 2>&1`

	if [ $? -ne 0 ] ; then
		printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[3]} -d "${DESCR[3]}" -1 "$FILESYSTEM" -2 "$DFPH"
	else

		PERCENT=`df -Ph $FILESYSTEM | grep -v Filesystem| awk '{print $5}' | sed 's/%//'`


    if [ $PERCENT -gt $ERRLIMIT ] ; then
       	printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[2]} -d "${DESCR[2]}" -1 "$FILESYSTEM" -2 "$PERCENT" -3 "$ERRLIMIT"
    elif [ $PERCENT -gt $WARNLIMIT ] ; then
       	printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $WARN -e ${ERRNO[2]} -d "${DESCR[2]}" -1 "$FILESYSTEM" -2 "$PERCENT" -3 "$WARNLIMIT"
		else
      	printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $INFO -e ${ERRNO[1]}  -d "${DESCR[1]}" -1 "$FILESYSTEM" -2 "$PERCENT" -3 "$LIMIT"
		fi
	fi
}


for (( i = 0 ;  i < ${#FILESYSTEM[@]} ; i++ )) ; do
	SCRIPTINDEX=$(addOneToIndex $SCRIPTINDEX)
	diskusage ${FILESYSTEM[$i]}  ${USAGEPERCENT[$i]} ${WARN_PERCENT[$i]} ${SCRIPTINDEX}
done
