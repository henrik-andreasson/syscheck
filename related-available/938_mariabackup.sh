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

#INC uniq ID of script (please use in the name of this file also for convinice for finding next availavle number)
SCRIPTID=938

# how many info/warn/error messages
NO_OF_ERR=23
initscript $SCRIPTID $NO_OF_ERR
getconfig "mariadb"

test $# == 0 &&schelp&&exit

INPUTARGS=`/usr/bin/getopt --options "rbpicdasxh" --long "restore,backup,,preprestore,incremental,cumulative,batch,help,screen" -- "$@"`
if [ $? != 0 ] ; then help ; fi
eval set -- "$INPUTARGS"

while true; do
  case "$1" in
    -b|--backup )      ACTION="BACKUP";TYPE=FULL ; shift;;
    -i|--incremental ) ACTION=BACKUP;TYPE="INC"; shift;;
    -c|--cumulative )  ACTION=BACKUP;TYPE="ACC"; shift;;
    -r|--restore)      ACTION=RESTORE;TYPE=PREP; shift;;
    -s|--screen )      PRINTTOSCREEN=1; shift;;
    -x|--batch )       BATCH=1; shift;;
    -h|--help )        schelp;exit;shift;;
    --) break ;;
  esac
done
RESTORE_POINT=$2
#PRINTTOSCREEN=1

mariabackup_full_backup() {
  BACKUP_TO_DIR=$1
  SCRIPTINDEX=$(addOneToIndex $SCRIPTINDEX)
  if [ -z $(pgrep mysqld) ];then
       printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[2]} -d ${DESCR[2]} -1 "Mariadb need to be started"
       exit
  fi
  SCRIPTINDEX=$(addOneToIndex $SCRIPTINDEX)
  if [ -f ${BACKUP_TO_DIR}/xtrabackup_logfile.qp ];then
       printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[2]} -d ${DESCR[2]} -1 "${BACKUP_TO_DIR} exist"
       exit 14
  fi
  if [ ! -d "${BACKUP_TO_DIR}" ] ; then
    mkdir -p "${BACKUP_TO_DIR}"
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
      printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $INFO  -e ${ERRNO[2]} -d "${DESCR[2]}" -1 "${BACKUP_TO_DIR}" -2 $TIMETOCOMPLEATE -3 "$filesize"
  fi

}

mariabackup_incremental_backup() {
set -x
  FULL_BACKUP_DIR=$1
  BACKUP_TO_INC_DIR=$2
  if [ -z $(pgrep mysqld) ];then
     echo "mysqld stoped, no incrementel backup run, Exit"
     exit
  fi
  SCRIPTINDEX=4
  if [ ! -d "${BACKUP_TO_INC_DIR}" ] ; then
    mkdir -p "${BACKUP_TO_INC_DIR}"
  fi

  if [ ! -d "${FULL_BACKUP_DIR}" ] ; then
    printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[4]} -d "${DESCR[4]}" -1 "${FULL_BACKUP_DIR}"
  fi

  SCRIPTINDEX=$(addOneToIndex $SCRIPTINDEX)

  DATESTART=$(date +"%s")
  dumpret=$($MARIABACKUP_BIN --backup --target-dir="${BACKUP_TO_INC_DIR}" --incremental-basedir="${FULL_BACKUP_DIR}" --user="${MARIABACKUP_USER}" --password="${MARIABACKUP_PASS}" ${MARIABACKUP_OPTIONS} 2>&1)
  retcode=$?
  DATEDONE=$(date +"%s")
  let TIMETOCOMPLEATE="$DATEDONE - $DATESTART" || true # not to stop script
  filesize=$(du -sh "${BACKUP_TO_INC_DIR}")

  if [ $retcode != 0 ] ; then
      printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[5]} -d "${DESCR[5]}" -1 "${BACKUP_TO_INC_DIR}" -2 $TIMETOCOMPLEATE -3 $filesize -4 "$dumpret"
  else
      printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $INFO  -e ${ERRNO[4]} -d "${DESCR[4]}" -1 "${BACKUP_TO_INC_DIR}" -2 $TIMETOCOMPLEATE -3 "$filesize"
  fi

}

