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

# number of errors in summary
ERRORNUM=0

# how many info/warn/error messages
NO_OF_ERR=6
initscript $SCRIPTID $NO_OF_ERR

default_script_getopt $*

# main part of script


raiddiskcheck () {
  DISCID="$1"
  xSLOT="$2"
  SCRIPTINDEX=$3

  COMMAND=$(echo "controller slot=${xSLOT} pd all show" | $HPTOOL | grep "$DISCID")
  STATUS=$(echo $COMMAND | grep "OK")
  if [ "x$STATUS" != "x" ] ; then
    printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $INFO  -e ${ERRNO[1]} -d "${DESCR[1]}" -1 "$COMMAND"
  else
    printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[2]} -d "${DESCR[2]}" -1 "$COMMAND disc: $DISCID slot: $xSLOT"
    (( ERRORNUM++ )) || true
  fi
}


raidlogiccheck () {
  LDID="$1"
  xSLOT="$2"
  SCRIPTINDEX=$3

  COMMAND=`echo "controller slot=${xSLOT} ld all show" | $HPTOOL | grep "$LDID"`
  STATUS=`echo $COMMAND | grep "OK"`

  if [ "x$STATUS" != "x" ] ; then
    printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX}  -l $INFO -e ${ERRNO[3]} -d "${DESCR[3]}" -1 "$COMMAND"

  elif [ "xRebuilding" = "x$COMMAND" ] ; then
    printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX}  -l $ERROR -e ${ERRNO[4]} -d "${DESCR[4]}" -1 "$COMMAND"
    (( ERRORNUM++ )) || true
  else
    printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX}  -l $ERROR -e ${ERRNO[5]} -d "${DESCR[5]}" -1 "$COMMAND LD:$LDID slot: $xSLOT"
    (( ERRORNUM++ )) || true
  fi
}


if [ ! -x $HPTOOL ] ; then
  printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX}  -l $ERROR -e ${ERRNO[6]} -d "${DESCR[6]}" -1 "$HPTOOL"
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

# send the summary message (00)
SCRIPTINDEX=00
if [ "$ERRORNUM" -gt 0 ] ; then
    printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[2]} -d "${DESCR[8]}" -1 "number of errors detected: ${ERRORNUM}"
else
    printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $INFO  -e ${ERRNO[1]} -d "${DESCR[7]}"
fi
