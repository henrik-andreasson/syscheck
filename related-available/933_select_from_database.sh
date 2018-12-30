#!/bin/bash

SYSCHECK_HOME="${SYSCHECK_HOME:-/opt/syscheck}" # use default if  unset
if [ ! -f ${SYSCHECK_HOME}/syscheck.sh ] ; then
  echo "Can't find $SYSCHECK_HOME/syscheck.sh"
  exit
fi

if [ ! -f ${SYSCHECK_HOME}/syscheck.sh ] ; then echo "Can't find $SYSCHECK_HOME/syscheck.sh" ;exit ; fi

## Import common definitions ##
source $SYSCHECK_HOME/config/related-scripts.conf

# script name, used when integrating with nagios/icinga
SCRIPTNAME=select_from_database

# uniq ID of script (please use in the name of this file also for convinice for finding next availavle number)
SCRIPTID=933

# how many info/warn/error messages
NO_OF_ERR=2
initscript $SCRIPTID $NO_OF_ERR || exit 1;
getconfig "mariadb"

# get command line arguments
INPUTARGS=`/usr/bin/getopt --options "hsv" --long "help,screen,verbose" -- "$@"`
if [ $? != 0 ] ; then schelp ; fi
#echo "TEMP: >$TEMP<"
eval set -- "$INPUTARGS"

while true; do
  case "$1" in
    -s|--screen  ) PRINTTOSCREEN=1; shift;;
    -v|--verbose ) PRINTVERBOSESCREEN=1 ; shift;;
    -h|--help )   schelp;exit;shift;;
    --) break;;
  esac
done


# main part of script

date +'%Y-%m-%d_%H.%m.%S'> ${SYSCHECK_HOME}/var/${SQL_SUMMARY_FILE}

for (( j=0; j < ${#SQL_SELECT[@]} ; j++ )){

	SCRIPTINDEX=$(addOneToIndex $SCRIPTINDEX)
	echo "${SQL_SELECT[$j]}" | $MYSQL_BIN ${DB_NAME} -u ${DB_USER} --password="${DB_PASSWORD}" --skip-column-names >  ${SYSCHECK_HOME}/var/${OUTFILE[$j]}

	if [ $? -eq 0 ] ; then
	        printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX}  $INFO ${ERRNO[1]} "${DESCR[1]}" "${SQL_DESC[$j]}"
	else
	        printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX}  $ERROR ${ERRNO[2]} "${DESCR[2]}" "${SQL_DESC[$j]}"
	fi

	echo "### ${SQL_DESC[$j]} ###" >> ${SYSCHECK_HOME}/var/${SQL_SUMMARY_FILE}
	cat ${SYSCHECK_HOME}/var/${OUTFILE[$j]} >> ${SYSCHECK_HOME}/var/${SQL_SUMMARY_FILE}
}