mariabackup_prepare_full() {
  FULL_BACKUP_DIR=$1
  if [ "x${FULL_BACKUP_DIR}" == "x" ] ; then
    printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[6]} -d "${DESCR[6]}" -1 "${FULL_BACKUP_DIR}"
    exit
  fi

  if [ ! -d "${FULL_BACKUP_DIR}" ] ; then
    printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[7]} -d "${DESCR[7]}" -1 "${FULL_BACKUP_DIR}"
    exit
  fi


  SCRIPTINDEX=$(addOneToIndex $SCRIPTINDEX)

  DATESTART=$(date +"%s")
  ret_decom=$($MARIABACKUP_BIN --decompress ${EXTRAPARAM} --target-dir="${FULL_BACKUP_DIR}"  2>&1)
  retdode=$?
  DATEDONE=$(date +"%s")
  let TIMETOCOMPLEATE="$DATEDONE - $DATESTART" || true # not to stop script
  if [ $retdode != 0 ] ; then
    printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[9]} -d "${DESCR[9]}" -1 "${FULL_BACKUP_DIR}" -2 $TIMETOCOMPLEATE -3 "$ret_prep"
  fi
  SCRIPTINDEX=$(addOneToIndex $SCRIPTINDEX)
  DATESTART=$(date +"%s")
  ret_prep=$($MARIABACKUP_BIN --prepare ${EXTRAPARAM} --target-dir="${FULL_BACKUP_DIR}"  2>&1)
  retcode=$?
  DATEDONE=$(date +"%s")
  let TIMETOCOMPLEATE="$DATEDONE - $DATESTART" || true # not to stop script
  if [ $retcode != 0 ] ; then
      printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[9]} -d "${DESCR[9]}" -1 "${FULL_BACKUP_DIR}" -2 $TIMETOCOMPLEATE -3 "$ret_prep"
  fi

}

mariabackup_prepare_incrementel() {
  INC_BACKUP_DIR=$1
  FULL_BACKUP_DIR=$2
  if [ "x${INC_BACKUP_DIR}" == "x" ] ; then
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
  ret_decom=$($MARIABACKUP_BIN --decompress ${EXTRAPARAM} --target-dir="${INC_BACKUP_DIR}"  2>&1)
  ret_prep=$($MARIABACKUP_BIN --prepare ${EXTRAPARAM} --target-dir="${FULL_BACKUP_DIR}" --incremental-dir="${INC_BACKUP_DIR}" 2>&1)
  retcode=$?
  echo $ret_prep
  DATEDONE=$(date +"%s")
}

