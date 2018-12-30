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
SCRIPTNAME=pcscreaders

# uniq ID of script (please use in the name of this file also for convinice for finding next availavle number)
SCRIPTID=04

# how many info/warn/error messages
NO_OF_ERR=3
initscript $SCRIPTID $NO_OF_ERR

default_script_getopt $*

# main part of script

CMD=$($SYSCHECK_HOME/lib/list_reader.pl 2>&1)
ERRCHK=$(echo $CMD| grep "locate Chipcard/PCSC.pm")

if [ "x$ERRCHK" != "x" ] ; then
	printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $WARN -e ${ERRNO[3]} -d "${DESCR[3]}" -1 "$CMD"
	exit
fi

STATUS=$(echo $CMD | perl -ane 'm/Number\ of\ attatched\ readers:\ (\d+)/gio, print $1') # todo not use perl

SCRIPTINDEX=$(addOneToIndex $SCRIPTINDEX)
if [ "$PCSC_NUMBER_OF_READERS" = "$STATUS" ] ; then
        printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $INFO -e ${ERRNO[1]} -d "${DESCR[1]}" -1 "$STATUS"

else

        printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[2]} -d "${DESCR[2]}" -1 "$STATUS"
fi
