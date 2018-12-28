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

# get command line arguments
INPUTARGS=`/usr/bin/getopt --options "hsv" --long "help,screen,verbose" -- "$@"`
if [ $? != 0 ] ; then schelp ; fi
#echo "TEMP: >$TEMP<"
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

CMD=$($SYSCHECK_HOME/lib/list_reader.pl 2>&1)
ERRCHK=$(echo $CMD| grep "locate Chipcard/PCSC.pm")

if [ "x$ERRCHK" != "x" ] ; then
	printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX} $WARN ${ERRNO[3]} "${DESCR[3]}" "$CMD"
	exit
fi

STATUS=`echo $CMD | perl -ane 'm/Number\ of\ attatched\ readers:\ (\d+)/gio, print $1'`

SCRIPTINDEX=$(addOneToIndex $SCRIPTINDEX)
if [ "$PCSC_NUMBER_OF_READERS" = "$STATUS" ] ; then
        printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   $INFO ${ERRNO[1]} "${DESCR[1]}" "$STATUS"

else

        printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   $ERROR ${ERRNO[2]} "${DESCR[2]}" "$STATUS"
fi

SCRIPTNAME=pcscreaders
