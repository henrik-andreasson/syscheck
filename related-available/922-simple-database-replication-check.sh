#!/bin/bash

SYSCHECK_HOME="${SYSCHECK_HOME:-/opt/syscheck}" # use default if  unset
if [ ! -f ${SYSCHECK_HOME}/syscheck.sh ] ; then
  echo "Can't find $SYSCHECK_HOME/syscheck.sh"
  exit
fi

if [ ! -f ${SYSCHECK_HOME}/syscheck.sh ] ; then echo "Can't find $SYSCHECK_HOME/syscheck.sh" ;exit ; fi

# Import common resources
source $SYSCHECK_HOME/config/related-scripts.conf

# script name, used when integrating with nagios/icinga
SCRIPTNAME=db_replication_check

# uniq ID of script (please use in the name of this file also for convinice for finding next availavle number)
SCRIPTID=922

# how many info/warn/error messages
NO_OF_ERR=4
initscript $SCRIPTID $NO_OF_ERR
getconfig "mariadb"


# get command line arguments
INPUTARGS=`/usr/bin/getopt --options "hsv" --long "help,screen,verbose" -- "$@"`
if [ $? != 0 ] ; then schelp ; fi
#echo "TEMP: >$TEMP<"
eval set -- "$INPUTARGS"

while true; do
  case "$1" in
    -s|--screen  ) PRINTTOSCREEN=1; shift;;
    -v|--verbose ) PRINTVERBOSESCREEN=1 ; shift;;
    -h|--help )   schelp;exit;shift;;
    --) break;;
  esac
done

# main part of script

mkdir -p "$SYSCHECK_HOME/tmp/"

OUTFILE="$SYSCHECK_HOME/tmp/tmp_create-test-table.sql"

echo "USE $DB_NAME;" > $OUTFILE
echo 'DROP TABLE IF EXISTS `relatedtest`;' >> $OUTFILE
echo "CREATE TABLE relatedtest (value INT);" >> $OUTFILE
echo "INSERT INTO relatedtest SET value='1';"  >> $OUTFILE

$MYSQL_BIN $DB_NAME -u root --password=$MYSQLROOT_PASSWORD < $OUTFILE

rm $OUTFILE
newval=$(date +"%s")
echo "delete from relatedtest"                   | $MYSQL_BIN $DB_NAME -u ${DB_USER} --password=${DB_PASSWORD}
echo "insert into relatedtest set value=$newval" | $MYSQL_BIN $DB_NAME -u ${DB_USER} --password=${DB_PASSWORD}

sleep 1

valhost1=`echo "SELECT value from relatedtest;" | $MYSQL_BIN $DB_NAME -h $HOSTNAME_NODE1 -u ${DB_USER} --password=${DB_PASSWORD} 2>/dev/null`

valhost2=`echo "SELECT value from relatedtest;" | $MYSQL_BIN $DB_NAME -h $HOSTNAME_NODE2 -u ${DB_USER} --password=${DB_PASSWORD} 2>/dev/null`

if [ "x$valhost1" != "x" ] ; then

	if [ "x$valhost2" != "x" ] ; then
		if [ "x$valhost1" = "x$valhost2" ] ; then
			#ok
			printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX}  $LEVEL_1 ${ERRNO[1]} "${DESCR[1]}"
		else
			#failed, not the same values
			printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX}  $LEVEL_2 ${ERRNO[2]} "${DESCR[2]}" "$valhost1" "$valhost2"
		fi
	else
		#failed, no value from $valhost2
		printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX}  $LEVEL_3 ${ERRNO[3]} "${DESCR[3]}" "$valhost2"
	fi

else
	#failed, no value from $valhost1
	printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX}  $LEVEL_4 ${ERRNO[4]} "${DESCR[4]}" "$valhost1"
fi
