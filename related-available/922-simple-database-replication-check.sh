#!/bin/bash

# 1. First check if SYSCHECK_HOME is set then use that
if [ "x${SYSCHECK_HOME}" = "x" ] ; then
# 2. Check if /etc/syscheck.conf exists then source that (put SYSCHECK_HOME=/path/to/syscheck in ther)
    if [ -e /etc/syscheck.conf ] ; then
	source /etc/syscheck.conf
    else
# 3. last resort use default path
	SYSCHECK_HOME="/opt/syscheck"
    fi
fi

if [ ! -f ${SYSCHECK_HOME}/syscheck.sh ] ; then echo "$0: Can't find syscheck.sh in SYSCHECK_HOME ($SYSCHECK_HOME)" ;exit ; fi

## Import common definitions ##
. $SYSCHECK_HOME/config/related-scripts.conf

# scriptname used to map and explain scripts in icinga and other
SCRIPTNAME=db_replication_check

# uniq ID of script (please use in the name of this file also for convinice for finding next availavle number)
SCRIPTID=922

# Index is used to uniquely identify one test done by the script (a harddrive, crl or cert)
SCRIPTINDEX=00

getlangfiles $SCRIPTID
getconfig $SCRIPTID

ERRNO_1="${SCRIPTID}1"
ERRNO_2="${SCRIPTID}2"
ERRNO_3="${SCRIPTID}3"
ERRNO_4="${SCRIPTID}4"

### end config ###

PRINTTOSCREEN=1
if [ "x$1" = "x-h" -o "x$1" = "x--help" ] ; then
        echo "$HELP"
        echo "$ERRNO_1/$DESCR_1 - $HELP_1"
        echo "$ERRNO_2/$DESCR_2 - $HELP_2"
        echo "$ERRNO_3/$DESCR_3 - $HELP_3"
        echo "$ERRNO_4/$DESCR_4 - $HELP_4"
        echo "${SCREEN_HELP}"
        exit
elif [ "x$1" = "x-s" -o  "x$1" = "x--screen" -o \
    "x$2" = "x-s" -o  "x$2" = "x--screen"   ] ; then
    PRINTTOSCREEN=1
fi


mkdir -p "$SYSCHECK_HOME/tmp/"

OUTFILE="$SYSCHECK_HOME/tmp/tmp_create-test-table.sql"

echo "USE $DB_NAME;" > $OUTFILE
echo 'DROP TABLE IF EXISTS `relatedtest`;' >> $OUTFILE
echo "CREATE TABLE relatedtest (value INT);" >> $OUTFILE
echo "INSERT INTO relatedtest SET value='1';"  >> $OUTFILE

$MYSQL_BIN $DB_NAME -u root --password=$MYSQLROOT_PASSWORD < $OUTFILE

rm $OUTFILE
newval=`perl -e 'print time'`
echo "delete from relatedtest"                   | $MYSQL_BIN $DB_NAME -u ${DB_USER} --password=${DB_PASSWORD}
echo "insert into relatedtest set value=$newval" | $MYSQL_BIN $DB_NAME -u ${DB_USER} --password=${DB_PASSWORD}

sleep 1

valhost1=`echo "SELECT value from relatedtest;" | $MYSQL_BIN $DB_NAME -h $HOSTNAME_NODE1 -u ${DB_USER} --password=${DB_PASSWORD} 2>/dev/null`

valhost2=`echo "SELECT value from relatedtest;" | $MYSQL_BIN $DB_NAME -h $HOSTNAME_NODE2 -u ${DB_USER} --password=${DB_PASSWORD} 2>/dev/null`

if [ "x$valhost1" != "x" ] ; then

	if [ "x$valhost2" != "x" ] ; then
		if [ "x$valhost1" = "x$valhost2" ] ; then
			#ok
			printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   $LEVEL_1 $ERRNO_1 "$DESCR_1"
		else
			#failed, not the same values
			printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   $LEVEL_2 $ERRNO_2 "$DESCR_2" "$valhost1" "$valhost2"
		fi
	else
		#failed, no value from $valhost2
		printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   $LEVEL_3 $ERRNO_3 "$DESCR_3" "$valhost2"
	fi

else
	#failed, no value from $valhost1
	printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   $LEVEL_4 $ERRNO_4 "$DESCR_4" "$valhost1"
fi
