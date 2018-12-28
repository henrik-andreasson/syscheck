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
SCRIPTNAME=vip

# uniq ID of script (please use in the name of this file also for convinice for finding next availavle number)
SCRIPTID=28

# how many info/warn/error messages
NO_OF_ERR=4
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

SCRIPTINDEX=$(addOneToIndex $SCRIPTINDEX)
CHECK_VIP_NODE1=`${SYSCHECK_HOME}/related-enabled/915_remote_command_via_ssh.sh ${HOSTNAME_NODE1} "${IFCONFIG} | grep ${HOSTNAME_VIRTUAL}" ${SSH_USER} ${SSH_KEY} | awk '{print $2}' | sed 's/addr\://g'`
CHECK_VIP_NODE2=`${SYSCHECK_HOME}/related-enabled/915_remote_command_via_ssh.sh ${HOSTNAME_NODE2} "${IFCONFIG} | grep ${HOSTNAME_VIRTUAL}" ${SSH_USER} ${SSH_KEY} | awk '{print $2}' | sed 's/addr\://g'`

if [ "$CHECK_VIP_NODE1" = "${HOSTNAME_VIRTUAL}" -a "$CHECK_VIP_NODE2" = "${HOSTNAME_VIRTUAL}" ] ; then
	printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   $ERROR ${ERRNO[3]} "${DESCR[3]}"
elif [ "$CHECK_VIP_NODE1" = "${HOSTNAME_VIRTUAL}" ] ; then
	printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   $INFO ${ERRNO[1]} "${DESCR[1]}"
elif [ "$CHECK_VIP_NODE2" = "${HOSTNAME_VIRTUAL}" ] ; then
	printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   $INFO ${ERRNO[2]} "${DESCR[2]}"
fi

SCRIPTINDEX=$(addOneToIndex $SCRIPTINDEX)
if [ ! "$NODE1" = "${HOSTNAME_VIRTUAL}" -a ! "$CHECK_VIP_NODE2" = "${HOSTNAME_VIRTUAL}" ] ; then
	printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   $ERROR ${ERRNO[4]} "${DESCR[4]}"
fi
