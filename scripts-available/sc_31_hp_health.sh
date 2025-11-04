#!/bin/bash

SYSCHECK_HOME="${SYSCHECK_HOME:-/opt/syscheck}" # use default if  unset
if [ ! -f ${SYSCHECK_HOME}/syscheck.sh ] ; then
  echo "Can't find $SYSCHECK_HOME/syscheck.sh"
  exit
fi

if [ ! -f ${SYSCHECK_HOME}/syscheck.sh ] ; then echo "Can't find $SYSCHECK_HOME/syscheck.sh" ;exit ; fi

## Import common definitions ##
source $SYSCHECK_HOME/config/syscheck-scripts.conf

# script name, used when integrating with nagios/icinga
SCRIPTNAME=hp_health

# uniq ID of script (please use in the name of this file also for convinice for finding next availavle number)
SCRIPTID=31

# how many info/warn/error messages
NO_OF_ERR=5
initscript $SCRIPTID $NO_OF_ERR

default_script_getopt $*

# main part of script


hppsu () {
        COMMAND=$($HP_HEALTH_TOOL serverinfo --power | grep -E "State|Health" | cut -f2 -d":" | awk '{printf "%s;",$1}')
        STATUSPSU1=`echo $COMMAND | cut -f1 -d\; | grep -i "ok"`
        CONDPSU1=`echo $COMMAND | cut -f2 -d\; | grep -i "enabled"`
        STATUSPSU2=`echo $COMMAND | cut -f3 -d\; | grep -i "ok"`
        CONDPSU2=`echo $COMMAND | cut -f4 -d\; | grep -i "enabled"`
        STATUSPSU3=`echo $COMMAND | cut -f5 -d\; | grep -i "ok"`
        CONDPSU3=`echo $COMMAND | cut -f6 -d\; | grep -i "enabled"`

	SCRIPTINDEX=$(addOneToIndex $SCRIPTINDEX)
        if [ "x$STATUSPSU1" != "x" -a "x$CONDPSU1" != "x" ] ; then
                printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $INFO -e ${ERRNO[1]} -d "${DESCR[1]}" -1 "PSU1"
        else
                printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[2]} -d "${DESCR[2]}" -1 "PSU1 $STATUSPSU1 $CONDPSU1"
		ERRSTATUS=1
        fi

	SCRIPTINDEX=$(addOneToIndex $SCRIPTINDEX)
        if [ "x$STATUSPSU2" != "x" -a "x$CONDPSU2" != "x" ] ; then
                printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $INFO  -e ${ERRNO[1]} -d "${DESCR[1]}" -1 "PSU2"
        else
                printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[2]} -d "${DESCR[2]}" -1 "PSU2 $STATUSPSU2 $CONDPSU2"
		ERRSTATUS=1
        fi

	SCRIPTINDEX=$(addOneToIndex $SCRIPTINDEX)
        if [ "x$STATUSPSU3" != "x" -a "x$CONDPSU3" != "x" ] ; then
                printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $INFO  -e ${ERRNO[1]} -d "${DESCR[1]}" -1 "PSU Group"
        else
                printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[2]} -d "${DESCR[2]}" -1 "PSU Group $STATUSPSU3 $CONDPSU3"
		ERRSTATUS=1
        fi
}

hptemp () {

 parse_temp () {
  {
	$HP_HEALTH_TOOL serverinfo --thermals | grep -Evi '(^-|restful|copyright)' | grep -E "Location|Current|Critical|Health" | cut -f2 -d":" | awk '{print $1}'
  } | 
 (set -f ; unset IFS ; set -- $(cat)
 while [ $# -ge 4 ] ; do {
	printf '%s;%s;%s;%s\n' "$1" "$2" "$3" "$4"
	shift 4 ; } done
 printf '%s' "$@")
 }

    for TEMPINPUT in $(parse_temp) ; do
      TEMPNAME=$(echo $TEMPINPUT | cut -f1 -d\;)
      TEMPVAL=$(echo $TEMPINPUT | cut -f2 -d\;)
      TEMPLIMIT=$(echo $TEMPINPUT | cut -f3 -d\; |sed 's,C/.*,,')
      TEMPHEALTH=$(echo $TEMPINPUT | cut -f4 -d\; |sed 's,C/.*,,')
      SCRIPTINDEX=$(addOneToIndex $SCRIPTINDEX)

    echo ${HPTEMP}|egrep -q "${TEMPNO} "
    if [[ "x${TEMPLIMIT}" = @(xNone|x-) ]];then
      printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX}  -l $INFO -e ${ERRNO[1]} -d "${DESCR[1]}" -1 "TEMP ${TEMPNO} ${TEMPNAME} is known not to give any threshold ($TEMPINPUT)"
      #continue
    else
      if [ "x${TEMPVAL}" = "x" ] ; then
        printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[2]} -d "${DESCR[2]}" -1 "TEMP  ${TEMPNO} ${TEMPNAME} did not return any value for CURRENT temp ($TEMPINPUT)"
        continue
      fi
      if [ "x${TEMPLIMIT}" = "x" ] ; then
        printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[2]} -d "${DESCR[2]}" -1 "TEMP  ${TEMPNO} ${TEMPNAME} did not return any value for LIMIT temp ($TEMPINPUT)"
        continue
      fi
      if [ ${TEMPVAL} -gt ${TEMPLIMIT} ] ; then
        printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[2]} -d "${DESCR[2]}" -1 "TEMP ${TEMPNO} ${TEMPNAME} Current: ${TEMPVAL} Limit: ${TEMPLIMIT} (celsius)"
	ERRSTATUS=1
      else
        printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $INFO  -e ${ERRNO[1]} -d "${DESCR[1]}" -1 "TEMP ${TEMPNO} ${TEMPNAME} Current: ${TEMPVAL} Limit: ${TEMPLIMIT} (celsius)"
      fi
    fi
  done
}

