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
NO_OF_ERR=5
initscript $SCRIPTID $NO_OF_ERR

default_script_getopt $*

# main part of script

if [ ! -f "${SYSCHECK_HOME}/related-enabled/915_remote_command_via_ssh.sh" ] ; then
  printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[5]} -d "${DESCR[5]}"
  exit
fi
SCRIPTINDEX=$(addOneToIndex $SCRIPTINDEX)
CHECK_VIP_NODE1=$(${SYSCHECK_HOME}/related-enabled/915_remote_command_via_ssh.sh ${HOSTNAME_NODE1} "${IFCONFIG} | grep ${HOSTNAME_VIRTUAL}" ${SSH_USER} ${SSH_KEY} | awk '{print $2}' | sed 's/addr\://g')
CHECK_VIP_NODE2=$(${SYSCHECK_HOME}/related-enabled/915_remote_command_via_ssh.sh ${HOSTNAME_NODE2} "${IFCONFIG} | grep ${HOSTNAME_VIRTUAL}" ${SSH_USER} ${SSH_KEY} | awk '{print $2}' | sed 's/addr\://g')

if [ "$CHECK_VIP_NODE1" = "${HOSTNAME_VIRTUAL}" -a "$CHECK_VIP_NODE2" = "${HOSTNAME_VIRTUAL}" ] ; then
	printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[3]} -d "${DESCR[3]}"
elif [ "$CHECK_VIP_NODE1" = "${HOSTNAME_VIRTUAL}" ] ; then
	printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $INFO  -e ${ERRNO[1]} -d "${DESCR[1]}"
elif [ "$CHECK_VIP_NODE2" = "${HOSTNAME_VIRTUAL}" ] ; then
	printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $INFO  -e ${ERRNO[2]} -d "${DESCR[2]}"
fi

SCRIPTINDEX=$(addOneToIndex $SCRIPTINDEX)
if [ ! "$NODE1" = "${HOSTNAME_VIRTUAL}" -a ! "$CHECK_VIP_NODE2" = "${HOSTNAME_VIRTUAL}" ] ; then
	printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[4]} -d "${DESCR[4]}"
fi
