#!/bin/bash

# Set default home if not already set.
SYSCHECK_HOME=${SYSCHECK_HOME:-"/usr/local/syscheck"}

## Import common definitions ##
. $SYSCHECK_HOME/resources.sh

## Local definitions ##
BACKUPFILE_NFAST=/var/backup/nfastbackup


DATE=`date +%Y%m%d-%H:%M`

FULLFILENAME="$BACKUPFILE_NFAST-local-$DATE.tar"

tar -c --directory /opt/nfast/kmdata -f $FULLFILENAME local

if [ $? = 0 ]
then
  gzip $FULLFILENAME
  if [ $? = 0 ]
  then
      printlogmess $INFO $BAK_ERRNO_1 "$BAK_NFAST_DESCR_1" 
  else
      printlogmess $ERROR $BAK_ERRNO_2 "$BAK_NFAST_DESCR_2"
  fi  
else
  printlogmess $ERROR $BAK_ERRNO_2 "$BAK_NFAST_DESCR_2"
fi 