hpfans () {

 parse_fans () {
  {
	$HP_HEALTH_TOOL serverinfo --fans | grep -Evi '(^-|restful|copyright)' | grep -E "Reading|Health" | cut -f2 -d":" | awk '{print $1}'
  } | 
 (set -f ; unset IFS ; set -- $(cat)
 while [ $# -ge 2 ] ; do {
	printf '%s;%s\n' "$1" "$2"
	shift 2 ; } done
 printf '%s' "$@")
 }

    for FANSINPUT in $(parse_fans) ; do

      FANPERCENT=$(echo $FANSINPUT | cut -f1 -d\;)
      FANSTATUS=$(echo $FANSINPUT | cut -f2 -d\;)
      SCRIPTINDEX=$(addOneToIndex $SCRIPTINDEX)

      if [ "x${FANSTATUS}" !=  "xOK" ] ; then
        printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[3]} -d "${DESCR[3]}" -1 "FAN(${FANSTATUS}) NOT in normal operation ${FANPERCENT}%" 
	ERRSTATUS=1
      else
        printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $INFO  -e ${ERRNO[1]} -d "${DESCR[1]}" -1 "FAN is ${FANSTATUS} in normal operation ${FANPERCENT}%"
      fi
    done
}

if [ ! -x $HP_HEALTH_TOOL ] ; then
    printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[4]} -d "${DESCR[4]}" -1 "$HP_HEALTH_TOOL"
    exit
fi
lockfilewait () {
        LOCKFILE=$1
# lock file check/wait
    if [ -f ${LOCKFILE} ] ; then
    lockFileIsChangedAt=$(stat --format="%Z" ${LOCKFILE})
    nowSec=$(date +"%s")
    let diff="$nowSec-$lockFileIsChangedAt"
    while [ $diff -lt ${LOCKFILE_MAX_WAIT_SEC} ] ; do
        printtoscreen "Lockfile (${LOCKFILE}) exist, waiting for maximum ${LOCKFILE_MAX_WAIT_SEC} sec, now at $diff "
        sleep 1
        nowSec=$(date +"%s")
        let diff="$nowSec-$lockFileIsChangedAt"
    done
    lockFileIsChangedAtHuman=$(stat --format="%z" ${LOCKFILE})
    printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $WARN -e ${ERRNO[5]} -d "${DESCR[5]}" -1 "$lockFileIsChangedAtHuman"
    rm ${LOCKFILE}
fi
}
LOCKFILE="${SYSCHECK_HOME}/var/${SCRIPTID}.lock"
lockfilewait ${LOCKFILE}
touch ${LOCKFILE}

# global ERRSTATUS for all healthchecks (0 is ok)
ERRSTATUS=0
WARNSTATUS=0
GLOBALERRMESSAGE=""
GENDESCR="All HP Healthchecks are OK"
GENERR="Error in HP Healthcheck"
GENWARN="Warning in HP Healthcheck"



hppsu
hptemp
hpfans



# send the summary message (00)
SCRIPTINDEX=00
if [ "x${ERRSTATUS}" != "x0" ] ; then
    printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[2]} -d "${GENERR}" -1 "${GLOBALERRMESSAGE}"
elif [ "x${WARNSTATUS}" != "x0" ] ; then
    printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $WARN  -e ${ERRNO[5]} -d "${GENWARN}" -1 "${GLOBALERRMESSAGE}"
else
    printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $INFO  -e ${ERRNO[1]} -d "${GENDESCR}"
fi


rm ${LOCKFILE}
