#!/bin/bash
# reports errors from the server.log once!

# Set default home if not already set.
SYSCHECK_HOME=${SYSCHECK_HOME:-"/usr/local/syscheck"}

## Import common definitions ##
. $SYSCHECK_HOME/resources.sh

SCRIPTID=20

getlangfiles $SCRIPTID
getconfig $SCRIPTID

EEL_ERRNO_1=${SCRIPTID}01
EEL_ERRNO_2=${SCRIPTID}02
EEL_ERRNO_3=${SCRIPTID}03

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
    printlogmess $WARN $EEL_ERRNO_3 "$EEL_DESCR_3"  $EEL_SERVER_LOG_FILE   
    exit
fi

NEWERRORS=`${SYSCHECK_HOME}/lib/tail_errors_from_ejbca_log.pl 2>/dev/null`

if [ "x$NEWERRORS" = "x" ]; then
    printlogmess $INFO $EEL_ERRNO_1 "$EEL_DESCR_1"
else
    SHORTMESS=`echo $NEWERRORS | perl -ane 'm/Comment : (.*)/, print "$1\n"'`
    printlogmess $ERROR $EEL_ERRNO_2 "$EEL_DESCR_2" "$SHORTMESS" 
fi

