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
SCRIPTNAME=raidcheck

# uniq ID of script (please use in the name of this file also for convinice for finding next availavle number)
SCRIPTID=06

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


raiddiskcheck () {
  DISCID="$1"
  xSLOT="$2"
  SCRIPTINDEX=$3

  COMMAND=$(echo "controller slot=${xSLOT} pd all show" | $HPTOOL | grep "$DISCID")
  STATUS=$(echo $COMMAND | grep "OK")
  if [ "x$STATUS" != "x" ] ; then
    printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   $INFO ${ERRNO[1]} "${DESCR[1]}" "$COMMAND"
  else
    printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   $ERROR ${ERRNO[2]} "${DESCR[2]}" "$COMMAND disc: $DISCID slot: $xSLOT"
  fi
}


raidlogiccheck () {
  LDID="$1"
  xSLOT="$2"
  SCRIPTINDEX=$3

  COMMAND=`echo "controller slot=${xSLOT} ld all show" | $HPTOOL | grep "$LDID"`
  STATUS=`echo $COMMAND | grep "OK"`

  if [ "x$STATUS" != "x" ] ; then
    printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   $INFO ${ERRNO[3]} "${DESCR[3]}" "$COMMAND"

  elif [ "xRebuilding" = "x$COMMAND" ] ; then
    printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   $ERROR ${ERRNO[4]} "${DESCR[4]}" "$COMMAND"
  else
    printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   $ERROR ${ERRNO[5]} "${DESCR[5]}" "$COMMAND LD:$LDID slot: $xSLOT"
  fi
}


if [ ! -x $HPTOOL ] ; then
  printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   $ERROR ${ERRNO[6]} "${DESCR[6]}" $HPTOOL
  exit
fi


for (( i = 0 ;  i < ${#PHYSICALDRIVE[@]} ; i++ )) ; do
  SCRIPTINDEX=$(addOneToIndex $SCRIPTINDEX)
  raiddiskcheck "${PHYSICALDRIVE[$i]}" $SLOT $SCRIPTINDEX
done

for (( i = 0 ;  i < ${#LOGICALDRIVE[@]} ; i++ )) ; do
  SCRIPTINDEX=$(addOneToIndex $SCRIPTINDEX)
  raidlogiccheck "${LOGICALDRIVE[$i]}" $SLOT $SCRIPTINDEX
done