mariabackup_prepare(){
  PREP_PATH=$1
  NUM=$(basename $1|cut -f1 -d"_")
  read dret
  PREP_TYPE=$(basename $1|sed 's/.*_//')

  if [ "${PREP_TYPE}" == "FULL" ] ; then
    echo "Prepere Full backup  ${PREP_PATH} for restore,,"
    mariabackup_prepare_full ${PREP_PATH}
  elif [ "${PREP_TYPE}" == "ACC" ] ; then
    PREP_DIR=$(dirname $PREP_PATH)
    PREP_BASE=${PREP_DIR}/FULL
    echo "Prepere Cumulative backup  ${PREP_PATH} for restore,,"
    echo "Use Full backup from ${PREP_BASE}"
    mariabackup_prepare_full ${PREP_BASE}
    echo "Continue to prep cumulativ backup: ${PREP_DIR}"
    mariabackup_prepare_incrementel ${PREP_PATH} ${PREP_BASE}
  elif [ "${PREP_TYPE}" == "INC" ] ; then
    PREP_DIR=$(dirname $PREP_PATH)
    PREP_BASE=${PREP_DIR}/FULL
    echo "Prepere Incremetel backup  ${PREP_PATH} for restore,,"
    echo "Use Full backup from ${PREP_BASE}"
    echo "use following dir to prepare"
    stat -c '%n %.19y '  ${PREP_DIR}/*INC
    echo "-------------------------------"
    echo "If Ok press return"
    read dret
    mariabackup_prepare_full ${PREP_BASE}
    echo "Continue to prep incremetel backup: ${PREP_DIR}"
    echo "Press return"
    read dret
    COUNT=1
    while [ $COUNT -le $NUM ]
      do
         mariabackup_prepare_incrementel ${PREP_DIR}/${COUNT}_INC ${PREP_BASE}
         echo "--------------------"
       ((COUNT++))
     done
  else
     echo "WRONG value, exit"
     exit
  fi
}

mariadb_restore() {
  FULL_BACKUP_DIR="$(dirname $1)/FULL"
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
  ret_restore=$($MARIABACKUP_BIN --copy-back --target-dir="${FULL_BACKUP_DIR}" --datadir=${MYSQL_DB_PATH} 2>&1)
  retcode2=$?
  DATEDONE2=$(date +"%s")
  let TIMETOCOMPLEATE2="$DATEDONE2 - $DATESTART2" || true # not to stop script

  if [ $retcode2 != 0 ] ; then
    printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[19]} -d "${DESCR[19]}" -1 "${FULL_BACKUP_DIR}" -2 $TIMETOCOMPLEATE2 -3 "$ret_restore"
    fi

    perms=$(chown -R ${MYSQL_FILESYSTEM_USER}:${MYSQL_FILESYSTEM_GROUP} "${MYSQL_DB_PATH}")
    retcode3=$?
    if [ $retcode3 != 0 ] ; then
        printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[21]} -d "${DESCR[21]}" -1 "${FULL_BACKUP_DIR}" -2 $TIMETOCOMPLEATE2 -3 "$perms"
    fi

    selinux=$(restorecon -Rv "${MYSQL_DB_PATH}")
    retcode4=$?
    if [ $retcode4 != 0 ] ; then
        printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[23]} -d "${DESCR[23]}" -1 "${FULL_BACKUP_DIR}" -2 $TIMETOCOMPLEATE2 -3 "$selinux"
  fi
}


echo "ACTION: ${ACTION} TYPE ${TYPE}"
################ ACTION SWITCH, little messy ################################

DATESTR=$(date +${DATESTING_FULL})
if [ "${ACTION}" == "BACKUP" -a "${TYPE}" == "FULL" ] ; then
  MARIABACKUP_DIR=${MARIABACKUP_BASEDIR}/${DATESTR}/${TYPE}
  mariabackup_full_backup "${MARIABACKUP_DIR}"
elif [  "${ACTION}" == "BACKUP" -a "${TYPE}" == "INC" ]; then
  DATESTR=$(ls -dtr /backup/mariabackup/*/FULL |tail -1 |cut -f4 -d"/")
  if [ ! -z "${DATESTR}" ];then
   if [ ! -d ${MARIABACKUP_BASEDIR}/${DATESTR}/1_${TYPE} ] ;then
        INDEX=1_
        MARIABACKUP_DIR=${MARIABACKUP_BASEDIR}/${DATESTR}/${INDEX}${TYPE}
        BASEBCK=${MARIABACKUP_BASEDIR}/${DATESTR}/FULL
    else
       cd ${MARIABACKUP_BASEDIR}/${DATESTR}/
       #INDEXB=$(ls -trd ${MARIABACKUP_BASEDIR}/${DATESTR}/*_${TYPE} |tail -1 |cut -f1 -d"_")
       INDEXB=$(ls -trd *_${TYPE} |tail -1 |cut -f1 -d"_")
       INDEX=$(( $INDEXB + 1))
       MARIABACKUP_DIR=${MARIABACKUP_BASEDIR}/${DATESTR}/${INDEX}_${TYPE}
       BASEBCK=${MARIABACKUP_BASEDIR}/${DATESTR}/${INDEXB}_${TYPE}
    fi
    mariabackup_incremental_backup "${BASEBCK}" "${MARIABACKUP_DIR}"
  else
    printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[19]} -d "${DESCR[19]}" -1 "${FULL_BACKUP_DIR}" -2 $TIMETOCOMPLEATE2 -3 "$ret_restore"
  fi
