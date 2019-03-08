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
SCRIPTNAME=ocsp

# uniq ID of script (please use in the name of this file also for convinice for finding next availavle number)
SCRIPTID=10

# how many info/warn/error messages
NO_OF_ERR=10
initscript $SCRIPTID $NO_OF_ERR

default_script_getopt $*

# main part of script

checkocsp() {

  local OPTIND

  while getopts ":u:i:c:h:a:s:x:d" opt; do
    case $opt in
     u)
        OCSP_URL="$OPTARG"
       ;;
     i)
        OCSP_ISSUER="$OPTARG"
       ;;
     c)
        OCSP_CERT="$OPTARG"
       ;;
     h)
        OCSP_HOSTNAME="$OPTARG"
       ;;
     a)
        OCSP_CACHAIN="$OPTARG"
       ;;
     s)
        EXPECTED_STATUS="$OPTARG"
       ;;
     x)
        SCRIPTINDEX="$OPTARG"
         ;;
     \?)
       printverbose "Invalid option: -$OPTARG" >&2
       exit 1
       ;;
     :)
       printverbose "Option -$OPTARG requires an argument." >&2
       exit 1
       ;;
    esac
  done

  if [ "x$OCSP_ISSUER" = "x" ] ; then printverbose "ISSUER NOT SET" ; exit ; fi
  if [ "x$OCSP_CACHAIN" = "x" ] ; then printverbose "CHAIN NOT SET" ; exit ; fi
  if [ "x$OCSP_CERT" = "x" ] ; then printverbose "CERT NOT SET" ; exit ; fi
  if [ "x$OCSP_HOST" = "x" ] ; then printverbose "HOST NOT SET(is optional)" ; fi
  if [ "x$OCSP_DEBUG" = "x" ] ; then printverbose "DEBUG NOT SET(is optional)" ; fi


  if [ ! -f "$OCSP_CERT"  ] ; then
    printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[1]} -d "${DESCR[1]}" -1 "Can NOT find OCSP_CERT $OCSP_CERT"
    return 1
  fi

  if [ ! -f "$OCSP_ISSUER" ] ; then
    printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[1]} -d "${DESCR[1]}" -1 "Can NOT find OCSP_ISSUER $OCSP_ISSUER"
    return 1
  fi

	if [ ! -f "$OCSP_CACHAIN" ] ; then
    printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[1]} -d "${DESCR[1]}" -1 "Can NOT find OCSP_CACHAIN $OCSP_CACHAIN"
    return 1
  fi

  if [ "x$PRINTVERBOSESCREEN" != "x" ] ; then
		    CERTINFO=$(openssl x509 -in "$OCSP_CERT" -noout  -subject -issuer -dates 2>&1)
        CERTINFO_SUBJECT=$(echo "$CERTINFO" | grep "^subject="    | sed 's#^subject=##')
        CERTINFO_ISSUER=$(echo "$CERTINFO" | grep "^issuer="      | sed 's#^issuer=##')
        CERTINFO_NOT_BEFORE=$(echo "$CERTINFO" | grep "^notBefore=" | sed 's#^notBefore=##')
        CERTINFO_NOT_AFTER=$(echo "$CERTINFO" | grep "^notAfter="   | sed 's#^notAfter=##')
        printverbose "### CERTINFO SUBJECT $CERTINFO_SUBJECT ###"
        printverbose "### CERTINFO ISSUER  $CERTINFO_ISSUER ####"
        printverbose "### CERTINFO NOT BEFORE  $CERTINFO_NOT_BEFORE ####"
        printverbose "### CERTINFO NOT AFTER   $CERTINFO_NOT_AFTER ####"
        printverbose "openssl ocsp -issuer $OCSP_ISSUER -cert $OCSP_CERT -CAfile $OCSP_CACHAIN -url $OCSP_URL $OCSP_DEBUG "
    fi

		OCSPINFO=$(openssl ocsp -issuer "$OCSP_ISSUER" -cert "$OCSP_CERT" -CAfile "$OCSP_CACHAIN" -resp_text  -url $OCSP_URL 2>/dev/null)
