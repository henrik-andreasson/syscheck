#!/bin/bash

# 1. First check if SYSCHECK_HOME is set then use that
if [ "x${SYSCHECK_HOME}" = "x" ] ; then
# 2. Check if /etc/syscheck.conf exists then source that (put SYSCHECK_HOME=/path/to/syscheck in ther)
    if [ -e /etc/syscheck.conf ] ; then
	source /etc/syscheck.conf
    else
# 3. last resort use default path
	SYSCHECK_HOME="/opt/syscheck"
    fi
fi

if [ ! -f ${SYSCHECK_HOME}/syscheck.sh ] ; then echo "$0: Can't find syscheck.sh in SYSCHECK_HOME ($SYSCHECK_HOME)" ;exit ; fi

# Import common definitions
source $SYSCHECK_HOME/config/syscheck-scripts.conf

# script name, used when integrating with nagios/icinga
SCRIPTNAME=crl_from_webserver

## Local Definitions ##
SCRIPTID=08

# Index is used to uniquely identify one test done by the script (a harddrive, crl or cert)
SCRIPTINDEX=00

getlangfiles $SCRIPTID
getconfig $SCRIPTID

ERRNO_1=01
ERRNO_2=02
ERRNO_3=03
ERRNO_4=04
ERRNO_5=05
ERRNO_6=06
ERRNO_7=07
ERRNO_8=08
ERRNO_9=09

# help
if [ "x$1" = "x--help" ] ; then
    echo "$0 $HELP"
    echo "$ERRNO_1/$DESCR_1 - $HELP_1"
    echo "$ERRNO_2/$DESCR_2 - $HELP_2"
    echo "$ERRNO_3/$DESCR_3 - $HELP_3"
    echo "$ERRNO_4/$DESCR_4 - $HELP_4"
    echo "$ERRNO_5/$DESCR_5 - $HELP_5"
    echo "$ERRNO_6/$DESCR_6 - $HELP_6"
    echo "$ERRNO_7/$DESCR_7 - $HELP_7"
    echo "$ERRNO_8/$DESCR_8 - $HELP_8"
    echo "$ERRNO_9/$DESCR_9 - $HELP_9"
    exit
elif [ "x$1" = "x-s" -o  "x$1" = "x--screen"  ] ; then
    PRINTTOSCREEN=1
fi



