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
# Check version of maria db if 10.1 need extra Parameter --apply-log-only
rpm -qa | grep -q MariaDB-backup-10.1&&EXTRAPARAM="--apply-log-only"

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
    -c|--cumulative )  ACTION=BACKUP;TYPE="CUM"; shift;;
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
  if [ -f ${BACKUP_TO_DIR}/xtrabackup_logfile.qp ];then
       #echo " printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[1]} -d ${DESCR[1]} -1 ${BACKUP_TO_DIR}/xtrabackup_logfile.qp exist"
       printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[2]} -d ${DESCR[2]} -1 "${BACKUP_TO_DIR}/xtrabackup_logfile.qp exist"
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
      printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $INFO  -e ${ERRNO[2]} -d "${DESCR[2]}" -1 "${BACKUP_TO_DIR}" -2 $TIMETOCOMPLEATE -3 $filesize
  fi

}

mariabackup_incremental_backup() {
  FULL_BACKUP_DIR=$1
  BACKUP_TO_INC_DIR=$2
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
      printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $INFO  -e ${ERRNO[4]} -d "${DESCR[4]}" -1 "${BACKUP_TO_INC_DIR}" -2 $TIMETOCOMPLEATE -3 $filesize
  fi

  #return $retcode
}

mariabackup_prepare_full() {
#set -x
     FULL_BACKUP_DIR=$1
  
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
    ret_decom=$($MARIABACKUP_BIN --decompress ${EXTRAPARAM} --target-dir="${FULL_BACKUP_DIR}"  2>&1)
    retdode=$?
    DATEDONE=$(date +"%s")
    let TIMETOCOMPLEATE="$DATEDONE - $DATESTART" || true # not to stop script
    if [ $retdode != 0 ] ; then
    #    printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $INFO  -e ${ERRNO[8]} -d "${DESCR[8]}" -1 "${FULL_BACKUP_DIR}" -2 $TIMETOCOMPLEATE
    #else
        printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[9]} -d "${DESCR[9]}" -1 "${FULL_BACKUP_DIR}" -2 $TIMETOCOMPLEATE -3 "$ret_prep"
    fi
    SCRIPTINDEX=$(addOneToIndex $SCRIPTINDEX)
    DATESTART=$(date +"%s")
    ret_prep=$($MARIABACKUP_BIN --prepare ${EXTRAPARAM} --target-dir="${FULL_BACKUP_DIR}"  2>&1)
    retcode=$?
    DATEDONE=$(date +"%s")
    let TIMETOCOMPLEATE="$DATEDONE - $DATESTART" || true # not to stop script

    if [ $retcode != 0 ] ; then
   #     printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $INFO  -e ${ERRNO[8]} -d "${DESCR[8]}" -1 "${FULL_BACKUP_DIR}" -2 $TIMETOCOMPLEATE
   # else
        printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[9]} -d "${DESCR[9]}" -1 "${FULL_BACKUP_DIR}" -2 $TIMETOCOMPLEATE -3 "$ret_prep"
    fi

#    return $ret_prep
}

mariabackup_prepare_incrementel() {
#set -x
   INC_BACKUP_DIR=$1
   FULL_BACKUP_DIR=$2 
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
  ret_decom=$($MARIABACKUP_BIN --decompress ${EXTRAPARAM} --target-dir="${INC_BACKUP_DIR}"  2>&1)
  ret_prep=$($MARIABACKUP_BIN --prepare ${EXTRAPARAM} --target-dir="${FULL_BACKUP_DIR}" --incremental-dir="${INC_BACKUP_DIR}" 2>&1)
  retcode=$?
  echo $ret_prep
  DATEDONE=$(date +"%s")
#  let TIMETOCOMPLEATE="$DATEDONE - $DATESTART" || true # not to stop script
}

mariabackup_prepare(){

PREP_PATH=$1 
NUM=$(basename $1|cut -f1 -d"_")
read dret
PREP_TYPE=$(basename $1|sed 's/.*_//')

if [ "${PREP_TYPE}" == "FULL" ] ; then
 echo "Prepere Full backup  ${PREP_PATH} for restore,,"
 mariabackup_prepare_full ${PREP_PATH}
elif [ "${PREP_TYPE}" == "CUM" ] ; then
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
 echo "WRONG value, bale out"
 exit
fi
}

