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




# Import common resources
. $SYSCHECK_HOME/config/related-scripts.conf

SCRIPTID=920
SCRIPTINDEX=00

getlangfiles $SCRIPTID 
getconfig $SCRIPTID

ERRNO_1="${SCRIPTID}1"
ERRNO_2="${SCRIPTID}2"
ERRNO_3="${SCRIPTID}3"

PRINTTOSCREEN=0
if [ "x$1" = "x-h" -o "x$1" = "x--help" ] ; then
	echo "$HELP"
	echo "$ERRNO_1/$DESCR_1 - $HELP_1"
	echo "$ERRNO_2/$DESCR_2 - $HELP_2"
	echo "$ERRNO_3/$DESCR_3 - $HELP_3"
	echo "${SCREEN_HELP}"
	exit
elif [ "x$1" = "x-s" -o  "x$1" = "x--screen" -o \
    "x$2" = "x-s" -o  "x$2" = "x--screen"   ] ; then
    PRINTTOSCREEN=1
    shift
fi

if [ "x$1" = "x" ] ; then
	printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   $ERROR $DESCR_4 "$BAK_DESCR_4"
	exit
fi

echo "enter 'im-really-sure' (without the '-') to continue or ctrl-c to abort"
read a
if [ "x$a" != "xim really sure" ] ; then
        echo "ok probably wise choice, exiting"
        exit
fi


echo "now we'll backup the current database before we restore the one you specified" 

$SYSCHECK_HOME/related-available/904_make_mysql_db_backup.sh -s

if [ $? -ne 0 ] ; then
	printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   $LEVEL_1 $ERRNO_1 "$DESCR_1"
	exit
fi 


echo "restoring the db from $1"
zcat $1 | $MYSQL_BIN ${DB_NAME} -u root --password="$MYSQLROOT_PASSWORD" 
if [ $? -eq 0 ] ; then
	printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   $LEVEL_2 $ERRNO_2 "$DESCR_2" "$1"
else
	printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   $LEVEL_3 $ERRNO_3 "$DESCR_3" "$1" "${MYSQLBACKUPFULLFILENAME}.gz"
fi

