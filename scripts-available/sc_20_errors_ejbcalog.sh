#!/bin/bash
# reports errors from the server.log once!

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
SCRIPTID=20

# Index is used to uniquely identify one test done by the script (a harddrive, crl or cert)
SCRIPTINDEX=00


getlangfiles $SCRIPTID
getconfig $SCRIPTID

EEL_ERRNO_1=01
EEL_ERRNO_2=02
EEL_ERRNO_3=03

# help
if [ "x$1" = "x--help" ] ; then
    echo "$0 $EEL_HELP"
    echo "$EEL_ERRNO_1/$EEL_DESCR_1 - $EEL_HELP_1"
    echo "$EEL_ERRNO_2/$EEL_DESCR_2 - $EEL_HELP_2"
    echo "$EEL_ERRNO_3/$EEL_DESCR_3 - $EEL_HELP_3"
    exit
elif [ "x$1" = "x-s" -o  "x$1" = "x--screen"  ] ; then
    PRINTTOSCREEN=1
fi

if [ ! -f $EEL_SERVER_LOG_FILE ] ; then
    printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   $WARN $EEL_ERRNO_3 "$EEL_DESCR_3"  $EEL_SERVER_LOG_FILE   
    exit
fi

SCRIPTINDEX=$(addOneToIndex $SCRIPTINDEX)

export EEL_SERVER_LOG_FILE
export EEL_SERVER_LOG_LASTPOSITION

NEWERRORS=`${SYSCHECK_HOME}/lib/tail_errors_from_ejbca_log.pl 2>/dev/null`

if [ "x$NEWERRORS" = "x" ]; then
    printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   $INFO $EEL_ERRNO_1 "$EEL_DESCR_1"
else
    SHORTMESS=`echo $NEWERRORS | perl -ane 'm/Comment : (.*)/, print "$1\n"'`
    printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   $ERROR $EEL_ERRNO_2 "$EEL_DESCR_2" "$SHORTMESS" 
fi

