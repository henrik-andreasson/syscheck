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
SCRIPTNAME=dss

# uniq ID of script (please use in the name of this file also for convinice for finding next availavle number)
SCRIPTID=27

# how many info/warn/error messages
NO_OF_ERR=4
initscript $SCRIPTID $NO_OF_ERR

default_script_getopt $*

# main part of script

if [ ! -f $SIGNSERVER_HOME/bin/signserver.sh ] ; then
    printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[4]} -d "${DESCR[4]}"
    exit
fi
cd $SIGNSERVER_HOME
OUTPUT=$($SIGNSERVER_HOME/bin/signserver.sh getstatus all 1 | grep "Status : Active" | wc -l)


SCRIPTINDEX=$(addOneToIndex $SCRIPTINDEX)
if [ "$OUTPUT" = "2" ] ; then
	printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX}  -l $INFO -e ${ERRNO[1]} -d "${DESCR[1]}"
elif [ "$OUTPUT" = "1" ] ; then
	printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX}  -l $WARN -e ${ERRNO[2]} -d "${DESCR[2]}"
else
	printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX}  -l $ERROR -e ${ERRNO[3]} -d "${DESCR[3]}"
fi
