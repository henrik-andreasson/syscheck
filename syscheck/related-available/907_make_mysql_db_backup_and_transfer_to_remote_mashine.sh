#!/bin/bash

# Set default home if not already set.
SYSCHECK_HOME=${SYSCHECK_HOME:-"/usr/local/syscheck"}

# Import common resources
. $SYSCHECK_HOME/resources.sh

SCRIPTID=907

ERRNO_1="${SCRIPTID}1"
ERRNO_2="${SCRIPTID}2"
ERRNO_3="${SCRIPTID}3"

getlangfiles $SCRIPTID 
getconfig $SCRIPTID


PRINTTOSCREEN=
if [ "x$1" = "x-h" -o "x$1" = "x--help" ] ; then
	echo "$BAK_HELP"
	echo "$ERRNO_1/$BAK_DESCR_1 - $BAK_HELP_1"
	echo "$ERRNO_2/$BAK_DESCR_2 - $BAK_HELP_2"
	echo "$ERRNO_3/$BAK_DESCR_3 - $BAK_HELP_3"
	echo "${SCREEN_HELP}"
	exit
elif [ "x$1" = "x-s" -o  "x$1" = "x--screen" -o \
    "x$2" = "x-s" -o  "x$2" = "x--screen"   ] ; then
    PRINTTOSCREEN=1
    shift
fi 



$MYSQLDUMP_BIN -u root --password="$MYSQLROOT_PASSWORD" ejbca  > $MYSQLBACKUPFULLFILENAME 

if [ $? -ne 0 ] ; then
    printlogmess $ERROR $BAK_ERRNO_2 "$BAK_DESCR_2"
fi 

gzip $MYSQLBACKUPFULLFILENAME
if [ $? -ne 0 ] ;   then
    printlogmess $ERROR $BAK_ERRNO_2 "$BAK_DESCR_2"
fi  


for ( i = 0 ;  i < ${#BACKUP_HOST[@]} ; i++ ) ; do
	$SYSCHECK_HOME/related-enabled/906_ssh-copy-to-remote-machine.sh ${MYSQLBACKUPFULLFILENAME}.gz ${BACKUP_HOST[$i]}
done

