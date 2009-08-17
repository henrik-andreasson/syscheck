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

PRINTTOSCREEN=0
if [ "x$1" = "x-h" -o "x$1" = "x--help" ] ; then
	echo "$ECRT_HELP"
	echo "$ERRNO_1/$MYSQL_BACKUP_DESCR_1 - $MYSQL_BACKUP_HELP_1"
	echo "$ERRNO_2/$MYSQL_BACKUP_DESCR_2 - $MYSQL_BACKUP_HELP_2"
	echo "$ERRNO_3/$MYSQL_BACKUP_DESCR_3 - $MYSQL_BACKUP_HELP_3"
	echo "${SCREEN_HELP}"
	exit
elif [ "x$1" = "x-s" -o  "x$1" = "x--screen" -o \
    "x$2" = "x-s" -o  "x$2" = "x--screen"   ] ; then
    PRINTTOSCREEN=1
fi

$MYSQLDUMP_BIN -u root --password="$MYSQLROOT_PASSWORD" ejbca  > $MYSQLBACKUPFULLFILENAME 

if [ $? = 0 ] ; then
  gzip $MYSQLBACKUPFULLFILENAME
  if [ $? = 0 ] ; then
      printlogmess $INFO $ERRNO_1 "$MYSQL_BACKUP_DESCR_1" 
  else
      printlogmess $ERROR $ERRNO_2 "$MYSQL_BACKUP_DESCR_2"
  fi  
else
  printlogmess $ERROR $ERRNO_2 "$MYSQL_BACKUP_DESCR_2"
fi 






