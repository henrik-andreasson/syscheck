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
SCRIPTNAME=redis

# uniq ID of script (please use in the name of this file also for convinice for finding next availavle number)
SCRIPTID=34

# how many info/warn/error messages
NO_OF_ERR=4
initscript $SCRIPTID $NO_OF_ERR

default_script_getopt $*

# main part of script

SCRIPTINDEX=$(addOneToIndex $SCRIPTINDEX)

checkredis () {
        SCRIPTINDEX=$1
        if [ "x${SCRIPTINDEX}" = "x" ] ; then
                        printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[3]} -d "${DESCR[3]}" -1 "SCRIPTINDEX not sent"
                        return
        fi

        REDIS_IP=$2
        if [ "x${REDIS_IP}" = "x" ] ; then
                        printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[3]} -d "${DESCR[3]}" -1 "REDIS_IP not sent"
                        return
        fi
        REDIS_PORT=$3
        if [ "x${REDIS_PORT}" = "x" ] ; then
                        printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[3]} -d "${DESCR[3]}" -1 "REDIS_PORT not sent"
                        return
        fi
        REDIS_PW=$4
        if [ "x${REDIS_PW}" = "x" ] ; then
                        printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[3]} -d "${DESCR[3]}" -1 "REDIS_PW not sent"
                        return
        fi


        OUTPUT=$($REDISCLI -h $REDIS_IP -p $REDIS_PORT -a $REDIS_PW ping 2>&1 |grep PONG )

        if [ "x$OUTPUT" = "xPONG" ]; then
                printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $INFO  -e ${ERRNO[1]} -d "${DESCR[1]}" -1 "$REDIS_IP" -2 "$REDIS_PORT" -3 "$OUTPUT"
        else
                printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[2]} -d "${DESCR[2]}" -1 "$REDIS_IP" -2 "$REDIS_PORT" -3 "$OUTPUT"
        fi
}


if [ x"$REDISCLI" = "x" ] ; then
	printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[4]} -d "${DESCR[4]}"
	exit
fi





for (( i = 0 ;  i < ${#REDIS_IP[@]} ; i++ )) ; do
	SCRIPTINDEX=$(addOneToIndex $SCRIPTINDEX)
	checkredis $SCRIPTINDEX "${REDIS_IP[$i]}" ${REDIS_PORT[$i]} ${REDIS_PW[$i]}
done
