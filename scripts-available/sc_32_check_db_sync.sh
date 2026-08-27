#!/bin/bash

SYSCHECK_HOME="${SYSCHECK_HOME:-/opt/syscheck}" # use default if  unset
if [ ! -f ${SYSCHECK_HOME}/syscheck.sh ] ; then
  echo "Can't find $SYSCHECK_HOME/syscheck.sh"
  exit
fi

## Import common definitions ##
source $SYSCHECK_HOME/config/syscheck-scripts.conf

# script name, used when integrating with nagios/icinga
SCRIPTNAME=db_sync

# uniq ID of script (please use in the name of this file also for convinice for finding next availavle number)
SCRIPTID=32

# how many info/warn/error messages
NO_OF_ERR=8
initscript $SCRIPTID $NO_OF_ERR
getconfig "mariadb"

default_script_getopt $*

# main part of script

DBSYNC_SETTLE_SECONDS="${DBSYNC_SETTLE_SECONDS:-60}"
DBSYNC_RECHECK_TRIES="${DBSYNC_RECHECK_TRIES:-3}"
DBSYNC_RECHECK_DELAY="${DBSYNC_RECHECK_DELAY:-5}"
DBSYNC_TIMEOUT="${DBSYNC_TIMEOUT:-15}"
DBSYNC_PORT="${DBSYNC_PORT:-3306}"

ERRSTATUS=0
GLOBALERRMESSAGE=""

run_sql () {
  NODE="$1"
  SQL="$2"

  timeout "${DBSYNC_TIMEOUT}" "${MYSQL_BIN}" \
    --batch --skip-column-names --connect-timeout="${DBSYNC_TIMEOUT}" \
    -h "${NODE}" -P "${DBSYNC_PORT}" -u "${DB_USER}" "--password=${DB_PASSWORD}" \
    "${DB_NAME}" -e "${SQL}" 2>&1
}

column_list () {
  NODE="$1"
  TABLE="$2"

  run_sql "${NODE}" "SET SESSION group_concat_max_len = 1000000; SELECT GROUP_CONCAT(CONCAT('IFNULL(\`', COLUMN_NAME, '\`,''~N~'')') ORDER BY ORDINAL_POSITION SEPARATOR ',') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA='${DB_NAME}' AND TABLE_NAME='${TABLE}';"
}

table_fingerprint () {
  NODE="$1"
  TABLE="$2"
  CUTOFF="$3"
  COLUMNS="$4"

  if [ "x${CUTOFF}" = "x" ] ; then
    WHERE=""
  else
    WHERE="WHERE \`${CUTOFF}\` <= NOW() - INTERVAL ${DBSYNC_SETTLE_SECONDS} SECOND"
  fi

  run_sql "${NODE}" "SELECT CONCAT(COUNT(*), ':', COALESCE(BIT_XOR(CRC32(CONCAT_WS('#', ${COLUMNS}))), 0)) FROM \`${TABLE}\` ${WHERE};"
}

