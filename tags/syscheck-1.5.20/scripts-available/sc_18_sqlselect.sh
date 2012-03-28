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

SCRIPTID=18

getlangfiles $SCRIPTID
getconfig $SCRIPTID

SQLSELECT_ERRNO_1=${SCRIPTID}01
SQLSELECT_ERRNO_2=${SCRIPTID}02
SQLSELECT_ERRNO_3=${SCRIPTID}03

# help
if [ "x$1" = "x--help" ] ; then
    echo "$0 $SQLSELECT_HELP"
    echo "$SQLSELECT_ERRNO_1/$SQLSELECT_DESCR_1 - $SQLSELECT_HELP_1"
    echo "$SQLSELECT_ERRNO_2/$SQLSELECT_DESCR_2 - $SQLSELECT_HELP_2"
    exit
elif [ "x$1" = "x-s" -o  "x$1" = "x--screen"  ] ; then
    PRINTTOSCREEN=1
fi



if [ $? -ne 0 ] ; then
    printlogmess $ERROR $SQLSELECT_ERRNO_2 "$SQLSELECT_DESCR_2"  
    exit 3
else
    printlogmess $INFO $SQLSELECT_ERRNO_1 "$SQLSELECT_DESCR_1"
fi

