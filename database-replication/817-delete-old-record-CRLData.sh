#!/bin/sh
#		 817-delete-old-record-CRLData.sh - Delete old crldata from ejbca db
#
# create a yearly backup
# Create crldata db and table crldatalog from crldata
# Create temp table crldatatmp in ejbca
# Get row number to delete to
# Copy rows before deleting to crldatalog.crldata
# Delete old record from crldata use argument for how many rows to keep, not less then 20
# if ok remove temptable in ejbca
# make backup of crldata db.

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
. $SYSCHECK_HOME/config/database-replication.conf

SCRIPTID=`basename $0|cut -d"-" -f1`
getlangfiles $SCRIPTID || exit 1;
getconfig $SCRIPTID || exit 1;
schelp () {
 echo
        echo "$HELP"
        echo
        echo "${SCRIPTID}1/$DESCR_1 - $HELP_1"
        echo "${SCRIPTID}2/$DESCR_2 - $HELP_2"
        echo "${SCRIPTID}3/$DESCR_3 - $HELP_3"
        echo "${SCRIPTID}4/$DESCR_4 - $HELP_4"
        echo "${SCRIPTID}5/$DESCR_5 - $HELP_5"
        echo "${SCRIPTID}6/$DESCR_6 - $HELP_6"
        echo "${SCRIPTID}7/$DESCR_7 - $HELP_7"
        echo "${SCRIPTID}8/$DESCR_8 - $HELP_8"
        echo "${SCRIPTID}9/$DESCR_9 - $HELP_9"
        echo "${SCRIPTID}10/$DESCR_10 - $HELP_10"
        echo "${SCRIPTID}11/$DESCR_11 - $HELP_11"
        echo "${SCRIPTID}12/$DESCR_12 - $HELP_12"
        echo "${SCRIPTID}13/$DESCR_13 - $HELP_13"
        echo "${SCREEN_HELP}"
        exit
}


PRINTTOSCREEN=0

if [ "x$1" = "x-h" -o "x$1" = "x--help" ] ; then
        schelp
elif [ "x$1" = "x-s" -o  "x$1" = "x--screen" -o \
    "x$2" = "x-s" -o  "x$2" = "x--screen"   ] ; then
        PRINTTOSCREEN=1
elif [ "x$1" = "x-q" -o  "x$1" = "x--quiet" -o \
    "x$2" = "x-q" -o  "x$2" = "x--quiet"   ] ; then
        PRINTTOSCREEN=0
fi

DATAFILE="$SYSCHECK_HOME/var/${SCRIPTID}.out"
OUTFILE="$SYSCHECK_HOME/var/${SCRIPTID}.sql"
ERRFILE="$SYSCHECK_HOME/var/${SCRIPTID}.err"
###############
# Error rutin
Sub_Error(){
if [ $ERR != 0 ]
then
###echo $ERR
echo "error in subrutin $1"
##cat ${ERRFILE}.$1
printlogmess ${LEVEL} ${SCRIPTID}$1 "${DESCR}"
exit $ERR
fi
}
###############
ERR=0
test -z "${ROW_SAVE}" && ERR=10
LEVEL=${LEVEL_10}
DESCR=${DESCR_10}
Sub_Error 10
test ${ROW_SAVE} -lt 5 && ERR=11
LEVEL=${LEVEL_11}
DESCR=${DESCR_11}
Sub_Error 11
###############
# create backup before starting job
if [ ${PRINTTOSCREEN} = 1 ]
then
  echo "$SYSCHECK_HOME/related-enabled/904_make_mysql_db_backup.sh -y -b "
fi
$SYSCHECK_HOME/related-enabled/904_make_mysql_db_backup.sh -y -b 2>${ERRFILE}.12
ERR=$?
LEVEL=${LEVEL_12}
DESCR=${DESCR_12}
Sub_Error 12

##############
# Create database for old crldatarecords
if [ ${PRINTTOSCREEN} = 1 ]
then
echo "CREATE DATABASE IF NOT EXISTS crldata;"
echo "USE CRLDATA;"
echo "CREATE TABLE IF NOT EXISTS CRLDataLog LIKE ejbca.CRLData;" 
echo ""
fi
echo "CREATE DATABASE IF NOT EXISTS crldata;"> $OUTFILE
echo "USE crldata;">> $OUTFILE
echo "CREATE TABLE IF NOT EXISTS CRLDataLog LIKE ejbca.CRLData;" >> $OUTFILE
$MYSQL_BIN $DB_NAME -u root --password=$MYSQLROOT_PASSWORD < $OUTFILE >${ERRFILE}.1
ERR=$?
LEVEL=${LEVEL_1}
DESCR=${DESCR_1}
Sub_Error 1

##############
# Copy table before clean for safty
if [ ${PRINTTOSCREEN} = 1 ]
then
echo "CREATE TABLE IF NOT EXISTS CRLDataTmp LIKE CRLData;"
echo "INSERT INTO CRLDataTmp SELECT * FROM CRLData;"
echo ""
fi
echo "USE $DB_NAME;" > $OUTFILE
echo "CREATE TABLE IF NOT EXISTS CRLDataTmp LIKE CRLData;" >>$OUTFILE
echo "INSERT INTO CRLDataTmp SELECT * FROM CRLData;">>$OUTFILE
$MYSQL_BIN $DB_NAME -u root --password=$MYSQLROOT_PASSWORD < $OUTFILE >${ERRFILE}.2 
ERR=$?
LEVEL=${LEVEL_2}
DESCR=${DESCR_2}
Sub_Error 2

