#!/bin/bash

SYSCHECK_HOME="${SYSCHECK_HOME:-/opt/syscheck}" # use default if  unset
if [ ! -f ${SYSCHECK_HOME}/syscheck.sh ] ; then
  echo "Can't find $SYSCHECK_HOME/syscheck.sh"
  exit
fi

# Import common resources
source $SYSCHECK_HOME/config/related-scripts.conf

# script name, used when integrating with nagios/icinga
SCRIPTNAME=mariabackup

#INC uniq ID of script (please use in the name of this file also for convinice for finding next availavle number)
SCRIPTID=938

# how many info/warn/error messages
NO_OF_ERR=23
initscript $SCRIPTID $NO_OF_ERR
getconfig "mariadb"

#test $# == 0 &&schelp&&exit

INPUTARGS=`/usr/bin/getopt --options "fi" --long "full,incremental,help,screen" -- "$@"`
if [ $? != 0 ] ; then help ; fi
eval set -- "$INPUTARGS"

while true; do
  case "$1" in
    -i|--incremental ) TYPE="incremental"; shift;;
    -f|--full)         TYPE="full"; shift;;
    -s|--screen )      PRINTTOSCREEN=1; shift;;
    -x|--batch )       BATCH=1; shift;;
    -h|--help )        schelp;exit;shift;;
    *) break ; shift;;
  esac
done

if [[ $TYPE == "full" ]] ; then
    mariabackup_full_backup
elif [[ $TYPE == "full" ]] ; then
    mariabackup_incremental_backup
fi


mariabackup_full_backup() {
    FULL_BACKUP_NAME=$1
    if [[ -z "${FULL_BACKUP_NAME" ]] ; then
        printlogmess -n "${SCRIPTNAME}" -i "${SCRIPTID}" -x "${SCRIPTINDEX}" -l $ERROR -e "${ERRNO[1]}" -d "${DESCR[1]}"
    fi
    BACKUP_TO_DIR="${MARIABACKUP_BASEDIR}/"
    if [ -f ${BACKUP_TO_DIR}/xtrabackup_logfile.qp ];then
        printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[2]} -d ${DESCR[2]} -1 "${BACKUP_TO_DIR}"
        exit 1
    fi

  DATESTART=$(date +"%s")

  dumpret=$($MARIABACKUP_BIN --backup --target-dir="${BACKUP_TO_DIR}" --user="${MARIABACKUP_USER}" --password="${MARIABACKUP_PASS}" ${MARIABACKUP_OPTIONS} 2>&1)
  retcode=$?
  DATEDONE=$(date +"%s")
  let TIMETOCOMPLEATE="$DATEDONE - $DATESTART" || true # not to stop script
  filesize=$(du -sh "${BACKUP_TO_DIR}")

  if [ $retcode != 0 ] ; then
      printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[3]} -d "${DESCR[3]}" -1 "${BACKUP_TO_DIR}" -2 $TIMETOCOMPLEATE -3 $filesize -4 "$dumpret"
  else
      printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $INFO  -e ${ERRNO[4]} -d "${DESCR[4]}" -1 "${BACKUP_TO_DIR}" -2 $TIMETOCOMPLEATE -3 "$filesize" -4 "$dumpret"
  fi

}

mariabackup_incremental_backup() {
    FULL_BACKUP_NAME=$1
    INC_BACKUP_NAME=$2
    if [ ! -d "${FULL_BACKUP_DIR}" ] ; then
        printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[7]} -d "${DESCR[7]}" -1 "${FULL_BACKUP_DIR}"
    fi

    SCRIPTINDEX=$(addOneToIndex $SCRIPTINDEX)

    DATESTART=$(date +"%s")
    dumpret=$($MARIABACKUP_BIN --backup --target-dir="${BACKUP_TO_INC_DIR}" --incremental-basedir="${FULL_BACKUP_DIR}" --user="${MARIABACKUP_USER}" --password="${MARIABACKUP_PASS}" ${MARIABACKUP_OPTIONS} 2>&1)
    retcode=$?
    DATEDONE=$(date +"%s")
    let TIMETOCOMPLEATE="$DATEDONE - $DATESTART" || true # not to stop script
    filesize=$(du -sh "${BACKUP_TO_INC_DIR}")

    if [ $retcode != 0 ] ; then
        printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[5]} -d "${DESCR[5]}" -1 "${FULL_BACKUP_NAME}" -2 "${BACKUP_TO_INC_DIR}" -3 $TIMETOCOMPLEATE -3 $filesize -4 "$dumpret"
    else
        printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $INFO  -e ${ERRNO[6]} -d "${DESCR[6]}" -1 "${FULL_BACKUP_NAME}" -2 "${BACKUP_TO_INC_DIR}" -3 $TIMETOCOMPLEATE -3 "$filesize"
    fi

}
