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
SCRIPTNAME=mariabackup

# uniq ID of script (please use in the name of this file also for convinice for finding next availavle number)
SCRIPTID=938

# how many info/warn/error messages
NO_OF_ERR=23
initscript $SCRIPTID $NO_OF_ERR
getconfig "mariadb"


INPUTARGS=`/usr/bin/getopt --options "rbfid:sxh" --long "restore,backup,full,incremental,dirfullbackup:,dirincbackup,batch,help,screen" -- "$@"`
if [ $? != 0 ] ; then help ; fi
eval set -- "$INPUTARGS"

while true; do
  case "$1" in
    -r|--restore )     ACTION="RESTORE" ; shift;;
    -b|--backup )      ACTION="BACKUP" ; shift;;
    -f|--full )        TYPE="FULL"; shift;;
    -i|--incremental ) TYPE="INCREMENTAL"; shift;;
    -d|--dirfullbackup) FULL_BACKUP_DIR=$2; shift 2;;
    -a|--dirincbackup) INC_BACKUP_DIR=$2; shift 2;;
    -s|--screen )      PRINTTOSCREEN=1; shift;;
    -x|--batch )       BATCH=1; shift;;
    -h|--help )        schelp;exit;shift;;
    --) break ;;
  esac
done


# main part of script

# defaults
if [ "x${TYPE}" = "x" ] ; then
  TYPE="FULL"
fi

if [ "x${ACTION}" = "x" ] ; then
  ACTION="BACKUP"
fi


mariabackup_full_backup () {

  BACKUP_TO_DIR=$1

  if [ ! -d "${BACKUP_TO_DIR}" ] ; then
    mkdir -p "${BACKUP_TO_DIR}"
  fi

  SCRIPTINDEX=$(addOneToIndex $SCRIPTINDEX)

  DATESTART=$(date +"%s")

  dumpret=$($MARIABACKUP_BIN --backup --target-dir="${BACKUP_TO_DIR}" --user="${MARIABACKUP_USER}" --password="${MARIABACKUP_PASS}" ${MARIABACKUP_OPTIONS} 2>&1)
  retcode=$?
  DATEDONE=$(date +"%s")
  let TIMETOCOMPLEATE="$DATEDONE - $DATESTART" || true # not to stop script
  filesize=$(du -s "${BACKUP_TO_DIR}")

  if [ $retcode -eq 0 ] ; then
      printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $INFO  -e ${ERRNO[1]} -d "${DESCR[1]}" -1 "${BACKUP_TO_DIR}" -2 $TIMETOCOMPLEATE -3 $filesize
  else
      printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[2]} -d "${DESCR[2]}" -1 "${BACKUP_TO_DIR}" -2 $TIMETOCOMPLEATE -3 $filesize -4 "$dumpret"
  fi

  return $retcode

}

mariabackup_incremental_backup() {

  BACKUP_TO_INC_DIR=$1

  if [ ! -d "${BACKUP_TO_INC_DIR}" ] ; then
    mkdir -p "${BACKUP_TO_INC_DIR}"
  fi

  if [ ! -d "${FULL_BACKUP_DIR}" ] ; then
    printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[3]} -d "${DESCR[3]}" -1 "${FULL_BACKUP_DIR}"
  fi

  SCRIPTINDEX=$(addOneToIndex $SCRIPTINDEX)

  DATESTART=$(date +"%s")
  dumpret=$($MARIABACKUP_BIN --backup --target-dir="${FULL_BACKUP_DIR}" --incremental-basedir="${BACKUP_TO_INC_DIR}" --user="${MARIABACKUP_USER}" --password="${MARIABACKUP_PASS}" ${MARIABACKUP_OPTIONS} 2>&1)
  retcode=$?
  DATEDONE=$(date +"%s")
  let TIMETOCOMPLEATE="$DATEDONE - $DATESTART" || true # not to stop script
  filesize=$(du -s "${BACKUP_TO_INC_DIR}")

  if [ $retcode -eq 0 ] ; then
      printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $INFO  -e ${ERRNO[4]} -d "${DESCR[4]}" -1 "${BACKUP_TO_INC_DIR}" -2 $TIMETOCOMPLEATE -3 $filesize
  else
      printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[5]} -d "${DESCR[5]}" -1 "${BACKUP_TO_INC_DIR}" -2 $TIMETOCOMPLEATE -3 $filesize -4 "$dumpret"
  fi

  return $retcode
}

mariabackup_full_prepare() {

    if [ "x${FULL_BACKUP_DIR}" == "x" ] ; then
      # must specify
      printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[6]} -d "${DESCR[6]}" -1 "${FULL_BACKUP_DIR}"
      exit
    fi

    if [ ! -d "${FULL_BACKUP_DIR}" ] ; then
      # must exist as dir
      printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[7]} -d "${DESCR[7]}" -1 "${FULL_BACKUP_DIR}"
      exit
    fi


    SCRIPTINDEX=$(addOneToIndex $SCRIPTINDEX)

    DATESTART=$(date +"%s")
    ret_prep=$($MARIABACKUP_BIN --prepare --target-dir="${FULL_BACKUP_DIR}"  2>&1)
    retcode=$?
    DATEDONE=$(date +"%s")
    let TIMETOCOMPLEATE="$DATEDONE - $DATESTART" || true # not to stop script

    if [ $retcode -eq 0 ] ; then
        printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $INFO  -e ${ERRNO[8]} -d "${DESCR[8]}" -1 "${FULL_BACKUP_DIR}" -2 $TIMETOCOMPLEATE
    else
        printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[9]} -d "${DESCR[9]}" -1 "${FULL_BACKUP_DIR}" -2 $TIMETOCOMPLEATE -3 "$ret_prep"
    fi

    return $ret_prep
}

