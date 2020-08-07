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
SCRIPTNAME=crl_from_webserver

# uniq ID of script (please use in the name of this file also for convinice for finding next availavle number)
SCRIPTID=08

# how many info/warn/error messages
NO_OF_ERR=9
initscript $SCRIPTID $NO_OF_ERR

default_script_getopt $*

# main part of script


checkcrl () {

	INPUTARGS=$(/usr/bin/getopt --options "c:w:e:i:" --long "crl:,warn:,err:,ip:" -- "$@")
	if [ $? != 0 ] ; then schelp ; fi
	eval set -- "$INPUTARGS"

	while true; do
	  case "$1" in
	    -c|--crl             ) CRLNAME=$2            ; shift 2 ;;
	    -w|--warn            ) LIMITMINUTES=$2       ; shift 2 ;;
	    -e|--err             ) ERRMINUTES=$2         ; shift 2 ;;
	    -i|--ip              ) CRL_HOST_IPx=$2       ; shift 2 ;;
	    --) break;;
	  esac
	done

  if [ "x$CRLNAME" = "x" ] ; then
    printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[5]} -d "${DESCR[5]}" -1 "No CRL Configured"
    GLOBALERRMESSAGE="${GLOBALERRMESSAGE};${DESCR[3]} $CRLNAME"
    ERRSTATUS=$(expr $ERRSTATUS + 1)
    return
  fi


  # Limitminutes is now optional, if not configured the limits is crl WARN: validity/2 ERROR: validity/4 eg: CRL is valid to 12h, warn will be 6h and error 3h
  if [ "x$LIMITMINUTES" != "xdefault" ] ; then
    ARGWARNMIN="--warnminutes=$LIMITMINUTES"
  fi

  if [ "x$ERRMINUTES" != "xdefault" ] ; then
    ARGERRMIN="--errorminutes=$ERRMINUTES"
  fi

  # rework of url to access the server via ip instead and send the hostname in the "Host" header variable
  if [ "x$CRL_HOST_IPx" != "xdefault" ] ; then
    HOSTNAME_FROM_URL=$(echo "${CRLNAME}" | cut -d'/' -f3 | cut -d':' -f1)
    PATH_FROM_URL=$(echo "${CRLNAME}" | cut -d'/' -f4-)

    CHECK_HOST_ARG1="--header"
    CHECK_HOST_ARG2="Host: ${HOSTNAME_FROM_URL}"
    CRLNAME="http://${CRL_HOST_IPx}/${PATH_FROM_URL}"
  fi


  cd /tmp
  outname=$(mktemp)
  if [ "x${CHECKTOOL}" = "xwget" ] ; then

    ${CHECKTOOL} ${CRLNAME}  -T ${TIMEOUT} -t ${RETRIES}    ${CHECK_HOST_ARG1} "${CHECK_HOST_ARG2}"      -O $outname -o /dev/null

    if [ $? -ne 0 ] ; then
      printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[3]} -d "${DESCR[3]}" -1 "$CRLNAME"
      ERRSTATUS=$(expr $ERRSTATUS + 1)
      GLOBALERRMESSAGE="${GLOBALERRMESSAGE};${DESCR[3]} $CRLNAME"
      return 1
    fi

  elif [ "x${CHECKTOOL}" = "xcurl" ] ; then

    ${CHECKTOOL} ${CRLNAME} --retry ${RETRIES} ${CHECK_HOST_ARG1} "${CHECK_HOST_ARG2}" --max-time ${TIMEOUT} --output $outname 2>/dev/null

    if [ $? -ne 0 ] ; then
      printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[3]} -d "${DESCR[3]}" -1 "$CRLNAME"
      GLOBALERRMESSAGE="${GLOBALERRMESSAGE};${DESCR[3]} $CRLNAME"
      ERRSTATUS=$(expr $ERRSTATUS + 1)
      return 1
    fi
  else
    printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[3]} -d "${DESCR[3]}"
    ERRSTATUS=$(expr $ERRSTATUS + 1)
    GLOBALERRMESSAGE="${GLOBALERRMESSAGE};${DESCR[3]} $CRLNAME"
  fi


  # file not found where it should be
  if [ ! -f $outname ] ; then
    printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[1]} -d "${DESCR[1]}" -1 "$CRLNAME"
    ERRSTATUS=$(expr $ERRSTATUS + 1)
    GLOBALERRMESSAGE="${GLOBALERRMESSAGE};${DESCR[1]} $CRLNAME"
    return 2
  fi

  CRL_FILE_SIZE=`stat -c"%s" $outname`

  # stat return check
  if [ $? -ne 0 ] ; then
    printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[4]} -d "${DESCR[4]}" -1 "$CRLNAME"
    ERRSTATUS=$(expr $ERRSTATUS + 1)
    GLOBALERRMESSAGE="${GLOBALERRMESSAGE};${DESCR[4]} $CRLNAME"
    return 3
  fi

  # crl of 0 size?
  if [ "x$CRL_FILE_SIZE" = "x0" ] ; then
    printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[4]} -d "${DESCR[4]}" -1 "$CRLNAME"
    ERRSTATUS=$(expr $ERRSTATUS + 1)
    GLOBALERRMESSAGE="${GLOBALERRMESSAGE};${DESCR[4]} $CRLNAME"
    return 4
  fi


  LASTUPDATE=$(openssl crl -inform der -in $outname -lastupdate -noout | sed 's/lastUpdate=//')
  if [ "x${LASTUPDATE}" = "x" ] ; then
    printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[1]} -d "${DESCR[1]}" -1 "$CRLNAME (Cant parse file,lastupdate)"
    ERRSTATUS=$(expr $ERRSTATUS + 1)
    GLOBALERRMESSAGE="${GLOBALERRMESSAGE};$CRLNAME (Cant parse file,lastupdate)"
  fi

  NEXTUPDATE=$(openssl crl -inform der -in $outname -nextupdate -noout | sed 's/nextUpdate=//')
  if [ "x${NEXTUPDATE}" = "x" ] ; then
    printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[1]} -d "${DESCR[1]}" -1 "$CRLNAME (Cant parse file,nextupdate)"
    ERRSTATUS=$(expr $ERRSTATUS + 1)
    GLOBALERRMESSAGE="${GLOBALERRMESSAGE};$CRLNAME (Cant parse file,nextupdate)"
  fi

  CRLMESSAGE=$(${SYSCHECK_HOME}/lib/cmp_dates.py "$LASTUPDATE" "$NEXTUPDATE" ${ARGWARNMIN} ${ARGERRMIN} )
  CRLCHECK=$?
  if [ "x$CRLCHECK" = "x" ] ; then
    printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[1]} -d "${DESCR[1]}" -1 "$CRLNAME (Cant parse file)"
    ERRSTATUS=$(expr $ERRSTATUS + 1)
    GLOBALERRMESSAGE="${GLOBALERRMESSAGE};$CRLNAME (Cant parse file)"

  elif [ $CRLCHECK -eq 3 ] ; then
    printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[6]} -d "${DESCR[6]}" -1 "$CRLNAME: ${CRLMESSAGE}"
    ERRSTATUS=$(expr $ERRSTATUS + 1)
    GLOBALERRMESSAGE="${GLOBALERRMESSAGE};${CRLNAME} ${CRLMESSAGE}"

  elif [ $CRLCHECK -eq 2 ] ; then
    printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[7]} -d "${DESCR[7]}" -1 "$CRLNAME: ${CRLMESSAGE}"
    ERRSTATUS=$(expr $ERRSTATUS + 1)
    GLOBALERRMESSAGE="${GLOBALERRMESSAGE};${CRLNAME} ${CRLMESSAGE}"

  elif [ $CRLCHECK -eq 1 ] ; then
    printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $WARN -e ${ERRNO[8]} -d "${DESCR[8]}" -1 "$CRLNAME: ${CRLMESSAGE}"
    WARNSTATUS=$(expr $WARNSTATUS + 1)
    GLOBALERRMESSAGE="${GLOBALERRMESSAGE};${CRLNAME} ${CRLMESSAGE}"

  elif [ $CRLCHECK -eq 0 ] ; then
    printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $INFO -e ${ERRNO[2]} -d "${DESCR[2]}" -1 "$CRLNAME: ${CRLMESSAGE}"

  else
    printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[1]} -d "${DESCR[1]}" -1 "$CRLNAME: problem calculating validity"
    ERRSTATUS=$(expr $ERRSTATUS + 1)
    GLOBALERRMESSAGE="${GLOBALERRMESSAGE};${CRLNAME} problem calculating validity"
  fi
  rm "$outname"
}

