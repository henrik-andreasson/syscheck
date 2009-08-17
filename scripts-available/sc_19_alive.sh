#!/bin/bash

set -e 

SYSCHECK_HOME=${SYSCHECK_HOME:-"/usr/local/syscheck"}

# Import common resources
. $SYSCHECK_HOME/resources.sh

SCRIPTID=19
getlangfiles $SCRIPTID
getconfig $SCRIPTID

ERRNO_1=${SCRIPTID}01 # boot (machine start)
ERRNO_2=${SCRIPTID}02 # shutdown (machine stop)
ERRNO_3=${SCRIPTID}03 # server "I'm alive" message

if [ "x$1" = "x--help" ] ; then
    echo "$SCALIVE_HELP"
    echo "$ERRNO_1/$SCALIVE_DESCR_1 - $SCALIVE_HELP_1"
    echo "$ERRNO_2/$SCALIVE_DESCR_2 - $SCALIVE_HELP_2"
    echo "$ERRNO_3/$SCALIVE_DESCR_3 - $SCALIVE_HELP_3"
    echo "${SCREEN_HELP}"
    exit
elif [ "x$1" = "x-s" -o  "x$1" = "x--screen"  ] ; then
    PRINTTOSCREEN=1
fi 


printlogmess $INFO $ERRNO_3 "$SCALIVE_DESCR_3"
