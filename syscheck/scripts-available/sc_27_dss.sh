#!/bin/sh 

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

SCRIPTID=27

getlangfiles $SCRIPTID
getconfig $SCRIPTID

ERRNO_1=${SCRIPTID}01
ERRNO_2=${SCRIPTID}02
ERRNO_3=${SCRIPTID}03
ERRNO_4=${SCRIPTID}04

# help
if [ "x$1" = "x--help" ] ; then
    echo "$0 $HELP"
    echo "$ERRNO_1/$DSS_DESCR_1 - $DSS_HELP_1"
    echo "$ERRNO_2/$DSS_DESCR_2 - $DSS_HELP_2"
    echo "$ERRNO_3/$DSS_DESCR_3 - $DSS_HELP_3"
    echo "$ERRNO_4/$DSS_DESCR_4 - $DSS_HELP_4"
    exit
elif [ "x$1" = "x-s" -o  "x$1" = "x--screen"  ] ; then
    PRINTTOSCREEN=1
fi


if [ ! -f $SIGNSERVER_HOME/bin/signserver.sh ] ; then 
    printlogmess $ERROR $ERRNO_4 "$DSS_DESCR_4"
    exit
fi
cd $SIGNSERVER_HOME
OUTPUT=`$SIGNSERVER_HOME/bin/signserver.sh getstatus all 1 | grep "Status : Active" | wc -l` 


if [ "$OUTPUT" = "2" ] ; then
	printlogmess $INFO $ERRNO_1 "$DSS_DESCR_1"  
elif [ "$OUTPUT" = "1" ] ; then
	printlogmess $WARNING $ERRNO_2 "$DSS_DESCR_2"  
else
	printlogmess $ERROR $ERRNO_3 "$DSS_DESCR_3"
fi

