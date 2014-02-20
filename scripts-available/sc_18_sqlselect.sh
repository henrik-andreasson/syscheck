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

ERRNO_1=${SCRIPTID}01
ERRNO_2=${SCRIPTID}02
ERRNO_3=${SCRIPTID}03

# help
if [ "x$1" = "x--help" ] ; then
    echo "$0 $HELP"
    echo "$ERRNO_1/$DESCR_1 - $HELP_1"
    echo "$ERRNO_2/$DESCR_2 - $HELP_2"
    exit
elif [ "x$1" = "x-s" -o  "x$1" = "x--screen"  ] ; then
    PRINTTOSCREEN=1
fi

status=`echo "SELECT * FROM $DB_TEST_TABLE LIMIT 1"|$MYSQL_BIN $DB_NAME -u root --password=$MYSQLROOT_PASSWORD 2>&1 > /dev/null`

if [ $? -ne 0 ] ; then
    printlogmess $ERROR $ERRNO_2 "$DESCR_2" 
    exit 3
else
    printlogmess $INFO $ERRNO_1 "$DESCR_1" 
fi