compare_table () {
  TABLE="$1"
  CUTOFF="$2"
  SCRIPTINDEX="$3"

  COLUMNS=$(column_list "${DBSYNC_NODE[0]}" "${TABLE}")
  if [ $? -ne 0 ] || [ "x${COLUMNS}" = "x" ] ; then
    printlogmess -n "${SCRIPTNAME}" -i "${SCRIPTID}" -x "${SCRIPTINDEX}" -l "$ERROR" -e "${ERRNO[4]}" -d "${DESCR[4]}" -1 "${DBSYNC_NODE[0]}" -2 "${TABLE}" -3 "${COLUMNS}"
    return 1
  fi

  if [ "x${COLUMNS}" = "xNULL" ] ; then
    printlogmess -n "${SCRIPTNAME}" -i "${SCRIPTID}" -x "${SCRIPTINDEX}" -l "$ERROR" -e "${ERRNO[5]}" -d "${DESCR[5]}" -1 "${TABLE}" -2 "${DBSYNC_NODE[0]}"
    return 1
  fi

  TRY=1
  while [ ${TRY} -le ${DBSYNC_RECHECK_TRIES} ] ; do
    REFERENCE=""
    REFERENCENODE=""
    MISMATCH=""
    MISMATCHVALUE=""
    FAILED=""
    FAILREASON=""

    for (( n = 0 ;  n < ${#DBSYNC_NODE[@]} ; n++ )) ; do
      FINGERPRINT=$(table_fingerprint "${DBSYNC_NODE[$n]}" "${TABLE}" "${CUTOFF}" "${COLUMNS}")
      if [ $? -ne 0 ] || [ "x${FINGERPRINT}" = "x" ] || [ "x${FINGERPRINT#*ERROR}" != "x${FINGERPRINT}" ] ; then
        FAILED="${DBSYNC_NODE[$n]}"
        FAILREASON="${FINGERPRINT}"
        break
      fi

      printverbose "${TABLE} ${DBSYNC_NODE[$n]} try ${TRY}: ${FINGERPRINT}"

      if [ "x${REFERENCE}" = "x" ] ; then
        REFERENCE="${FINGERPRINT}"
        REFERENCENODE="${DBSYNC_NODE[$n]}"
      elif [ "x${FINGERPRINT}" != "x${REFERENCE}" ] ; then
        MISMATCH="${DBSYNC_NODE[$n]}"
        MISMATCHVALUE="${FINGERPRINT}"
      fi
    done

    if [ "x${FAILED}" != "x" ] ; then
      printlogmess -n "${SCRIPTNAME}" -i "${SCRIPTID}" -x "${SCRIPTINDEX}" -l "$ERROR" -e "${ERRNO[4]}" -d "${DESCR[4]}" -1 "${FAILED}" -2 "${TABLE}" -3 "${FAILREASON}"
      return 1
    fi

    if [ "x${MISMATCH}" = "x" ] ; then
      if [ ${TRY} -eq 1 ] ; then
        printlogmess -n "${SCRIPTNAME}" -i "${SCRIPTID}" -x "${SCRIPTINDEX}" -l "$INFO" -e "${ERRNO[1]}" -d "${DESCR[1]}" -1 "${TABLE}" -2 "${#DBSYNC_NODE[@]}" -3 "${REFERENCE}"
      else
        printlogmess -n "${SCRIPTNAME}" -i "${SCRIPTID}" -x "${SCRIPTINDEX}" -l "$WARN" -e "${ERRNO[3]}" -d "${DESCR[3]}" -1 "${TABLE}" -2 "${TRY}" -3 "${REFERENCE}"
      fi
      return 0
    fi

    if [ ${TRY} -lt ${DBSYNC_RECHECK_TRIES} ] ; then
      sleep "${DBSYNC_RECHECK_DELAY}"
    fi
    TRY=$(expr ${TRY} + 1)
  done

  printlogmess -n "${SCRIPTNAME}" -i "${SCRIPTID}" -x "${SCRIPTINDEX}" -l "$ERROR" -e "${ERRNO[2]}" -d "${DESCR[2]}" -1 "${TABLE}" -2 "${REFERENCENODE}" -3 "${REFERENCE}" -4 "${MISMATCH}" -5 "${MISMATCHVALUE}"
  return 1
}

if [ ${#DBSYNC_NODE[@]} -lt 2 ] ; then
  SCRIPTINDEX=$(addOneToIndex $SCRIPTINDEX)
  printlogmess -n "${SCRIPTNAME}" -i "${SCRIPTID}" -x "${SCRIPTINDEX}" -l "$ERROR" -e "${ERRNO[6]}" -d "${DESCR[6]}" -1 "at least two nodes must be set in DBSYNC_NODE"
  exit
fi

if [ ${#SYNCTABLE[@]} -lt 1 ] ; then
  SCRIPTINDEX=$(addOneToIndex $SCRIPTINDEX)
  printlogmess -n "${SCRIPTNAME}" -i "${SCRIPTID}" -x "${SCRIPTINDEX}" -l "$ERROR" -e "${ERRNO[6]}" -d "${DESCR[6]}" -1 "no tables set in SYNCTABLE"
  exit
fi

if [ ! -x "${MYSQL_BIN}" ] ; then
  SCRIPTINDEX=$(addOneToIndex $SCRIPTINDEX)
  printlogmess -n "${SCRIPTNAME}" -i "${SCRIPTID}" -x "${SCRIPTINDEX}" -l "$ERROR" -e "${ERRNO[6]}" -d "${DESCR[6]}" -1 "mysql client not found at ${MYSQL_BIN}"
  exit
fi

for (( i = 0 ;  i < ${#SYNCTABLE[@]} ; i++ )) ; do
  SCRIPTINDEX=$(addOneToIndex $SCRIPTINDEX)
  compare_table "${SYNCTABLE[$i]}" "${SYNCCUTOFF[$i]}" "${SCRIPTINDEX}"
  if [ $? -ne 0 ] ; then
    ERRSTATUS=$(expr ${ERRSTATUS} + 1)
    GLOBALERRMESSAGE="${GLOBALERRMESSAGE};${SYNCTABLE[$i]}"
  fi
done

SCRIPTINDEX=$(addOneToIndex $SCRIPTINDEX)
if [ ${ERRSTATUS} -eq 0 ] ; then
  printlogmess -n "${SCRIPTNAME}" -i "${SCRIPTID}" -x "${SCRIPTINDEX}" -l "$INFO" -e "${ERRNO[7]}" -d "${DESCR[7]}" -1 "${#SYNCTABLE[@]}" -2 "${#DBSYNC_NODE[@]}"
else
  printlogmess -n "${SCRIPTNAME}" -i "${SCRIPTID}" -x "${SCRIPTINDEX}" -l "$ERROR" -e "${ERRNO[8]}" -d "${DESCR[8]}" -1 "${ERRSTATUS}" -2 "${GLOBALERRMESSAGE}"
fi
