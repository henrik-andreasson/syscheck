#!/bin/bash

# Set SYSCHECK_HOME if not already set.

# 1. First check if SYSCHECK_HOME is set then use that
if [ "x${SYSCHECK_HOME}" = "x" ] ; then
# 2. Check if /etc/syscheck.conf exists then source that (put SYSCHECK_HOME=/path/to/syscheck in ther)
    if [ -e /etc/syscheck.conf ] ; then
        source /etc/syscheck.conf
    else
# 3. last resort use default path
        SYSCHECK_HOME="/usr/local/syscheck"
    fi
fi

if [ ! -f ${SYSCHECK_HOME}/syscheck.sh ] ; then echo "$0: Can't find syscheck.sh in SYSCHECK_HOME ($SYSCHECK_HOME)" ;exit ; fi




## Import common definitions ##
. $SYSCHECK_HOME/config/syscheck-scripts.conf

# uniq ID of script (please use in the name of this file also for convinice for finding next availavle number)
SCRIPTID=34

# Index is used to uniquely identify one test done by the script (a harddrive, crl or cert)
SCRIPTINDEX=00



getlangfiles $SCRIPTID
getconfig $SCRIPTID

ERRNO_1=01
ERRNO_2=02
ERRNO_3=03
ERRNO_4=04
ERRNO_5=05

if [ "x$1" = "x-h" -o "x$1" = "x--help" ] ; then
        echo "$HELP"
        echo "$ERRNO_1/$DESCR_1 - $HELP_1"
        echo "$ERRNO_2/$DESCR_2 - $HELP_2"
        echo "$ERRNO_3/$DESCR_3 - $HELP_3"
        echo "$ERRNO_4/$DESCR_4 - $HELP_4"
        echo "$ERRNO_5/$DESCR_5 - $HELP_5"
        echo "${SCREEN_HELP}"
        exit
elif [ "x$1" = "x-s" -o  "x$1" = "x--screen"  ] ; then
    PRINTTOSCREEN=1
fi


SCRIPTINDEX=$(addOneToIndex $SCRIPTINDEX)

checkredis () {
        SCRIPTINDEX=$1
        if [ "x${SCRIPTINDEX}" = "x" ] ; then
                        printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   $ERROR $ERRNO_3 "$DESCR_3" "SCRIPTINDEX not sent"
                        return
        fi

        REDIS_IP=$2
        if [ "x${REDIS_IP}" = "x" ] ; then
                        printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   $ERROR $ERRNO_3 "$DESCR_3" "REDIS_IP not sent"
                        return
        fi
        REDIS_PORT=$3
        if [ "x${REDIS_PORT}" = "x" ] ; then
                        printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   $ERROR $ERRNO_3 "$DESCR_3" "REDIS_PORT not sent"
                        return
        fi
        REDIS_PW=$4
        if [ "x${REDIS_PW}" = "x" ] ; then
                        printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   $ERROR $ERRNO_3 "$DESCR_3" "REDIS_PW not sent"
                        return
        fi


        OUTPUT=$($REDISCLI -h $REDIS_IP -p $REDIS_PORT -a $REDIS_PW ping 2>&1 |grep PONG )

        if [ "x$OUTPUT" = "xPONG" ]; then
                printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX} $INFO $ERRNO_1 "$DESCR_1" "$REDIS_IP" "$REDIS_PORT" "$OUTPUT"
        else
                printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX} $ERROR $ERRNO_2 "$DESCR_2" "$REDIS_IP" "$REDIS_PORT" "$OUTPUT"
        fi
}


if [ x"$REDISCLI" = "x" ] ; then
	printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   $ERROR $ERRNO_4 "$DESCR_4"
	exit
fi





for (( i = 0 ;  i < ${#REDIS_IP[@]} ; i++ )) ; do
	SCRIPTINDEX=$(addOneToIndex $SCRIPTINDEX)
	checkredis $SCRIPTINDEX "${REDIS_IP[$i]}" ${REDIS_PORT[$i]} ${REDIS_PW[$i]}
done
