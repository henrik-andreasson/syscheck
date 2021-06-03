#!/bin/bash

SYSCHECK_HOME="${SYSCHECK_HOME:-/opt/syscheck}" # use default if  unset
if [ ! -f ${SYSCHECK_HOME}/syscheck.sh ] ; then
  echo "Can't find $SYSCHECK_HOME/syscheck.sh"
  exit
fi

if [ ! -f ${SYSCHECK_HOME}/syscheck.sh ] ; then echo "Can't find $SYSCHECK_HOME/syscheck.sh" ;exit ; fi

# Import common definitions
source $SYSCHECK_HOME/config/syscheck-scripts.conf

# script name, used when integrating with nagios/icinga
SCRIPTNAME=cert_from_webserver

# uniq ID of script (please use in the name of this file also for convinice for finding next availavle number)
SCRIPTID=44

# how many info/warn/error messages
NO_OF_ERR=5
initscript $SCRIPTID $NO_OF_ERR

default_script_getopt $*

# main part of script


checkhttpscert () {
	INPUTARGS=$(/usr/bin/getopt --options "s:p:w:e:i:" --long "servicename:,port:,warn:,err:,ip:" -- "$@")
	if [ $? != 0 ] ; then schelp ; fi
	eval set -- "$INPUTARGS"

	while true; do
	  case "$1" in
	    -s|--servicename     ) SERVICENAME=$2   ; shift 2 ;;
            -p|--portno          ) PORTNO=$2        ; shift 2 ;;
	    -w|--warn            ) WARNDAYS=$2      ; shift 2 ;;
	    -e|--err             ) ERRDAYS=$2       ; shift 2 ;;
	    -i|--ip              ) HOST_IP=$2       ; shift 2 ;;
	    --) break;;
	  esac
	done

  if [ "x$SERVICENAME" = "x" ] ; then
    printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[5]} -d "${DESCR[5]}" -1 "No ServiceName Configured"
    GLOBALERRMESSAGE="${GLOBALERRMESSAGE};${DESCR[3]} $CRLNAME"
    ERRSTATUS=$(expr $ERRSTATUS + 1)
    return
  fi

  if [ "x$WARNDAYS" != "xdefault" ] ; then
    let WARNMIN="$WARNDAYS * 1440"
  fi

  if [ "x$ERRDAYS" != "xdefault" ] ; then
    let ERRMIN="$ERRDAYS * 1440"
  fi

  if [ "x$HOST_IP" == "xdefault" ] ; then
    ARGCONNECT="-connect $SERVICENAME:$PORTNO"
  else
    ARGCONNECT="-connect $HOST_IP:$PORTNO -servername $SERVICENAME"
  fi

  cd /tmp
  outname=$(mktemp)
  echo "" | openssl s_client $ARGCONNECT  >> $outname 2>&1
  check_outname=$(cat "$outname" | grep "Server certificate")
  if [ "x$outname" == "x" ] ; then
      printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[7]} -d "${DESCR[7]}" -1 "${SERVICENAME}" -2 "${PORTNO}" -3 "${HOST_IP}" -4 "${ERRDAYS}" 
      ERRSTATUS=$(expr $ERRSTATUS + 1)
      GLOBALERRMESSAGE="${GLOBALERRMESSAGE};${DESCR[7]}"
      return 1
  fi

  servcert=0
  certbegin=0
  certfile=$(mktemp)
  while read line ; do

          echo $line >> /tmp/cert.new

          if [ "x$line" = "xServer certificate" ] ; then
                  servcert=1
          fi

          if [ "x$line" = "x-----BEGIN CERTIFICATE-----" -a $servcert -eq 1 ] ; then
                  certbegin=1
          fi

          if [ $certbegin -eq 1 ] ; then
            echo $line >> $certfile
          fi

          if [ "x$line" = "x-----END CERTIFICATE-----" ] ; then
              break
          fi

  done < $outname

  issuer=$(openssl x509 -in "$certfile" -issuer -noout | sed 's/issuer=//')
  subject=$(openssl x509 -in "$certfile" -issuer -noout | sed 's/subject=//')
  certexpiredate=$(openssl x509 -in "$certfile" -enddate  -noout | sed 's/notAfter=//')

  expireinfo=$($SYSCHECK_HOME/lib/cmp_dates.py --warnminutes="${WARNMIN}" --errorminutes="${ERRMIN}"  "$(date +'%b %d %H:%M:%S %Y %Z')" "${certexpiredate}")
  retcode=$?
  if [ $retcode -eq 0 ] ; then
    printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $INFO -e ${ERRNO[1]} -d "${DESCR[1]}" -1 "${SERVICENAME}" -2 "${PORTNO}" -3 "${HOST_IP}"

  elif [ $retcode -eq 1 ] ; then
    printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $WARN -e ${ERRNO[2]} -d "${DESCR[2]}" -1 "${SERVICENAME}" -2 "${PORTNO}" -3 "${HOST_IP}" -4 "${WARNDAYS}" -5 "${certexpiredate}"
    WARNSTATUS=$(expr $WARNSTATUS + 1)
    GLOBALERRMESSAGE="${GLOBALWARNESSAGE};WARN ${SERVICENAME} ${PORTNO} ${HOST_IP}"

  elif [ $retcode -eq 2 ] ; then
    printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[3]} -d "${DESCR[3]}" -1 "${SERVICENAME}" -2 "${PORTNO}" -3 "${HOST_IP}" -4 "${ERRDAYS}"  -5 "${certexpiredate}"
    ERRSTATUS=$(expr $ERRSTATUS + 1)
    GLOBALERRMESSAGE="${GLOBALERRMESSAGE};ERR ${SERVICENAME} ${PORTNO} ${HOST_IP}"

  elif [ $retcode -eq 3 ] ; then
    printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[8]} -d "${DESCR[8]}" -1 "${SERVICENAME}" -2 "${PORTNO}" -3 "${HOST_IP}" -4 "${ERRDAYS}"  -5 "${certexpiredate}"
    ERRSTATUS=$(expr $ERRSTATUS + 1)
    GLOBALERRMESSAGE="${GLOBALERRMESSAGE};ERR ${SERVICENAME} ${PORTNO} ${HOST_IP}"

  else

    #TODO: case should  not happen not happen not happen
    printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[8]} -d "${DESCR[8]}" -1 "${SERVICENAME}" -2 "${PORTNO}" -3 "${HOST_IP}" -4 "${ERRDAYS}"  -5 "${certexpiredate}"
    ERRSTATUS=$(expr $ERRSTATUS + 1)
    GLOBALERRMESSAGE="${GLOBALERRMESSAGE};ERR ${SERVICENAME} ${PORTNO} ${HOST_IP}"

  fi
  rm "$outname"
  rm "$certfile"
