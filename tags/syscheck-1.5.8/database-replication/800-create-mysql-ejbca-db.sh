#!/bin/sh

#Scripts that creates replication privilegdes for the slave db to the master.

# Set default home if not already set.
SYSCHECK_HOME=${SYSCHECK_HOME:-"/usr/local/syscheck"}

## Import common definitions ##
. $SYSCHECK_HOME/resources.sh

SCRIPTID=800
getlangfiles $SCRIPTID || exit 1;
getconfig $SCRIPTID || exit 1;

ERRNO_1="${SCRIPTID}1"
ERRNO_2="${SCRIPTID}2"
ERRNO_3="${SCRIPTID}3"




schelp () {
        echo "$HELP"
        echo "$ERRNO_1/$DESCR_1 - $HELP_1"
        echo "$ERRNO_2/$DESCR_2 - $HELP_2"
        echo "$ERRNO_3/$DESCR_3 - $HELP_3"
        echo "${SCREEN_HELP}"
        exit
}


PRINTTOSCREEN=1

if [ "x$1" = "x-h" -o "x$1" = "x--help" ] ; then
	schelp
elif [ "x$1" = "x-s" -o  "x$1" = "x--screen" -o \
    "x$2" = "x-s" -o  "x$2" = "x--screen"   ] ; then
	PRINTTOSCREEN=1
elif [ "x$1" = "x-q" -o  "x$1" = "x--quiet" -o \
    "x$2" = "x-q" -o  "x$2" = "x--quiet"   ] ; then
	PRINTTOSCREEN=0
fi 

echo "select * from UserData" | $MYSQL_BIN $DB_NAME -u root --password="$MYSQLROOT_PASSWORD" >/dev/null 2>/dev/null
if [ $? -ne 0 ] ; then
	$MYSQLADMIN_BIN create $DB_NAME -u root --password="$MYSQLROOT_PASSWORD" 
	if [ $? -ne 0 ] ; then
		printlogmess $LEVEL_3 $ERRNO_3 "$DESCR_3"
	else
		printlogmess $LEVEL_1 $ERRNO_1 "$DESCR_1"
	fi
else
	printlogmess $LEVEL_2 $ERRNO_2 "$DESCR_2"
fi