#    printverbose "### START OCSP INFO ###"
#    printverbose $OCSPINFO
#    printverbose "### END OCSP INFO ###"

    OCSP_STATUS=$(echo "${OCSPINFO}" | egrep "^$OCSP_CERT:" | sed "s#$OCSP_CERT:\ ##" )
    OCSP_DATE=$(echo "${OCSPINFO}" | egrep "^\ +This Update:" | sed "s#.*This Update: ##" )
    OCSP_RESPONDER_CERT_ISSUER=$(echo "${OCSPINFO}" | egrep  "^\ +Issuer: " | sed "s#.*Issuer: ##" )
    OCSP_RESPONDER_CERT_SUBJECT=$(echo "${OCSPINFO}" | egrep  "^\ +Subject: " | sed "s#.*Subject: ##" )
    OCSP_RESPONDER_CERT_NOT_BEFORE=$(echo "${OCSPINFO}" | egrep  "^\ +Not Before: " | sed "s#.*Not Before: ##" )
    OCSP_RESPONDER_CERT_NOT_AFTER=$(echo "${OCSPINFO}" | egrep  "^\ +Not After : " | sed "s#.*Not After : ##" )
    OCSP_RESPONDER_RESPONSE_STATUS=$(echo "${OCSPINFO}" | grep "OCSP Response Status:"  | sed 's#.*OCSP Response Status:##')

    printverbose "### OCSP DATE: $OCSP_DATE ###"
    printverbose "### OCSP STATUS: $OCSP_STATUS ###"
    printverbose "### OCSP Responder CERT Subject: $OCSP_RESPONDER_CERT_SUBJECT  ###"
    printverbose "### OCSP Responder CERT Issuer: $OCSP_RESPONDER_CERT_ISSUER  ###"
    printverbose "### OCSP Responder CERT Not before: $OCSP_RESPONDER_CERT_NOT_BEFORE  ###"
    printverbose "### OCSP Responder CERT not after: $OCSP_RESPONDER_CERT_NOT_AFTER  ###"
    printverbose "### OCSP_RESPONDER_RESPONSE_STATUS: $OCSP_RESPONDER_RESPONSE_STATUS ###"

    if [ "x${OCSP_STATUS}" == "x${EXPECTED_STATUS}" ] ; then
      printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $INFO -e ${ERRNO[6]} -d "${DESCR[6]}" -1 "${CERTINFO_SUBJECT}: $OCSP_STATUS/$EXPECTED_STATUS)"
    else
      printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $WARN -e ${ERRNO[10]} -d "${DESCR[10]}" -1 "${CERTINFO_SUBJECT}: $OCSP_STATUS/$EXPECTED_STATUS)"
      WARNSTATUS=$(expr $WARNSTATUS + 1)
      GLOBALMESSAGE="${GLOBALMESSAGE}; ${OCSP_RESPONDER_CERT_ISSUER}"
    fi

    OCSP_RESPONDER_CERT_CHECK_VALIDITY=$(${SYSCHECK_HOME}/lib/cmp_dates.py "$OCSP_RESPONDER_CERT_NOT_BEFORE" "$OCSP_RESPONDER_CERT_NOT_AFTER" --warnminutes "${WARN_OCSP_RESPONDER_CERT_EXPIRE}" --errorminutes "${ERROR_OCSP_RESPONDER_CERT_EXPIRE}" )
    OCSP_RESPONDER_CERT_CHECK_RETCODE=$?

    if [ "x$OCSP_RESPONDER_CERT_CHECK_VALIDITY" = "x" ] ; then
      printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[1]} -d "${DESCR[1]}" -1 "$OCSP_RESPONDER_CERT_CHECK_RETCODE"
      ERRSTATUS=$(expr $ERRSTATUS + 1)
      GLOBALMESSAGE="${GLOBALMESSAGE}; ${OCSP_RESPONDER_CERT_ISSUER}"

# ocsp responder cert has already expired
    elif [ $OCSP_RESPONDER_CERT_CHECK_RETCODE -eq 3 ] ; then
      printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[5]} -d "${DESCR[5]}" -1 "${OCSP_RESPONDER_CERT_ISSUER}" -2 "${OCSP_RESPONDER_CERT_CHECK_VALIDITY}"
      ERRSTATUS=$(expr $ERRSTATUS + 1)
      GLOBALMESSAGE="${GLOBALMESSAGE}; ${OCSP_RESPONDER_CERT_ISSUER}"