##############
# Get all issuerDN, need to now for deleteing for each issuerDN

if [ ${PRINTTOSCREEN} = 1 ]
then
echo "select distinct issuerDN from CRLData ;"
echo ""
fi
echo "USE $DB_NAME;" > ${OUTFILE}.3
echo "select distinct issuerDN from CRLData;" >> ${OUTFILE}.3
$MYSQL_BIN --skip-column-names $DB_NAME -u root --password=$MYSQLROOT_PASSWORD < ${OUTFILE}.3 >${DATAFILE}
ERR=$?
LEVEL=${LEVEL_3}
DESCR=${DESCR_3}
Sub_Error 3

############t#
# Get number of row to delete to desending from each issuerDN
cat ${DATAFILE}|while read ISSUERDN
do
if [ ${PRINTTOSCREEN} = 1 ]
then
######echo "select cRLNumber from CRLData order by cRLNumber where issuerDN='${ISSUERDN}' and desc Limit ${ROW_SAVE};"
echo "select cRLNumber from CRLData where issuerDN='${ISSUERDN}' order by cRLNumber desc Limit ${ROW_SAVE};"
echo ""
fi
echo "USE $DB_NAME;" > ${OUTFILE}.4
echo "select cRLNumber from CRLData where issuerDN='${ISSUERDN}' order by cRLNumber desc Limit ${ROW_SAVE};" >> ${OUTFILE}.4
ROWNUM=`$MYSQL_BIN $DB_NAME -u ${DB_USER} --password=$DB_PASSWORD < ${OUTFILE}.4 |tail -1`  
ERR=$?
LEVEL=${LEVEL_4}
DESCR=${DESCR_4}
Sub_Error 4

##############
# Copy row to crldata db
if [ ${PRINTTOSCREEN} = 1 ]
then
echo "INSERT INTO crldata.CRLDataLog select * from CRLData where issuerDN=${ISSUERDN} and cRLNumber < ${ROWNUM};"
echo ""
fi
echo "USE $DB_NAME;" > ${OUTFILE}.5
echo "INSERT INTO crldata.CRLDataLog select * from CRLData where issuerDN='${ISSUERDN}' and cRLNumber < ${ROWNUM};" >> ${OUTFILE}.5
$MYSQL_BIN $DB_NAME -u root --password=$MYSQLROOT_PASSWORD < ${OUTFILE}.5
##$MYSQL_BIN $DB_NAME -u root --password=$MYSQLROOT_PASSWORD < ${OUTFILE}.5 >${ERRFILE}.5
ERR=$?
echo $ERR
LEVEL=${LEVEL_5}
DESCR=${DESCR_5}
Sub_Error 5

##############
# Delete row
if [ ${PRINTTOSCREEN} = 1 ]
then
echo "delete from CRLData where  issuerDN=${ISSUERDN} and cRLNumber < ${ROWNUM};"
echo ""
fi
echo "USE $DB_NAME;" > ${OUTFILE}.6
echo "delete from CRLData where issuerDN='${ISSUERDN}' and cRLNumber < ${ROWNUM};" >> ${OUTFILE}.6
$MYSQL_BIN $DB_NAME -u root --password=$MYSQLROOT_PASSWORD < ${OUTFILE}.6  >${ERRFILE}.6
ERR=$?
echo $ERR
LEVEL=${LEVEL_6}
DESCR=${DESCR_6}
Sub_Error 6
done
##############
# Delet temp table
if [ ${PRINTTOSCREEN} = 1 ]
then
echo "DROP TABLE IF EXISTS CRLDataTmp;"
echo ""
fi
echo "USE $DB_NAME;" > ${OUTFILE}.7
echo "DROP TABLE IF EXISTS CRLDataTmp;">>${OUTFILE}.7
$MYSQL_BIN $DB_NAME -u ${DB_USER} --password=$DB_PASSWORD < ${OUTFILE}.7  >${ERRFILE}.7
ERR=$?
LEVEL=${LEVEL_7}
DESCR=${DESCR_7}
Sub_Error 7

##############
# backup of crldata db

MYSQLBACKUPFULLFILENAME="${MYSQLBACKUPDIR}/${SUBDIR_YEARLY}/${MYSQLBACKUPFILE}"
dumpret=$($MYSQLDUMP_BIN -u root --password="${MYSQLROOT_PASSWORD}" crldata 2>&1 > ${MYSQLBACKUPFULLFILENAME} )
ERR=$?
LEVEL=${LEVEL_8}
DESCR=${DESCR_8}
Sub_Error 8
gzip $MYSQLBACKUPFULLFILENAME
ERR=$?
LEVEL=${LEVEL_9}
DESCR=${DESCR_9}
Sub_Error 9


##############
# If we got here, the job is finnish

printlogmess $INFO ${SCRIPTID}13 "$DESCR_13 " 