#force Timezone to UTC
export TZ=UTC

# global ERRSTATUS for all crl:s (0 is ok)
ERRSTATUS=0
WARNSTATUS=0
GLOBALERRMESSAGE=""

for (( i = 0 ;  i < ${#CRLS[@]} ; i++ )) ; do
    SCRIPTINDEX=$(addOneToIndex $SCRIPTINDEX)
    if [ "x${MINUTES[$i]}" != "x" ] ; then
      MINUTESx=${MINUTES[$i]}
    else
      MINUTESx="default"
    fi
    if [ "x${ERRMIN[$i]}" != "x" ] ; then
      ERRMINx=${ERRMIN[$i]}
    else
      ERRMINx="default"
    fi
    if [ "x${CRL_HOST_IP[$i]}" != "x" ] ; then
      CRL_HOST_IPx="${CRL_HOST_IP[$i]}"

    elif [ "x${CRL_HOST_IP_ALL}" != "x" ] ; then
      CRL_HOST_IPx="${CRL_HOST_IP_ALL}"

    else
      CRL_HOST_IPx="default"
    fi

    checkcrl -c "${CRLS[$i]}" -w "${MINUTESx}" -e "${ERRMINx}" -i "${CRL_HOST_IPx}"
done

# send the summary message (00)

if [ "x${ERRSTATUS}" != "x0" ] ; then
    printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[9]} -d "${DESCR[9]}" -1 "${GLOBALERRMESSAGE}"
elif [ "x${WARNSTATUS}" != "x0" ] ; then
    printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $WARN  -e ${ERRNO[9]} -d "${DESCR[9]}" -1 "${GLOBALERRMESSAGE}"
else
    printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $INFO  -e ${ERRNO[2]} -d "${DESCR[2]}"
fi
