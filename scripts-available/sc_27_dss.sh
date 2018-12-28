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


if [ ! -f $SIGNSERVER_HOME/bin/signserver.sh ] ; then
    printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   $ERROR ${ERRNO[4]} "${DESCR[4]}"
    exit
fi
cd $SIGNSERVER_HOME
OUTPUT=`$SIGNSERVER_HOME/bin/signserver.sh getstatus all 1 | grep "Status : Active" | wc -l`


SCRIPTINDEX=$(addOneToIndex $SCRIPTINDEX)
if [ "$OUTPUT" = "2" ] ; then
	printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   $INFO ${ERRNO[1]} "${DESCR[1]}"
elif [ "$OUTPUT" = "1" ] ; then
	printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   $WARNING ${ERRNO[2]} "${DESCR[2]}"
else
	printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   $ERROR ${ERRNO[3]} "${DESCR[3]}"
fi
