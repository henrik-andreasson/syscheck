#!/bin/bash

SYSCHECK_HOME="${SYSCHECK_HOME:-/opt/syscheck}" # use default if  unset
if [ ! -f ${SYSCHECK_HOME}/syscheck.sh ] ; then
  echo "Can't find $SYSCHECK_HOME/syscheck.sh"
  exit
fi

## Import common definitions ##
source $SYSCHECK_HOME/config/syscheck-scripts.conf

# script name, used when integrating with nagios/icinga
SCRIPTNAME=cluster_health

# uniq ID of script (please use in the name of this file also for convinice for finding next availavle number)
SCRIPTID=40

# number of errors in summary
ERRORNUM=0

# how many info/warn/error messages
NO_OF_ERR=8

initscript $SCRIPTID $NO_OF_ERR
getconfig "mariadb"

default_script_getopt $*

# main part of script

SCRIPTINDEX=$(addOneToIndex $SCRIPTINDEX)
pid=$($SYSCHECK_HOME/lib/proc_checker.sh $pidfile $procname)
if [ "x$pid" = "x" ] ; then
    printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[2]} -d "${DESCR[2]}"
    (( ERRORNUM++ )) || true
else
    printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $INFO -e ${ERRNO[1]} -d "${DESCR[1]}"
fi

# Check Select in database

SCRIPTINDEX=$(addOneToIndex $SCRIPTINDEX)

if [ "x${MYSQL_BIN}" = "x" -o "x${DB_NAME}" = "x" -o "x${DB_TEST_TABLE}" = "x" ] ; then
    printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e  ${ERRNO[4]} -d "${DESCR[4]}" -1 "MYSQL_BIN, DB_NAME and DB_TEST_TABLE must be set, see config/mariadb.conf"
    (( ERRORNUM++ )) || true
else
    status=$(echo "SELECT * FROM $DB_TEST_TABLE LIMIT 1" | $MYSQL_BIN $DB_NAME 2>&1 > /dev/null)
    if [ $? -ne 0 ] ; then
        printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e  ${ERRNO[4]} -d "${DESCR[4]}" -1 "$status"
        (( ERRORNUM++ )) || true
    else
        printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $INFO -e  ${ERRNO[3]} -d "${DESCR[3]}"
    fi
fi

####################
# string values compare with test, only the float operands need awk
Sub_Compare(){
  VALUE=$1
  OPERAND=$2
  EXPECTED=$3
  case "$OPERAND" in
    "="|"==") [ "$VALUE" = "$EXPECTED" ] ;;
    "!=")     [ "$VALUE" != "$EXPECTED" ] ;;
    *)        awk -v a="$VALUE" -v b="$EXPECTED" "BEGIN{ exit !(a $OPERAND b) }" ;;
  esac
}

# Check Galera cluster
Sub_Check_Cluster(){
    CLUSTER=$1
    RESULT=$2
    SCRIPTINDEX=$3
    OPERAND=$4

    STATUS=$(echo "show status like '${CLUSTER}';" | $MYSQL_BIN 2>&1)
    retcode=$?
    if [ $retcode -eq 0 ] ; then
      STATUS=$(echo "$STATUS" | cut -f2 | sed '/^Value$/d;/^$/d')
    fi
    if [ $retcode -ne 0 -o "x${STATUS}" = "x" ] ; then
      printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[6]} -d "${DESCR[6]}" -1 "$CLUSTER $STATUS should be $RESULT"
      (( ERRORNUM++ )) || true
    elif Sub_Compare "${STATUS}" "${OPERAND}" "${RESULT}" ; then
      printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[6]} -d "${DESCR[6]}" -1 "$CLUSTER $STATUS should be $RESULT"
      (( ERRORNUM++ )) || true
    else
   	  printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $INFO -e ${ERRNO[5]}  -d "${DESCR[5]}" -1 "${CLUSTER} $STATUS"
    fi
}


for (( i = 0 ;  i < ${#CLUSTER[@]} ; i++ )) ; do
    SCRIPTINDEX=$(addOneToIndex $SCRIPTINDEX)
    Sub_Check_Cluster ${CLUSTER[$i]}  ${RESULT[$i]} $SCRIPTINDEX ${OPERAND[$i]}
done

# send the summary message (00)
SCRIPTINDEX=00
if [ "$ERRORNUM" -gt 0 ] ; then
    printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[8]} -d "${DESCR[8]}" -1 "number of errors detected: ${ERRORNUM}"
else
    printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $INFO  -e ${ERRNO[7]} -d "${DESCR[7]}"
fi