mariabackup_incremental_prepare() {

  if [ "x${INC_BACKUP_DIR}" == "x" ] ; then
    # must specify
    printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[10]} -d "${DESCR[10]}" -1 "${INC_BACKUP_DIR}"
    exit
  fi

  if [ ! -d "${INC_BACKUP_DIR}" ] ; then
    # must exist
    printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[11]} -d "${DESCR[11]}" -1 "${INC_BACKUP_DIR}"
    exit
  fi

  if [ "x${FULL_BACKUP_DIR}" == "x" ] ; then
    # must specify
    printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[12]} -d "${DESCR[12]}" -1 "${FULL_BACKUP_DIR}"
    exit
  fi

  if [ ! -d "${FULL_BACKUP_DIR}" ] ; then
    # must exist
    printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[13]} -d "${DESCR[13]}" -1 "${FULL_BACKUP_DIR}"
    exit
  fi


  SCRIPTINDEX=$(addOneToIndex $SCRIPTINDEX)

  DATESTART=$(date +"%s")
# mariabackup --prepare    --target-dir=/var/mariadb/backup     --incremental-dir=/var/mariadb/inc1
  ret_prep=$($MARIABACKUP_BIN --prepare --target-dir="${FULL_BACKUP_DIR}" --incremental-dir="${INC_BACKUP_DIR}" 2>&1)
  retcode=$?
  DATEDONE=$(date +"%s")
  let TIMETOCOMPLEATE="$DATEDONE - $DATESTART" || true # not to stop script

  if [ $retcode -eq 0 ] ; then
      printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $INFO  -e ${ERRNO[14]} -d "${DESCR[14]}" -1 "${INC_BACKUP_DIR}" -2 $TIMETOCOMPLEATE
  else
      printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[15]} -d "${DESCR[15]}" -1 "${INC_BACKUP_DIR}" -2 $TIMETOCOMPLEATE -3 "$ret_prep"
  fi


}

mariadb_restore() {


    if [ "x${FULL_BACKUP_DIR}" == "x" ] ; then
      # must specify
      printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[16]} -d "${DESCR[16]}" -1 "${FULL_BACKUP_DIR}"
      exit
    fi

    if [ ! -d "${FULL_BACKUP_DIR}" ] ; then
      # must be a dir
      printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[17]} -d "${DESCR[17]}" -1 "${FULL_BACKUP_DIR}"
      exit
    fi

    SCRIPTINDEX=$(addOneToIndex $SCRIPTINDEX)

    DATESTART2=$(date +"%s")
    ret_restore=$($MARIABACKUP_BIN --copy-back --target-dir="${FULL_BACKUP_DIR}"  2>&1)
    retcode2=$?
    DATEDONE2=$(date +"%s")
    let TIMETOCOMPLEATE2="$DATEDONE2 - $DATESTART2" || true # not to stop script

    if [ $retcode2 -eq 0 ] ; then
        printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $INFO  -e ${ERRNO[18]} -d "${DESCR[18]}" -1 "${FULL_BACKUP_DIR}" -2 $TIMETOCOMPLEATE2
    else
        printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[19]} -d "${DESCR[19]}" -1 "${FULL_BACKUP_DIR}" -2 $TIMETOCOMPLEATE2 -3 "$ret_restore"
    fi

    perms=$(chown -R ${MYSQL_FILESYSTEM_USER}:${MYSQL_FILESYSTEM_GROUP} "${MYSQL_DB_PATH}")
    retcode3=$?
    if [ $retcode3 -eq 0 ] ; then
        printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $INFO  -e ${ERRNO[20]} -d "${DESCR[20]}" -1 "${FULL_BACKUP_DIR}" -2 $TIMETOCOMPLEATE2
    else
        printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[21]} -d "${DESCR[21]}" -1 "${FULL_BACKUP_DIR}" -2 $TIMETOCOMPLEATE2 -3 "$ret_restore"
    fi

    selinux=$(restorecon -Rv "${MYSQL_DB_PATH}")
    retcode4=$?
    if [ $retcode4 -eq 0 ] ; then
        printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $INFO  -e ${ERRNO[22]} -d "${DESCR[22]}" -1 "${FULL_BACKUP_DIR}" -2 $TIMETOCOMPLEATE2
    else
        printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[23]} -d "${DESCR[23]}" -1 "${FULL_BACKUP_DIR}" -2 $TIMETOCOMPLEATE2 -3 "$ret_restore"
    fi


}



################# ACTION SWITCH ################################

if [ "${ACTION}" == "BACKUP" -a "${TYPE}" == "FULL" ] ; then

  DATESTR=$(date +${DATESTING_FULL})
  MARIABACKUP_DIR="${MARIABACKUP_BASEDIR}/${TYPE}/${DATESTR}"

  backupdir=$(mariabackup_full_backup "${MARIABACKUP_DIR}")


elif [  "${ACTION}" == "BACKUP" -a "${TYPE}" == "INCREMENTAL" ] ; then

  DATESTR=$(date +${DATESTING_INC})
  MARIABACKUP_DIR="${MARIABACKUP_BASEDIR}/${TYPE}/${DATESTR}"

  backupdir=$(mariabackup_incremental_backup "${FULL_BACKUP_DIR}" "${MARIABACKUP_DIR}")


elif [  "${ACTION}" == "PREPARE" -a  "${TYPE}" == "FULL" ] ; then

  result=$(mariabackup_prepare_full)


elif [  "${ACTION}" == "PREPARE" -a  "${TYPE}" == "INCREMENTAL" ] ; then

  result=$(mariabackup_prepare_incremental)


elif [  "${ACTION}" == "RESTORE"  ] ; then

  result=$(mariabackup_restore)

else
  echo "unknown turf"
fi
