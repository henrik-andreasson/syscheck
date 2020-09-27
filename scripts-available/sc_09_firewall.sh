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
SCRIPTNAME=firewall

# uniq ID of script (please use in the name of this file also for convinice for finding next availavle number)
SCRIPTID=09

# how many info/warn/error messages
NO_OF_ERR=3
initscript $SCRIPTID $NO_OF_ERR

default_script_getopt $*

# main part of script

SCRIPTINDEX=$(addOneToIndex $SCRIPTINDEX)
IPTABLES_RULES=$($IPTABLES_BIN -L -n 2>&1)
if [ $? -ne 0 ] ; then
	printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[1]} -d "${DESCR[1]}"
	exit
fi

FIREWALLFAILED=0

SCRIPTINDEX=$(addOneToIndex $SCRIPTINDEX)
# rule that must exist
rule1check=$(echo "${IPTABLES_RULES}" | grep "$IPTABLES_RULE1")
if [ "x$rule1check" = "x" ] ; then
	FIREWALLFAILED=1
fi

# rule that must not exist
rule2check=$(echo "${IPTABLES_RULES}" | grep "$IPTABLES_RULE2")
if [ "x$rule2check" != "x" ] ; then
	FIREWALLFAILED=1
fi

if [ $FIREWALLFAILED -ne 0 ] ; then
	printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[2]} -d "${DESCR[2]}"
else
	printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $INFO  -e ${ERRNO[3]} -d "${DESCR[3]}"
fi