elif [  "${ACTION}" == "BACKUP" -a "${TYPE}" == "ACC" ] ; then

  DATESTR=$(ls -dtr /backup/mariabackup/*/FULL |tail -1 |cut -f4 -d"/")
  if [ ! -z "${DATESTR}" ];then
   if [ ! -d ${MARIABACKUP_BASEDIR}/${DATESTR}/1_${TYPE} ] ;then
        INDEX=1_
        MARIABACKUP_DIR=${MARIABACKUP_BASEDIR}/${DATESTR}/${INDEX}${TYPE}
        BASEBCK=${MARIABACKUP_BASEDIR}/${DATESTR}/FULL
   else
       cd  ${MARIABACKUP_BASEDIR}/${DATESTR}/
       #INDEXB=$(ls -trd ${MARIABACKUP_BASEDIR}/${DATESTR}/*_${TYPE} |tail -1 |cut -f1 -d"_")
       INDEXB=$(ls -trd *_${TYPE} |tail -1 |cut -f1 -d"_")
       INDEX=$(( $INDEXB + 1))
       MARIABACKUP_DIR=${MARIABACKUP_BASEDIR}/${DATESTR}/${INDEX}_${TYPE}
       BASEBCK=${MARIABACKUP_BASEDIR}/${DATESTR}/FULL
   fi
       mariabackup_incremental_backup "${BASEBCK}" "${MARIABACKUP_DIR}"

  else
        printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[19]} -d "${DESCR[19]}" -1 "${FULL_BACKUP_DIR}" -2 $TIMETOCOMPLEATE2 -3 "$ret_restore"

  fi

elif [  "${ACTION}" == "RESTORE" -a "${TYPE}" == "PREP" ]; then
  echo $RESTORE_POINT
  if [ x != x${RESTORE_POINT} -a -d ${RESTORE_POINT} ];then
      echo " Some precheck before start restore and prepare"
      pgrep mysql&&echo "Mysql Still running, stop mysql :systemctl stop mysql"
      pgrep mysql&&exit
      test -d /var/lib/mysql/mysql && echo "need to be empty
      Remove files: rm -rf ${MYSQL_DB_PATH}/*, Exit script"
      test -d /var/lib/mysql/mysql&& exit
      mariabackup_prepare ${RESTORE_POINT}
      CA=$RESTORE_POINT
  else
      DATESTR=$(ls -dtr /backup/mariabackup/*/FULL |tail -1 |cut -f4 -d"/")
      echo "Last full backup:${DATESTR}"
      for i in $(ls -d  /backup/mariabackup/*) ;do
         echo $i
         echo "----------------------"
         ls -ldtr $i/*
         echo
      done
      exit
  fi
  echo "Time to be careful and rellay know what you, continue press return or exit with Ctrl-c"
  echo "To restore from : ${CA}, press return"
  read dret
  result=$(mariadb_restore ${CA})
  echo ""
  echo "Before start mysql, check that ALL servers in cluster are stoped."
  echo "To start database with bootstrap"
  echo "-----------------------"
  echo "Run: galera_new_cluster"
  echo "-----------------------"
  echo " Then run: systemctl start mysql"
  echo "-----------------------"
  echo "Press return"
  read dret
elif [  "${ACTION}" == "RESTORE"  ] ; then

  result=$(mariadb_restore)

else
  echo "unknown turf"
fi
