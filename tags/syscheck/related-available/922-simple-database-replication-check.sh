#!/bin/sh

#Script that creates a test table on the master database.
#the table is created in the EJBCA database and contains a int columnt test
#with the value on 1.
#

# Set default home if not already set.
SYSCHECK_HOME=${SYSCHECK_HOME:-"/usr/local/syscheck"}

## Import common definitions ##
. $SYSCHECK_HOME/resources.sh

# uniq ID of script (please use in the name of this file also for convinice for finding next availavle number)
SCRIPTID=922

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
echo "delete from relatedtest" | $MYSQL_BIN $DB_NAME -h $HOSTNAME_NODE1 -u ${DB_USER} --password=${DB_PASSWORD}
echo "insert into relatedtest set value=$newval" | $MYSQL_BIN $DB_NAME -h $HOSTNAME_NODE1 -u ${DB_USER} --password=${DB_PASSWORD}

sleep 1

valhost1=`echo "SELECT value from relatedtest;" | $MYSQL_BIN $DB_NAME -h $HOSTNAME_NODE1 -u ${DB_USER} --password=${DB_PASSWORD} 2>/dev/null`

valhost2=`echo "SELECT value from relatedtest;" | $MYSQL_BIN $DB_NAME -h $HOSTNAME_NODE2 -u ${DB_USER} --password=${DB_PASSWORD} 2>/dev/null`

if [ "x$valhost1" != "x" ] ; then

	if [ "x$valhost2" != "x" ] ; then
		if [ "x$valhost1" = "x$valhost2" ] ; then
			#ok
			printlogmess $LEVEL_1 $ERRNO_1 "$DESCR_1"
		else
			#failed, not the same values
			printlogmess $LEVEL_2 $ERRNO_2 "$DESCR_2" "$valhost1" "$valhost2"
		fi
	else
		#failed, no value from $valhost2
		printlogmess $LEVEL_3 $ERRNO_3 "$DESCR_3" "$valhost2"
	fi

else
	#failed, no value from $valhost1
	printlogmess $LEVEL_4 $ERRNO_4 "$DESCR_4" "$valhost1"
fi
