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
SCRIPTNAME=mysqlbackup

# uniq ID of script (please use in the name of this file also for convinice for finding next availavle number)
SCRIPTID=904

# how many info/warn/error messages
NO_OF_ERR=3
initscript $SCRIPTID $NO_OF_ERR 3
getconfig "mariadb"


INPUTARGS=`/usr/bin/getopt --options "hsymwdxb" --long "help,screen,default,daily,weekly,monthly,yearly,batch" -- "$@"`
if [ $? != 0 ] ; then help ; fi
eval set -- "$INPUTARGS"

while true; do
  case "$1" in
    -x|--default ) TYPE=${SUBDIR_DEFAULT}; shift;;
    -d|--daily   ) TYPE=${SUBDIR_DAILY}; shift;;
    -w|--weekly  ) TYPE=${SUBDIR_WEEKLY}; shift;;
    -m|--monthly ) TYPE=${SUBDIR_MONTHLY}; shift;;
    -y|--yearly  ) TYPE=${SUBDIR_YEARLY}; shift;;
    -s|--screen ) PRINTTOSCREEN=1; shift;;
    -b|--batch )  BATCH=1; shift;;
    -h|--help )   schelp;exit;shift;;
    --) break ;;
  esac
done


# main part of script

EXTRADIR=
if [ "x${TYPE}" = "x" ] ; then
	EXTRADIR=${SUBDIR_DEFAULT}
else
	EXTRADIR=${TYPE}
fi


if [ ! -d "${MYSQLBACKUPDIR}/${EXTRADIR}" ] ; then
    printlogmess ${SCRIPTNAME}  ${SCRIPTID} ${SCRIPTINDEX}   $ERROR ${ERRNO[3]} "${DESCR[3]}" "${MYSQLBACKUPDIR}/${EXTRADIR}"
    exit 1
fi


for (( i = 0 ;  i < ${#DBNAME[@]} ; i++ )) ; do
    SCRIPTINDEX=$(addOneToIndex $SCRIPTINDEX)

    DATESTR=$(date +${DATESTING})
    MYSQLBACKUPFULLFILENAME="${MYSQLBACKUPDIR}/${EXTRADIR}/${DBNAME[$i]}-${DATESTR}.gz"
    DATESTART=$(date +"%s")
    dumpret=$($MYSQLDUMP_BIN -u root --password="${MYSQLROOT_PASSWORD}" ${MYSQLDUMP_OPTIONS} "${DB_NAME}" ${MYSQLDUMP_TABLES} |& gzip > ${MYSQLBACKUPFULLFILENAME} 2>&1)
    retcode=$?
    DATEDONE=$(date +"%s")
    let TIMETOCOMPLEATE="$DATEDONE - $DATESTART" || true # not to stop script
    filesize=$(stat -c "%s" "$MYSQLBACKUPFULLFILENAME")

    if [ $retcode -eq 0 ] ; then
        printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX} $INFO  ${ERRNO[1]} "${DESCR[1]}" "$MYSQLBACKUPFULLFILENAME" $TIMETOCOMPLEATE $filesize
    else
        printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX} $ERROR ${ERRNO[2]} "${DESCR[2]}" "$MYSQLBACKUPFULLFILENAME" $TIMETOCOMPLEATE $filesize "$dumpret"
    fi

    if [ "x$BATCH" = "x1" ] ; then
        echo "$MYSQLBACKUPFULLFILENAME"
    fi

done
