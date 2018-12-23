#!/bin/bash

# 1. First check if SYSCHECK_HOME is set then use that
if [ "x${SYSCHECK_HOME}" = "x" ] ; then
# 2. Check if /etc/syscheck.conf exists then source that (put SYSCHECK_HOME=/path/to/syscheck in ther)
    if [ -e /etc/syscheck.conf ] ; then
	source /etc/syscheck.conf
    else
# 3. last resort use default path
	SYSCHECK_HOME="/opt/syscheck"
    fi
fi

if [ ! -f ${SYSCHECK_HOME}/syscheck.sh ] ; then echo "$0: Can't find syscheck.sh in SYSCHECK_HOME ($SYSCHECK_HOME)" ;exit ; fi

## Import common definitions ##
source $SYSCHECK_HOME/config/related-scripts.conf

SCRIPTNAME=send_result_as_message

# uniq ID of script (please use in the name of this file also for convinice for finding next availavle number)
SCRIPTID=932

SCRIPTINDEX=00

getlangfiles $SCRIPTID
getconfig $SCRIPTID

ERRNO_1="${SCRIPTID}1"
ERRNO_2="${SCRIPTID}2"

### end config ###

PRINTTOSCREEN=0
if [ "x$1" = "x-h" -o "x$1" = "x--help" ] ; then
	echo "$HELP"
	echo "$ERRNO_1/$DESCR_1 - $HELP_1"
	echo "$ERRNO_2/$DESCR_2 - $HELP_2"
	echo "${SCREEN_HELP}"
	exit
elif [ "x$1" = "x-s" -o  "x$1" = "x--screen" -o \
    "x$2" = "x-s" -o  "x$2" = "x--screen"   ] ; then
    PRINTTOSCREEN=1
fi 



for (( j=0; j < ${#SEND_MSG_COMMAND[@]} ; j++ )){
	printtoscreen "Sending status as message with: ${SEND_MSG_COMMAND[$j]} ${SEND_MSG_FILE[$j]}"
	SCRIPTINDEX=$(addOneToIndex $SCRIPTINDEX)
	SENDRES=$(${SEND_MSG_COMMAND[$j]} -c ${SEND_MSG_CONFIG[$j]} -m ${SEND_MSG_FILE[$j]} | perl -ane 's/\n//,print')
	if [ $? -ne 0 ] ; then
      		printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   $ERROR $ERRNO_2 "$DESCR_2" "${SEND_MSG_COMMAND[$j]} ${SEND_MSG_FILE[$j]}" "result: ${SENDRES}"
	else
		printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   $INFO $ERRNO_1 "$DESCR_1" "${SEND_MSG_COMMAND[$j]} ${SEND_MSG_FILE[$j]}" "result: ${SENDRES}"
	fi
}


