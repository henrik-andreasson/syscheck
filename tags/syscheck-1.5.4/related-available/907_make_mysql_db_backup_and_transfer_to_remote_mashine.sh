#!/bin/bash

# Set default home if not already set.
SYSCHECK_HOME=${SYSCHECK_HOME:-"/usr/local/syscheck"}

# Import common resources
. $SYSCHECK_HOME/resources.sh

SCRIPTID=907

BAK_ERRNO_1="${SCRIPTID}1"
BAK_ERRNO_2="${SCRIPTID}2"
BAK_ERRNO_3="${SCRIPTID}3"
BAK_ERRNO_4="${SCRIPTID}4"

getlangfiles $SCRIPTID 
getconfig $SCRIPTID

PRINTTOSCREEN=
if [ "x$1" = "x-h" -o "x$1" = "x--help" ] ; then
	echo "$BAK_HELP"
	echo "$ERRNO_1/$BAK_DESCR_1 - $BAK_HELP_1"
	echo "$ERRNO_2/$BAK_DESCR_2 - $BAK_HELP_2"
	echo "$ERRNO_3/$BAK_DESCR_3 - $BAK_HELP_3"
	echo "$ERRNO_4/$BAK_DESCR_4 - $BAK_HELP_4"
	echo "${SCREEN_HELP}"
	exit
elif [ "x$1" = "x-s" -o  "x$1" = "x--screen" -o \
    "x$2" = "x-s" -o  "x$2" = "x--screen"   ] ; then
    PRINTTOSCREEN=1
    shift
fi 

$SYSCHECK_HOME/related-available/904_make_mysql_db_backup.sh -s

if [ $? -ne 0 ] ; then
    printlogmess $ERROR $BAK_ERRNO_2 "$BAK_DESCR_2"
fi 

if [ $? -ne 0 ] ;   then
    printlogmess $ERROR $BAK_ERRNO_3 "$BAK_DESCR_3"
fi  

for (( i = 0 ;  i < "${#BACKUP_HOST[@]}" ; i++ )) ; do
	$SYSCHECK_HOME/related-enabled/906_ssh-copy-to-remote-machine.sh ${MYSQLBACKUPFULLFILENAME}.gz ${BACKUP_HOST[$i]} ${BACKUP_DIR[$i]} ${BACKUP_USER[$i]} 
	if [ $? -eq 0 ] ; then
		printlogmess $INFO $BAK_ERRNO_1 "$BAK_DESCR_1"
	else
		printlogmess $ERROR $BAK_ERRNO_4 "$BAK_DESCR_4"
	fi
done
