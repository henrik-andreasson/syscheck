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
SCRIPTNAME=mariadb_jobs

# uniq ID of script (please use in the name of this file also for convinice for finding next availavle number)
SCRIPTID=940

# how many info/warn/error messages
NO_OF_ERR=2
initscript $SCRIPTID $NO_OF_ERR 3
getconfig "mariadb"


INPUTARGS=`/usr/bin/getopt --options "hsj:l" --long "help,screen,listjob,job:" -- "$@"`
if [ $? != 0 ] ; then help ; fi
eval set -- "$INPUTARGS"

while true; do
  case "$1" in
    -j|--job ) jobname=$2; shift 2;;
    -l|--listjob ) listjob=1; shift;;
    -s|--screen ) PRINTTOSCREEN=1; shift;;
    -h|--help )   schelp;exit;shift;;
    --) break ;;
  esac
done


# main part of script

if [ "x${listjob}" == "x1" ] ; then
	for (( i = 0 ;  i < ${#DBJOBS_SQL[@]} ; i++ )) ; do
		echo "$i. ${DBJOBS_NAME[$i]} - ${DBJOBS_SQL[$i]}"
	done
elif [ "x${jobname}" != "x" ] ; then
    SCRIPTINDEX=$(addOneToIndex $SCRIPTINDEX)

    sqlret=$(echo "${DBJOBS_SQL[${jobname}]}" | $MYSQL_BIN -u root --password="${MYSQLROOT_PASSWORD}" | grep -v "count" | tr '\n' ';')
    retcode=$?
    if [ $retcode -eq 0 ] ; then
        printlogmess -n "${SCRIPTNAME}" -i "${SCRIPTID}" -x "${SCRIPTINDEX}" -l "$INFO"  -e "${ERRNO[1]}" -d "${DESCR[1]}" -1 "${DBJOBS_NAME[$jobname]}" -2 "${sqlret}"
    else
        printlogmess -n "${SCRIPTNAME}" -i "${SCRIPTID}" -x "${SCRIPTINDEX}" -l "$ERROR" -e "${ERRNO[2]}" -d "${DESCR[2]}" -1 "${DBJOBS_NAME[$jobname]}" -2 "${sqlret}"
    fi


else

	for (( i = 0 ;  i < "${#DBJOBS_SQL[@]}" ; i++ )) ; do
		SCRIPTINDEX=$(addOneToIndex $SCRIPTINDEX)
		sqlret=$(echo "${DBJOBS_SQL[0]}" | $MYSQL_BIN -u root --password="${MYSQLROOT_PASSWORD}" | grep -v "count" | tr '\n' ';')
		retcode=$?
		if [ $retcode -eq 0 ] ; then
			printlogmess -n "${SCRIPTNAME}" -i "${SCRIPTID}" -x "${SCRIPTINDEX}" -l "$INFO"  -e "${ERRNO[1]}" -d "${DESCR[1]}" -1 "${DBJOBS_NAME[$i]}" -2 "${sqlret}"
		else
			printlogmess -n "${SCRIPTNAME}" -i "${SCRIPTID}" -x "${SCRIPTINDEX}" -l "$ERROR" -e "${ERRNO[2]}" -d "${DESCR[2]}" -1 "${DBJOBS_NAME[$i]}" -2 "${sqlret}"
		fi

	done

fi
