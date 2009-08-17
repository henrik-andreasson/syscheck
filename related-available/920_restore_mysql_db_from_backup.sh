#!/bin/bash

# Set default home if not already set.
SYSCHECK_HOME=${SYSCHECK_HOME:-"/usr/local/syscheck"}

# Import common resources
. $SYSCHECK_HOME/resources.sh

SCRIPTID=920

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
	printlogmess $ERROR $DESCR_4 "$BAK_DESCR_4"
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
	printlogmess $LEVEL_1 $ERRNO_1 "$DESCR_1"
	exit
fi 


echo "restoring the db from $1"
zcat $1 | $MYSQL_BIN ${DB_NAME} -u root --password="$MYSQLROOT_PASSWORD" 
if [ $? -eq 0 ] ; then
	printlogmess $LEVEL_2 $ERRNO_2 "$DESCR_2" "$1"
else
	printlogmess $LEVEL_3 $ERRNO_3 "$DESCR_3" "$1" "${MYSQLBACKUPFULLFILENAME}.gz"
fi

