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
SCRIPTNAME=healthcheck

# uniq ID of script (please use in the name of this file also for convinice for finding next availavle number)
SCRIPTID=33

# how many info/warn/error messages
NO_OF_ERR=6
initscript $SCRIPTID $NO_OF_ERR


INPUTARGS=`/usr/bin/getopt --options "hsvcinf" --long "help,screen,verbose,scriptid,scriptname,scripthumanname,full" -- "$@"`
if [ $? != 0 ] ; then schelp ; fi
eval set -- "$INPUTARGS"

while true; do
  case "$1" in
    -s|--screen  ) PRINTTOSCREEN=1; shift;;
    -v|--verbose ) PRINTVERBOSESCREEN=1 ; shift;;
    -i|--scriptid        ) scriptid          ; exit ; shift;;
    -n|--scriptname      ) scriptname        ; exit ; shift;;
    -a|--scripthumanname ) script_human_name ; exit ; shift;;
    -h|--help            ) schelp            ; exit ; shift;;
    -f|--full            ) PRINTFULL=1       ; shift;;
    --) break;;
  esac
done

# main part of script

restartProcess() {

  	local OPTIND

  	while getopts ":t:p:w:n:x:" opt; do
    case $opt in
     t)
        STARTCMD="$OPTARG"
       ;;
     p)
        STOPCMD="$OPTARG"
       ;;
     w)
        WAITTIME="$OPTARG"
       ;;
     n)
        PROCESSNAME="$OPTARG"
       ;;
     x)
        MAXRESTARTS="$OPTARG"
       ;;
     \?)
       printverbose "Invalid option: -$OPTARG" >&2
       return 1
       ;;
     :)
       printverbose "Option -$OPTARG requires an argument." >&2
       return 1
       ;;
    esac
  done

  if [ "x$STARTCMD" = "x" ] ; then printverbose "STARTCMD NOT SET" ; return 1; fi
  if [ "x$STOPCMD" = "x" ] ; then printverbose "STOPCMD NOT SET" ; return 1 ; fi
  if [ "x$WAITTIME" = "x" ] ; then printverbose "WAITTIME NOT SET" ; return 1 ; fi
  if [ "x$PROCESSNAME" = "x" ] ; then printverbose "PROCESSNAME NOT SET" ; return 1 ; fi
  if [ "x$MAXRESTARTS" = "x" ] ; then printverbose "MAXRESTARTS NOT SET" ; return 1 ; fi

  RESTARTLOG="${SYSCHECK_HOME}/var/auto-restart-${PROCESSNAME}.log"
  NOW=$(date +"%Y-%m-%d_%H.%M.%S")
  now_ts=$(date +"%s")
  restartsin24h=0
  if [ -f "${RESTARTLOG}" ] ; then
	while read line ; do
		let row="$row + 1"
		row_ts=$(echo $line | cut -f2 -d\;)
		let timediff="$now_ts - $row_ts"
		if [ $timediff -lt 86400 ] ; then
			let restartsin24h="$restartsin24h + 1"
		fi
	done < "${RESTARTLOG}"
  else
    touch "${RESTARTLOG}"
  fi

  if [ $restartsin24h -gt $MAXRESTARTS ] ; then
  	printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[5]} -d "${DESCR[5]}" -1 "${PROCESSNAME}" -2 "${restartsin24h}"
	return 1
  fi

  printtoscreen "stop command: <${STOPCMD}>"
  STOP_STATUS=$(eval ${STOPCMD} 2>&1)
  printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[4]} -d "${DESCR[4]}" -1 "${HEALTHCHECK_APP[$i]}" -2 "${STOP_STATUS}" -3 "${STOPCMD}" -4 "${restartsin24h}"
  sleep "${WAITTIME}"
  printtoscreen "start command: <${STARTCMD}>"
  START_STATUS=$(eval ${STARTCMD} 2>&1)
  printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[4]} -d "${DESCR[4]}" -1 "${HEALTHCHECK_APP[$i]}" -2 "${START_STATUS}" -3 "${STARTCMD}" -4 "${restartsin24h}"
  /bin/echo -e "${NOW};${now_ts};${STOPCMD};${STARTCMD}" >> "${RESTARTLOG}"
}

if [ "x${MAX_RESTARTS}" == "x" ] ; then
  printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[6]} -d "${DESCR[6]}"
fi

for (( i = 0 ;  i < ${#HEALTHCHECKURL[@]} ; i++ )) ; do
        SCRIPTINDEX=$(addOneToIndex $SCRIPTINDEX)

	if [ "x${PRINTFULL}" = "x1" ] ; then
		printtoscreen "Checking ${HEALTHCHECKURL_FULL[$i]}"
	fi

	if [ "x${CHECKTOOL}" = "xwget" ] ; then
	        STATUS=$(${CHECKTOOL} ${HEALTHCHECKURL[$i]} -T ${TIMEOUT} -t 1 2>/dev/null)
		FULLSTATUS=$(${CHECKTOOL} ${HEALTHCHECKURL_FULL[$i]} -T ${TIMEOUT} -t 1 2>/dev/null)
		if [ "x${PRINTFULL}" = "x1" ] ; then
			printtoscreen ${FULLSTATUS}
		fi
	elif [ "x${CHECKTOOL}" = "xcurl" ] ; then
	        STATUS=$(${CHECKTOOL} ${HEALTHCHECKURL[$i]} --connect-timeout ${TIMEOUT} --retry 1 2>/dev/null)
	        FULLSTATUS=$(${CHECKTOOL} ${HEALTHCHECKURL_FULL[$i]} --connect-timeout ${TIMEOUT} --retry 1 2>/dev/null)
		if [ "x${PRINTFULL}" = "x1" ] ; then
			printtoscreen ${FULLSTATUS}
		fi
	else
	        printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[3]} -d "${DESCR[3]}"
	fi
	FIXED_FULL_STATUS=$(echo "${FULLSTATUS}" | tr -d '\\' | tr -d "'"  | sed 's/%/%%/gi' | tr  '\n' ';' | tr -d '"')
	if [ "x$STATUS" != "xALLOK" ] ; then
		printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[2]} -d "${DESCR[2]}" -1 "${HEALTHCHECK_APP[$i]}" -2 "$FIXED_FULL_STATUS"
    		if [ "x${STOP_CMD[$i]}" != "x" -a  "x${START_CMD[$i]}" != "x" ] ; then
			restartProcess -n "${HEALTHCHECK_APP[$i]}" -p "${STOP_CMD[$i]}" -t "${START_CMD[$i]}" -w "${STOP_START_PAUSE}" -x "${MAX_RESTARTS}"
		fi
	else
		printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $INFO  -e ${ERRNO[1]} -d "${DESCR[1]}" -1 "${HEALTHCHECK_APP[$i]}" -2 "$FIXED_FULL_STATUS"
	fi

	if [ "x${PRINTFULL}" = "x1" ] ; then
		printtoscreen "----"
	fi

done