mariadb_restore() {
#set -x
       FULL_BACKUP_DIR="$(dirname $1)/FULL"
#       echo "Restore from ${FULL_BACKUP_DIR}, Press return"
#       read dret
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
    #    printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $INFO  -e ${ERRNO[18]} -d "${DESCR[18]}" -1 "${FULL_BACKUP_DIR}" -2 $TIMETOCOMPLEATE2
    #else
        printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[19]} -d "${DESCR[19]}" -1 "${FULL_BACKUP_DIR}" -2 $TIMETOCOMPLEATE2 -3 "$ret_restore"
    fi

    perms=$(chown -R ${MYSQL_FILESYSTEM_USER}:${MYSQL_FILESYSTEM_GROUP} "${MYSQL_DB_PATH}")
    retcode3=$?
    if [ $retcode3 != 0 ] ; then
    #    printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $INFO  -e ${ERRNO[20]} -d "${DESCR[20]}" -1 "${FULL_BACKUP_DIR}" -2 $TIMETOCOMPLEATE2
    #else
        printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[21]} -d "${DESCR[21]}" -1 "${FULL_BACKUP_DIR}" -2 $TIMETOCOMPLEATE2 -3 "$perms"
    fi

    selinux=$(restorecon -Rv "${MYSQL_DB_PATH}")
    retcode4=$?
    if [ $retcode4 != 0 ] ; then
    #    printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $INFO  -e ${ERRNO[22]} -d "${DESCR[22]}" -1 "${FULL_BACKUP_DIR}" -2 $TIMETOCOMPLEATE2
    #else
        printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[23]} -d "${DESCR[23]}" -1 "${FULL_BACKUP_DIR}" -2 $TIMETOCOMPLEATE2 -3 "$selinux"
    fi
}

Sub_Menu(){
#cat ${DATAFILE} |cut -f3 -d"="| sort |uniq
# Displays a list of valid backup directorys

# Set the prompt for the select command
PS3="Type a number or 'q' to quit, or press return to main menu: "

# Create a list of files to display
#fileList=$(stat -c '%n %.19y ' /backup/mariabackup/* )
#fileList=$( cat ${DATAFILE} |cut -f3 -d"="| sort |uniq )
fileList=$( cat /tmp/file.txt )
# Show a menu and ask for input. If the user entered a valid choice,
# then invoke the editor on that file
#select fileName in $fileList; do
OIFS=$IFS
IFS="
"
#select fileName in `cat ${DATAFILE} |cut -f3 -d"="| sort |uniq`; do
#select fileName in `stat -c '%n %.19y ' /backup/mariabackup/*`; do
select fileName in `cat /tmp/file.txt`; do
IFS=$OIFS
    if [ -n "$fileName" ]; then
        YESNO=Y
        echo " Choose dir to use: ${fileName}"
IFS="
"
	BCKFILE=$(basename $(echo "${fileName}"|awk '{print $1}'))
        echo $BCKFILE
        #select CA in `egrep "${fileName}" ${DATAFILE}|sort`;do
        #select CA in `egrep "${BCKFILE}" ${MARIABACKUP_BASEDIR}/*/|sort`;do
        #select CA in `ls ${MARIABACKUP_BASEDIR}/*/*|egrep "${BCKFILE}"|xargs stat -c '%n %.19x ' |sort`;do
        select CA in `stat -c '%n %.19x ' ${MARIABACKUP_BASEDIR}/*/*|egrep "${MARIABACKUP_BASEDIR}/${BCKFILE}" |sort`;do
        if [ -n "$CA" ]; then
                YESNO=Y
                echo " Choose restore point: ${CA}"
                read -r -p "Are you sure? [y/N] " response
                        if [[ $response =~ ^([yY][eE][sS]|[yY])$ ]]
                                then
                                echo "Restore from : ${CA}"
                                mariabackup_prepare `echo ${CA}|awk '{print $1}'`
                                echo  `echo ${CA}|cut -f2 -d";"`
                                echo "PRess q"
IFS=$OIFS
                        else
                                break
                        fi
        break
        fi
        done
    else
    break
    fi
done

}


echo "ACTION: ${ACTION} TYPE ${TYPE}" 
################ ACTION SWITCH, little messy ################################

DATESTR=$(date +${DATESTING_FULL})
if [ "${ACTION}" == "BACKUP" -a "${TYPE}" == "FULL" ] ; then
# Full backup is only  possible once per date eq 2021-01-22
  MARIABACKUP_DIR=${MARIABACKUP_BASEDIR}/${DATESTR}/${TYPE}
  #backupdir=$(mariabackup_full_backup "${MARIABACKUP_DIR}")
  mariabackup_full_backup "${MARIABACKUP_DIR}"