# ocsp responder cert has passed  configured error time
    elif [ $OCSP_RESPONDER_CERT_CHECK_RETCODE -eq 2 ] ; then
      printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[4]} -d "${DESCR[4]}" -1 "${OCSP_RESPONDER_CERT_ISSUER}" -2 "${OCSP_RESPONDER_CERT_CHECK_VALIDITY}"
      ERRSTATUS=$(expr $ERRSTATUS + 1)
      GLOBALMESSAGE="${GLOBALMESSAGE}; ${OCSP_RESPONDER_CERT_ISSUER}"

# ocsp responder cert has passed  configured warn time
    elif [ $OCSP_RESPONDER_CERT_CHECK_RETCODE -eq 1 ] ; then
      printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $WARN -e ${ERRNO[3]} -d "${DESCR[3]}" -1 "${OCSP_RESPONDER_CERT_ISSUER}" -2 "${OCSP_RESPONDER_CERT_CHECK_VALIDITY}"
      WARNSTATUS=$(expr $WARNSTATUS + 1)
      GLOBALMESSAGE="${GLOBALMESSAGE}; ${OCSP_RESPONDER_CERT_ISSUER}"

# ocsp responder cert is before any warn/error time
    elif [ $OCSP_RESPONDER_CERT_CHECK_RETCODE -eq 0 ] ; then
      printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $INFO -e ${ERRNO[2]} -d "${DESCR[2]}" -1 "${OCSP_RESPONDER_CERT_ISSUER}" -2 "${OCSP_RESPONDER_CERT_CHECK_VALIDITY}"

    else
      printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[1]} -d "${DESCR[1]}"
      ERRSTATUS=$(expr $ERRSTATUS + 1)
      GLOBALMESSAGE="${GLOBALMESSAGE};${OCSP_RESPONDER_CERT_ISSUER}; other problem "
    fi


}


# global ERRSTATUS for all crl:s (0 is ok)
ERRSTATUS=0
WARNSTATUS=0
GLOBALMESSAGE=""


for (( i = 0 ;  i < ${#OCSP_TEST[@]} ; i++ )) ; do
    SCRIPTINDEX=$(addOneToIndex $SCRIPTINDEX)

    for ocsp_cert_to_test in ${OCSP_TEST[$i]}/test_*_cert* ; do
      test_name=$(basename  "$ocsp_cert_to_test" | cut -f1,2 -d_ )
      expected_status=$(basename  "$ocsp_cert_to_test" | cut -f4 -d_ | cut -f1 -d\.)
      issuer_cert="${OCSP_TEST[$i]}/${test_name}_issuer.pem"
      cacerts="${OCSP_TEST[$i]}/${test_name}_cacerts.pem"
      printverbose "## Current test: cert: $ocsp_cert_to_test to URL: ${OCSP_URL[$i]} issuer: ${issuer_cert} cacerts: ${cacerts} -x ${SCRIPTINDEX}"
      checkocsp  -c "${ocsp_cert_to_test}" -u "${OCSP_URL[$i]}" -i "${issuer_cert}" -a "${cacerts}" -s "${expected_status}" -x "${SCRIPTINDEX}"
    done
done

# send the summary GLOBALMESSAGE (00)
export SCRIPTINDEX="00"
if [ "x${ERRSTATUS}" != "x0" ] ; then
     printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[7]} -d "${DESCR[7]}" -1 "${GLOBALMESSAGE}" -2 "${ERRSTATUS}" -3 "${WARNSTATUS}"
elif [ "x${WARNSTATUS}" != "x0" ] ; then
     printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $WARN  -e ${ERRNO[8]} -d "${DESCR[8]}" -1 "${GLOBALMESSAGE}" -2 "${ERRSTATUS}" -3 "${WARNSTATUS}"
else
     printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $INFO  -e ${ERRNO[9]} -d "${DESCR[9]}"
fi
