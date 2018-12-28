#!/bin/bash

SYSCHECK_HOME="${SYSCHECK_HOME:-/opt/syscheck}" # use default if  unset
if [ ! -f ${SYSCHECK_HOME}/syscheck.sh ] ; then
  echo "Can't find $SYSCHECK_HOME/syscheck.sh"
  exit
fi

if [ ! -f ${SYSCHECK_HOME}/syscheck.sh ] ; then echo "Can't find $SYSCHECK_HOME/syscheck.sh" ;exit ; fi

## Import common definitions ##
source $SYSCHECK_HOME/config/syscheck-scripts.conf

# uniq ID of script (please use in the name of this file also for convinice for finding next availavle number)
SCRIPTID=34

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

checkredis () {
        SCRIPTINDEX=$1
        if [ "x${SCRIPTINDEX}" = "x" ] ; then
                        printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   $ERROR ${ERRNO[3]} "${DESCR[3]}" "SCRIPTINDEX not sent"
                        return
        fi

        REDIS_IP=$2
        if [ "x${REDIS_IP}" = "x" ] ; then
                        printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   $ERROR ${ERRNO[3]} "${DESCR[3]}" "REDIS_IP not sent"
                        return
        fi
        REDIS_PORT=$3
        if [ "x${REDIS_PORT}" = "x" ] ; then
                        printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   $ERROR ${ERRNO[3]} "${DESCR[3]}" "REDIS_PORT not sent"
                        return
        fi
        REDIS_PW=$4
        if [ "x${REDIS_PW}" = "x" ] ; then
                        printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   $ERROR ${ERRNO[3]} "${DESCR[3]}" "REDIS_PW not sent"
                        return
        fi


        OUTPUT=$($REDISCLI -h $REDIS_IP -p $REDIS_PORT -a $REDIS_PW ping 2>&1 |grep PONG )

        if [ "x$OUTPUT" = "xPONG" ]; then
                printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX} $INFO ${ERRNO[1]} "${DESCR[1]}" "$REDIS_IP" "$REDIS_PORT" "$OUTPUT"
        else
                printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX} $ERROR ${ERRNO[2]} "${DESCR[2]}" "$REDIS_IP" "$REDIS_PORT" "$OUTPUT"
        fi
}


if [ x"$REDISCLI" = "x" ] ; then
	printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   $ERROR ${ERRNO[4]} "${DESCR[4]}"
	exit
fi





for (( i = 0 ;  i < ${#REDIS_IP[@]} ; i++ )) ; do
	SCRIPTINDEX=$(addOneToIndex $SCRIPTINDEX)
	checkredis $SCRIPTINDEX "${REDIS_IP[$i]}" ${REDIS_PORT[$i]} ${REDIS_PW[$i]}
done