#  echo "certfile: $certfile"
}


# global ERRSTATUS for all crl:s (0 is ok)
ERRSTATUS=0
WARNSTATUS=0
GLOBALERRMESSAGE=""

for (( i = 0 ;  i < ${#SERVICENAME[@]} ; i++ )) ; do
    SCRIPTINDEX=$(addOneToIndex $SCRIPTINDEX)
    if [ "x${WARNTIME[$i]}" != "x" ] ; then
      WARNTIME=${WARNTIME[$i]}
    else
      WARNTIME="default"
    fi
    if [ "x${ERRTIME[$i]}" != "x" ] ; then
      ERRTIME=${ERRTIME[$i]}
    else
      ERRTIME="default"
    fi
    if [ "x${HOST_IP[$i]}" != "x" ] ; then
      HOST_IP="${HOST_IP[$i]}"
    else
      HOST_IP="default"
    fi

    checkhttpscert --servicename "${SERVICENAME[$i]}" -p "${PORTNO[$i]}" -i "${HOST_IP}" -w "${WARNTIME}" -e "${ERRTIME}"

done

# send the summary message (00)
SCRIPTINDEX=00
if [ "x${ERRSTATUS}" != "x0" ] ; then
    printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[6]} -d "${DESCR[6]}" -1 "${GLOBALERRMESSAGE}"
elif [ "x${WARNSTATUS}" != "x0" ] ; then
    printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $WARN  -e ${ERRNO[5]} -d "${DESCR[5]}" -1 "${GLOBALWARNMESSAGE}"
else
    printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $INFO  -e ${ERRNO[4]} -d "${DESCR[4]}"
fi
