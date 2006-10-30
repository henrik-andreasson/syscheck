#!/bin/bash

# Set default home if not already set.
SYSCHECK_HOME=${SYSCHECK_HOME:-"/usr/local/syscheck"}

# Import common resources
. $SYSCHECK_HOME/resources.sh

DATE=`date +%Y%m%d-%H:%M`

FULLFILENAME="$BACKUPFILE-$DATE.sql"

$MYSQLDUMP_BIN -u root --password="$MYSQLROOT_PASSWORD" ejbca  > $FULLFILENAME 

if [ $? = 0 ]
then
  gzip $FULLFILENAME
  if [ $? = 0 ]
  then
      printlogmess $BAK_LEVEL_1 $BAK_ERRNO_1 "$BAK_DESCR_1" 
  else
      printlogmess $BAK_LEVEL_2 $BAK_ERRNO_2 "$BAK_DESCR_2"
  fi  
else
  printlogmess $BAK_LEVEL_2 $BAK_ERRNO_2 "$BAK_DESCR_2"
fi 






