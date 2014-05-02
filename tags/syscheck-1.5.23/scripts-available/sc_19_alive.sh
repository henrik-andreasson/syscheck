#!/bin/bash

set -e 

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



# Import common resources
. $SYSCHECK_HOME/config/syscheck-scripts.conf

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