elif [  "${ACTION}" == "BACKUP" -a "${TYPE}" == "INC" ]; then
# find last fullbackup find dir FULL, if not exist, exit
# Need to have one fullbackup to use as base. with date, it is base  for all Incrementel backup
# Try first with this day
  DATESTR=$(ls -dtr /backup/mariabackup/*/FULL |tail -1 |cut -f4 -d"/")
  #if [ -d ${MARIABACKUP_BASEDIR}/${DATESTR}/FULL ];then
  if [ ! -z "${DATESTR}" ];then
 #    # find first value of inc file, if no start with oneRIABACKUP_BASEDIR}/${DATESTR}/${INDEX}${TYPE}
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
    #backupdir=$(mariabackup_incremental_backup "${BASEBCK}" "${MARIABACKUP_DIR}")
    mariabackup_incremental_backup "${BASEBCK}" "${MARIABACKUP_DIR}"

 #    echo "mariabackup_incremental_backup ${BASEBCK} ${MARIABACKUP_DIR}"
#exit
    else
        printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[19]} -d "${DESCR[19]}" -1 "${FULL_BACKUP_DIR}" -2 $TIMETOCOMPLEATE2 -3 "$ret_restore"
  fi

elif [  "${ACTION}" == "BACKUP" -a "${TYPE}" == "CUM" ] ; then

# find last fullbackup find dir FULL, if not exist, exit
# Try first with this day
  DATESTR=$(ls -dtr /backup/mariabackup/*/FULL |tail -1 |cut -f4 -d"/")
  if [ ! -z "${DATESTR}" ];then
  #if [ -d ${MARIABACKUP_BASEDIR}/${DATESTR}/FULL ];then
 #    # find first value of inc file, if no start with oneRIABACKUP_BASEDIR}/${DATESTR}/${INDEX}${TYPE}
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
    backupdir=$(mariabackup_incremental_backup "${BASEBCK}" "${MARIABACKUP_DIR}")

 #    echo "mariabackup_incremental_backup ${BASEBCK} ${MARIABACKUP_DIR}"
#exit
    else
        printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[19]} -d "${DESCR[19]}" -1 "${FULL_BACKUP_DIR}" -2 $TIMETOCOMPLEATE2 -3 "$ret_restore"
  
  fi

elif [  "${ACTION}" == "RESTORE" -a "${TYPE}" == "PREP" ]; then
       echo " Some precheck before start restore and prepare"
       pgrep mysql&&echo "Mysql Still running, stop mysql :systemctl stop mysql"
       pgrep mysql&&exit
       test -d /var/lib/mysql/mysql && echo "need to be empty
       Remove files: rm -rf ${MYSQL_DB_PATH}/*, Exit script"
       test -d /var/lib/mysql/mysql&& exit
# If RESTORE_POINT have a value check if it true, skip menu
       echo $RESTORE_POINT
       if [ x != x${RESTORE_POINT} -a -d ${RESTORE_POINT} ];then
          mariabackup_prepare ${RESTORE_POINT}
          CA=$RESTORE_POINT
       else
# Find last fullbackup to use as base.
         DATESTR=$(ls -dtr /backup/mariabackup/*/FULL |tail -1 |cut -f4 -d"/")
         echo "Last full backup:${DATESTR}" 
         stat -c '%n %.19x ' /backup/mariabackup/* >/tmp/file.txt
         Sub_Menu
       fi
#stat -c '%n %.19y ' /backup/mariabackup/2021-01-27/*FULL
      echo "Time to be careful and rellay know what you, continue press return or exit with Ctrl-c"
      echo "To restore from : ${CA}, press return"
      read dret
      result=$(mariadb_restore ${CA})
   # echo $result
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


#elif [  "${ACTION}" == "PREPARE" -a  "${TYPE}" == "INC" ] ; then
#
#  result=$(mariabackup_prepare_incremental)
#
#elif [  "${ACTION}" == "PREPARE" -a  "${TYPE}" == "CUM" ] ; then
#
#  result=$(mariabackup_prepare_incremental)

elif [  "${ACTION}" == "RESTORE"  ] ; then

  result=$(mariadb_restore)

else
  echo "unknown turf"
fi
