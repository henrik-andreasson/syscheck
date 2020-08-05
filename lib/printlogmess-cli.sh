#!/bin/bash

SYSCHECK_HOME="${SYSCHECK_HOME:-/opt/syscheck}" # use default if  unset
if [ ! -f ${SYSCHECK_HOME}/syscheck.sh ] ; then
  echo "Can't find $SYSCHECK_HOME/syscheck.sh"
  exit
fi

if [ ! -f ${SYSCHECK_HOME}/syscheck.sh ] ; then echo "Can't find $SYSCHECK_HOME/syscheck.sh" ;exit ; fi

## Import common definitions ##
source $SYSCHECK_HOME/config/common.conf

# source libsycheck
source ${SYSCHECK_HOME}/lib/libsyscheck.sh

# use the printlog function
source $SYSCHECK_HOME/lib/printlogmess.sh



INPUTARGS=`/usr/bin/getopt --options "n:i:x:l:e:d:1:2:3:4:5:6:7:8:9"  -- "$@"`
if [ $? != 0 ] ; then schelp ; fi
eval set -- "$INPUTARGS"

while true; do
  case "$1" in
    -n ) SCRIPTNAME=$2; shift 2;;
    -i ) SCRIPTID=$2; shift 2;;
    -x ) SCRIPTINDEX=$2; shift 2;;
    -l ) LEVEL=$2; shift 2;;
    -e ) ERRNO=$2; shift 2;;
    -d ) DESCR=$2; shift 2;;
    -1 ) ARG1=$2 ; shift 2;;
    -2 ) ARG2=$2 ; shift 2;;
    -3 ) ARG3=$2 ; shift 2;;
    -4 ) ARG4=$2 ; shift 2;;
    -5 ) ARG5=$2 ; shift 2;;
    -6 ) ARG6=$2 ; shift 2;;
    --) break;;
  esac
done

if [ "x${LEVEL}" = "xI" ] ;then
  SYSLOGLEVEL="info"
  LONGLEVEL="INFO"
elif [ "x${LEVEL}" = "xW" ] ;then
  SYSLOGLEVEL="warning"
  LONGLEVEL="WARNING"
elif [ "x${LEVEL}" = "xE" ] ;then
  SYSLOGLEVEL="err"
  LONGLEVEL="ERROR"
else
  echo "wrong type of LEVEL (${LEVEL})"
  exit;
fi

if [ "x$SCRIPTNAME" = "x" ] ;then
  echo "scriptname must be passed to printlogmess"
  exit
fi

if [ "x$SCRIPTID" = "x" ] ;then
  echo "scriptid must be passed to printlogmess"
  exit
fi

if [ "x$SCRIPTINDEX" = "x" ] ;then
  echo "scriptindex must be passed to printlogmess"
  exit
fi
if [ "x$DESCR" = "x" ] ;then
  echo "DESCR must be passed to printlogmess"
  exit
fi



printlogmess -n "$SCRIPTNAME" -i "$SCRIPTID" -x "$SCRIPTINDEX" -d "$DESCR" -l "$LEVEL" -e "$ERRNO" -1 "$ARG1" -2 "$ARG2" -3 "$SRG3" -4 "$ARG4" -5 "$ARG5" -6 "$ARG6"