checkcrl () {

  CRLNAME=$1
  if [ "x$CRLNAME" = "x" ] ; then
    printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   $ERROR $ERRNO_5 "$DESCR_5" "No CRL Configured"
    GLOBALERRMESSAGE="${GLOBALERRMESSAGE};$DESCR_3 $CRLNAME"
    ERRSTATUS=$(expr $ERRSTATUS + 1)
    return
  fi


  # Limitminutes is now optional, if not configured the limits is crl WARN: validity/2 ERROR: validity/4 eg: CRL is valid to 12h, warn will be 6h and error 3h
  LIMITMINUTES=$2
  if [ "x$LIMITMINUTES" != "xdefault" ] ; then
    ARGWARNMIN="--warnminutes=$LIMITMINUTES"
  fi

  ERRMINUTES=$3
  if [ "x$ERRMINUTES" != "xdefault" ] ; then
    ARGERRMIN="--errorminutes=$ERRMINUTES"
  fi

  # rework of url to access the server via ip instead and send the hostname in the "Host" header variable
  CRL_HOST_IPx=$4
  if [ "x$CRL_HOST_IPx" != "xdefault" ] ; then
    HOSTNAME_FROM_URL=$(echo "${CRLNAME}" | cut -d'/' -f3 | cut -d':' -f1)
    PATH_FROM_URL=$(echo "${CRLNAME}" | cut -d'/' -f4-)
    CHECK_HOST_ARG1="--header"
    CHECK_HOST_ARG2="Host: ${HOSTNAME_FROM_URL}"
    CRLNAME="http://${CRL_HOST_IPx}/${PATH_FROM_URL}"
  fi


  cd /tmp
  outname=`mktemp`
  if [ "x${CHECKTOOL}" = "xwget" ] ; then

    ${CHECKTOOL} ${CRLNAME}  -T ${TIMEOUT} -t ${RETRIES}    ${CHECK_HOST_ARG1} "${CHECK_HOST_ARG2}"      -O $outname -o /dev/null
    if [ $? -ne 0 ] ; then
      printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   $ERROR $ERRNO_3 "$DESCR_3" "$CRLNAME"
      ERRSTATUS=$(expr $ERRSTATUS + 1)
      GLOBALERRMESSAGE="${GLOBALERRMESSAGE};$DESCR_3 $CRLNAME"
      return 1
    fi

  elif [ "x${CHECKTOOL}" = "xcurl" ] ; then

    ${CHECKTOOL} ${CRLNAME} --retry ${RETRIES} ${CHECK_HOST_ARG1} "${CHECK_HOST_ARG2}" --connect-timeout ${TIMEOUT} --max-time ${TIMEOUT} --output $outname 2>/dev/null
    if [ $? -ne 0 ] ; then
      printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   $ERROR $ERRNO_3 "$DESCR_3" "$CRLNAME"
      GLOBALERRMESSAGE="${GLOBALERRMESSAGE};$DESCR_3 $CRLNAME"
      ERRSTATUS=$(expr $ERRSTATUS + 1)
      return 1
    fi
  else
    printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   $ERROR $ERRNO_3 "$DESCR_3"
    ERRSTATUS=$(expr $ERRSTATUS + 1)
    GLOBALERRMESSAGE="${GLOBALERRMESSAGE};$DESCR_3 $CRLNAME"
  fi


  # file not found where it should be
  if [ ! -f $outname ] ; then
    printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   $ERROR $ERRNO_1 "$DESCR_1" "$CRLNAME"
    ERRSTATUS=$(expr $ERRSTATUS + 1)
    GLOBALERRMESSAGE="${GLOBALERRMESSAGE};$DESCR_1 $CRLNAME"
    return 2
  fi

  CRL_FILE_SIZE=`stat -c"%s" $outname`
  # stat return check
  if [ $? -ne 0 ] ; then
    printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   $ERROR $ERRNO_4 "$DESCR_4" "$CRLNAME"
    ERRSTATUS=$(expr $ERRSTATUS + 1)
    GLOBALERRMESSAGE="${GLOBALERRMESSAGE};$DESCR_4 $CRLNAME"
    return 3
  fi

  # crl of 0 size?
  if [ "x$CRL_FILE_SIZE" = "x0" ] ; then
    printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   $ERROR $ERRNO_4 "$DESCR_4" "$CRLNAME"
    ERRSTATUS=$(expr $ERRSTATUS + 1)
    GLOBALERRMESSAGE="${GLOBALERRMESSAGE};$DESCR_4 $CRLNAME"
    return 4
  fi


  LASTUPDATE=$(openssl crl -inform der -in $outname -lastupdate -noout | sed 's/lastUpdate=//')
  if [ "x${LASTUPDATE}" = "x" ] ; then
    printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX} $ERROR $ERRNO_1 "$DESCR_1" "$CRLNAME (Cant parse file,lastupdate)"
    ERRSTATUS=$(expr $ERRSTATUS + 1)
    GLOBALERRMESSAGE="${GLOBALERRMESSAGE};$CRLNAME (Cant parse file,lastupdate)"
  fi

  NEXTUPDATE=$(openssl crl -inform der -in $outname -nextupdate -noout | sed 's/nextUpdate=//')
  if [ "x${NEXTUPDATE}" = "x" ] ; then
    printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX} $ERROR $ERRNO_1 "$DESCR_1" "$CRLNAME (Cant parse file,nextupdate)"
    ERRSTATUS=$(expr $ERRSTATUS + 1)
    GLOBALERRMESSAGE="${GLOBALERRMESSAGE};$CRLNAME (Cant parse file,nextupdate)"
  fi

  CRLMESSAGE=$(${SYSCHECK_HOME}/lib/cmp_dates.py "$LASTUPDATE" "$NEXTUPDATE" ${ARGWARNMIN} ${ARGERRMIN} )
  CRLCHECK=$?
  if [ "x$CRLCHECK" = "x" ] ; then
    printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   $ERROR $ERRNO_1 "$DESCR_1" "$CRLNAME (Cant parse file)"
    ERRSTATUS=$(expr $ERRSTATUS + 1)
    GLOBALERRMESSAGE="${GLOBALERRMESSAGE};$CRLNAME (Cant parse file)"

  elif [ $CRLCHECK -eq 3 ] ; then
    printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   $ERROR $ERRNO_6 "$DESCR_6" "$CRLNAME: ${CRLMESSAGE}"
    ERRSTATUS=$(expr $ERRSTATUS + 1)
    GLOBALERRMESSAGE="${GLOBALERRMESSAGE};${CRLNAME} ${CRLMESSAGE}"

  elif [ $CRLCHECK -eq 2 ] ; then
    printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   $ERROR $ERRNO_7 "$DESCR_7" "$CRLNAME: ${CRLMESSAGE}"
    ERRSTATUS=$(expr $ERRSTATUS + 1)
    GLOBALERRMESSAGE="${GLOBALERRMESSAGE};${CRLNAME} ${CRLMESSAGE}"

  elif [ $CRLCHECK -eq 1 ] ; then
    printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   $WARN $ERRNO_8 "$DESCR_8" "$CRLNAME: ${CRLMESSAGE}"
    WARNSTATUS=$(expr $WARNSTATUS + 1)
    GLOBALERRMESSAGE="${GLOBALERRMESSAGE};${CRLNAME} ${CRLMESSAGE}"

  elif [ $CRLCHECK -eq 0 ] ; then
    printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   $INFO $ERRNO_2 "$DESCR_2" "$CRLNAME: ${CRLMESSAGE}"

  else
    printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   $ERROR $ERRNO_1 "$DESCR_1" "$CRLNAME: problem calculating validity"
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
      MINUTES=${MINUTES[$i]}
    else
      MINUTESx="default"
    fi
    if [ "x${ERRMIN[$i]}" != "x" ] ; then
      ERRMINx=${ERRMIN[$i]}
    else
      ERRMINx="default"
    fi
    if [ "x${CRL_HOST_IP[$i]}" != "x" ] ; then
      CRL_HOST_IPx=${CRL_HOST_IP[$i]}

    elif [ "x${CRL_HOST_IP_ALL}" != "x" ] ; then
      CRL_HOST_IPx=${CRL_HOST_IP_ALL}

    else
      CRL_HOST_IPx="default"
    fi

    checkcrl "${CRLS[$i]}" "${MINUTESx}" "${ERRMINx}" "${CRL_HOST_IPx}"
done

# send the summary message (00)
SCRIPTINDEX=00
if [ "x${ERRSTATUS}" != "x0" ] ; then
    printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   $ERROR $ERRNO_9 "$DESCR_9" "${GLOBALERRMESSAGE}"
elif [ "x${WARNSTATUS}" != "x0" ] ; then
    printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   $WARN $ERRNO_9 "$DESCR_9" "${GLOBALERRMESSAGE}"
else
    printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   $INFO $ERRNO_2 "$DESCR_2"
fi
