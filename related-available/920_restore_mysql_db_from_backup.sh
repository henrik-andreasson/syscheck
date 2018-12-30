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
SCRIPTNAME=restore_db

# uniq ID of script (please use in the name of this file also for convinice for finding next availavle number)
SCRIPTID=920

# how many info/warn/error messages
NO_OF_ERR=3
initscript $SCRIPTID $NO_OF_ERR
getconfig "mariadb"

# get command line arguments
INPUTARGS=`/usr/bin/getopt --options "hsvb" --long "help,screen,verbose,backupfile:" -- "$@"`
if [ $? != 0 ] ; then schelp ; fi
#echo "TEMP: >$TEMP<"
eval set -- "$INPUTARGS"

while true; do
  case "$1" in
    -s|--screen  ) PRINTTOSCREEN=1; shift;;
    -v|--verbose ) PRINTVERBOSESCREEN=1 ; shift;;
    -b|--backupdile ) BACKUPFILE=$2 ; shift 2;;
    -h|--help )   schelp;exit;shift;;
    --) break;;
  esac
done

# main part of script

if [ "x$BACKUPFILE" = "x" ] ; then
	printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX}  $ERROR ${DESCR[4]} "$BAK_DESCR[4]"
	exit
fi

echo "enter 'im-really-sure' (without the '-') to continue or ctrl-c to abort"
read a
if [ "x$a" != "xim really sure" ] ; then
        echo "ok probably wise choice, exiting"
        exit
fi


echo "now we'll backup the current database before we restore the one you specified"

$SYSCHECK_HOME/related-available/904_make_mysql_db_backup.sh -s

if [ $? -ne 0 ] ; then
	printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX}  $ERROR ${ERRNO[1]} "${DESCR[1]}"
	exit
fi


echo "restoring the db from $BACKUPFILE"
zcat "$BACKUPFILE" | $MYSQL_BIN ${DB_NAME} -u root --password="$MYSQLROOT_PASSWORD"
if [ $? -eq 0 ] ; then
	printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX}  $INFO ${ERRNO[2]} "${DESCR[2]}" "$1"
else
	printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX}  $ERROR ${ERRNO[3]} "${DESCR[3]}" "$1" "${BACKUPFILE}"
fi
