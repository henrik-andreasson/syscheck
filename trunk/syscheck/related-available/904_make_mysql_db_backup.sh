#!/bin/bash

# Set default home if not already set.
SYSCHECK_HOME=${SYSCHECK_HOME:-"/usr/local/syscheck"}

# Import common resources
. $SYSCHECK_HOME/resources.sh

SCRIPTID=904

getlangfiles $SCRIPTID 
getconfig $SCRIPTID

ERRNO_1="${SCRIPTID}1"
ERRNO_2="${SCRIPTID}2"
ERRNO_3="${SCRIPTID}3"
ERRNO_4="${SCRIPTID}4"

PRINTTOSCREEN=0

schelp () {
	echo "$HELP"
	echo "$ERRNO_1/$MYSQL_BACKUP_DESCR_1 - $MYSQL_BACKUP_HELP_1"
	echo "$ERRNO_2/$MYSQL_BACKUP_DESCR_2 - $MYSQL_BACKUP_HELP_2"
	echo "$ERRNO_3/$MYSQL_BACKUP_DESCR_3 - $MYSQL_BACKUP_HELP_3"
	echo "${SCREEN_HELP}"
	exit
}


TEMP=`/usr/bin/getopt --options "hsymwdx" --long "help,screen,default,daily,weekly,monthly,yearly" -- "$@"`
if [ $? != 0 ] ; then help ; fi
eval set -- "$TEMP"

while true; do
  case "$1" in
    -x|--default ) TYPE=${SUBDIR_DEFAULT}; shift;;
    -d|--daily   ) TYPE=${SUBDIR_DAILY}; shift;;
    -w|--weekly  ) TYPE=${SUBDIR_WEEKLY}; shift;;
    -m|--monthly ) TYPE=${SUBDIR_MONTHLY}; shift;;
    -y|--yearly  ) TYPE=${SUBDIR_YEARLY}; shift;;
    -s|--screen ) PRINTTOSCREEN=1; shift;;
    -h|--help )   help;shift;;
    --) break ;;
  esac
done

EXTRADIR=
if [ "x${TYPE}" = "x" ] ; then
	EXTRADIR=${SUBDIR_DEFAULT}	
else
	EXTRADIR=${TYPE}
fi

if [ ! -d "${MYSQLBACKUPDIR}/${EXTRADIR}" ] ; then
	printlogmess $ERROR $ERRNO_3 "$MYSQL_BACKUP_DESCR_3" "${MYSQLBACKUPDIR}/${EXTRADIR}"
	exit 1
fi

MYSQLBACKUPFULLFILENAME="${MYSQLBACKUPDIR}/${EXTRADIR}/${MYSQLBACKUPFILE}"
dumpret=$($MYSQLDUMP_BIN -u root --password="${MYSQLROOT_PASSWORD}" ${DB_NAME} 2>&1 > ${MYSQLBACKUPFULLFILENAME} )

if [ $? = 0 ] ; then
  gzip $MYSQLBACKUPFULLFILENAME
  if [ $? = 0 ] ; then
      printlogmess $INFO $ERRNO_1 "$MYSQL_BACKUP_DESCR_1" $MYSQLBACKUPFULLFILENAME.gz
      echo "$MYSQLBACKUPFULLFILENAME.gz"
  else
      printlogmess $ERROR $ERRNO_2 "$MYSQL_BACKUP_DESCR_2" $MYSQLBACKUPFULLFILENAME
  fi  
else
  printlogmess $ERROR $ERRNO_4 "$MYSQL_BACKUP_DESCR_4" "$dumpret"
fi 






