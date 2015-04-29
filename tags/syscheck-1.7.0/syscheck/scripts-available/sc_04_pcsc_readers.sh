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

SCRIPTID=04

# Index is used to uniquely identify one test done by the script (a harddrive, crl or cert)
SCRIPTINDEX=00


getlangfiles $SCRIPTID
getconfig $SCRIPTID


ERRNO_1=01
ERRNO_2=02
ERRNO_3=03

# help
if [ "x$1" = "x--help" ] ; then
    echo "$0 $HELP"
    echo "$ERRNO_1/$DESCR_1 - $HELP_1"
    echo "$ERRNO_2/$DESCR_2 - $HELP_2"
    echo "$ERRNO_3/$DESCR_3 - $HELP_3"
    exit
elif [ "x$1" = "x-s" -o  "x$1" = "x--screen"  ] ; then
    PRINTTOSCREEN=1
fi

CMD=`$SYSCHECK_HOME/lib/list_reader.pl 2>&1`

ERRCHK=`echo $CMD| grep "locate Chipcard/PCSC.pm" ` 
if [ "x$ERRCHK" != "x" ] ; then
	printlogmess ${SCRIPTID} ${SCRIPTINDEX} $WARN $ERRNO_3 "$DESCR_3" "$CMD"
	exit
fi

STATUS=`echo $CMD | perl -ane 'm/Number\ of\ attatched\ readers:\ (\d+)/gio, print $1'`


SCRIPTINDEX=$(addOneToIndex $SCRIPTINDEX)
if [ "$PCSC_NUMBER_OF_READERS" = "$STATUS" ] ; then     
        printlogmess ${SCRIPTID} ${SCRIPTINDEX}   $INFO $ERRNO_1 "$DESCR_1" "$STATUS" 
	
else

        printlogmess ${SCRIPTID} ${SCRIPTINDEX}   $ERROR $ERRNO_2 "$DESCR_2" "$STATUS"
fi

