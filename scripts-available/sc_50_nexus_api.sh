#!/bin/bash

SYSCHECK_HOME="${SYSCHECK_HOME:-/opt/syscheck}" # use default if  unset
if [ ! -f ${SYSCHECK_HOME}/syscheck.sh ] ; then
  echo "Can't find $SYSCHECK_HOME/syscheck.sh"
  exit
fi

# Import common definitions
source $SYSCHECK_HOME/config/syscheck-scripts.conf

# script name, used when integrating with nagios/icinga
SCRIPTNAME=nexusapi

# uniq ID of script (please use in the name of this file also for convinice for finding next availavle number)
SCRIPTID=50

# how many info/warn/error messages
NO_OF_ERR=10
initscript $SCRIPTID $NO_OF_ERR

default_script_getopt $*

# main part of script
#
# Full nexus api certificate enrollment test:
#   1. Generate a CSR with openssl
#   2. POST pkcs10 to /pgwy/api/certificates/pkcs10          -> dataToSign
#   3. Sign dataToSign with PgwySign.java (officer P12)       -> signature (base64)
#   4. POST pkcs10 + signature to finalize enrollment         -> certificate (DER)

checknexusapi() {

  local OPTIND

  while getopts ":u:p:w:j:c:a:x:" opt; do
    case $opt in
     u)
        PGWY_API_BASE="$OPTARG"
       ;;
     p)
        PGWY_P12FILE="$OPTARG"
       ;;
     w)
        PGWY_P12PASSWORD="$OPTARG"
       ;;
     j)
        PGWY_JAVA_CLASSPATH="$OPTARG"
       ;;
     c)
        PGWY_JAVA_CLASS="$OPTARG"
       ;;
     a)
        PGWY_CACHAIN="$OPTARG"
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

  if [ "x$PGWY_API_BASE" = "x" ] ; then printverbose "API BASE NOT SET" ; exit ; fi
  if [ "x$PGWY_P12FILE" = "x" ] ; then printverbose "P12FILE NOT SET" ; exit ; fi
  if [ "x$PGWY_JAVA_CLASSPATH" = "x" ] ; then printverbose "JAVA CLASSPATH NOT SET" ; exit ; fi
  if [ "x$PGWY_JAVA_CLASS" = "x" ] ; then printverbose "JAVA CLASS NOT SET" ; exit ; fi
  if [ "x$PGWY_CACHAIN" = "x" ] ; then printverbose "CACHAIN NOT SET(is optional)" ; fi

  if [ ! -f "$PGWY_P12FILE" ] ; then
    printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[1]} -d "${DESCR[1]}" -1 "Can NOT find PGWY_P12FILE $PGWY_P12FILE"
    return 1
  fi

  if [ "x$PGWY_CACHAIN" != "x" ] && [ ! -f "$PGWY_CACHAIN" ] ; then
    printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[1]} -d "${DESCR[1]}" -1 "Can NOT find PGWY_CACHAIN $PGWY_CACHAIN"
    return 1
  fi

  CN="test-cert-api-$((RANDOM % 90000 + 10000))"
  WORKDIR=$(mktemp -d "/tmp/pgwy-enroll.XXXXXX")
  KEYFILE="${WORKDIR}/${CN}.key"
  CSRFILE="${WORKDIR}/${CN}.csr"
  SIGNEDFILE="${WORKDIR}/${CN}.signed.b64"
  CERTFILE="${WORKDIR}/${CN}.crt.der"

  if [ "x$PRINTVERBOSESCREEN" != "x" ] ; then
        printverbose "### CN: $CN ###"
        printverbose "openssl req -new -newkey rsa:2048 -nodes -keyout $KEYFILE -out $CSRFILE -subj /CN=$CN"
        printverbose "curl --cert-type P12 --cert $PGWY_P12FILE:**** -F pkcs10=... ${PGWY_API_BASE}/pgwy/api/certificates/pkcs10/verification"
  fi

  # ---- STEP 1: generate CSR ----
  START=$(date +"%s%3N")
  openssl req -new -newkey rsa:2048 -nodes -keyout "$KEYFILE" -out "$CSRFILE" -subj "/CN=${CN}" >/dev/null 2>&1
  OPENSSL_RC=$?
  STOP=$(date +"%s%3N")
  let PGWYdeltaTns="$STOP - $START"

  if [ $OPENSSL_RC -ne 0 ] ; then
    printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[2]} -d "${DESCR[2]}" -1 "${CN}" -2 "${OPENSSL_RC}"
    ERRSTATUS=$(expr $ERRSTATUS + 1)
    GLOBALMESSAGE="${GLOBALMESSAGE}; ${PGWY_API_BASE} CSR generation failed"
    rm -rf "$WORKDIR" 2>/dev/null
    return 1
  fi

  PKCS10=$(cat "$CSRFILE")

  # ---- build optional cacert flag as an array, avoids unreliable word-splitting ----
  CURL_CACERT_OPTS=()
  if [ "x$PGWY_CACHAIN" != "x" ] ; then
    CURL_CACERT_OPTS=(--cacert "$PGWY_CACHAIN")
  fi

  # ---- STEP 2: POST pkcs10, get dataToSign ----
  START=$(date +"%s%3N")
  RESP1=$(curl -s -w "\n%{http_code}" --max-time "${TIMEOUT}" \
    --cert-type P12 --cert "${PGWY_P12FILE}:${PGWY_P12PASSWORD}" \
    "${CURL_CACERT_OPTS[@]}" \
    -F "pkcs10=\"${PKCS10}\"" \
    "${PGWY_API_BASE}/pgwy/api/certificates/pkcs10/verification")
  STOP=$(date +"%s%3N")
  let PGWYdeltaTns="$STOP - $START"

  HTTP1=$(echo "$RESP1" | tail -n1)
  BODY1=$(echo "$RESP1" | sed '$d')
  DATATOSIGN=$(echo "$BODY1" | sed -n 's/.*"dataToSign"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')
  BODY1_ONELINE="${BODY1//$'\n'/ }"

  printverbose "### STEP2 HTTP: $HTTP1 ###"
  printverbose "### STEP2 BODY: $BODY1 ###"

  if [ "x$HTTP1" != "x200" ] || [ "x$DATATOSIGN" = "x" ] ; then
    printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[3]} -d "${DESCR[3]}" -1 "${CN}: HTTP ${HTTP1} ${BODY1_ONELINE}" -2 "${PGWYdeltaTns}"
    ERRSTATUS=$(expr $ERRSTATUS + 1)
    GLOBALMESSAGE="${GLOBALMESSAGE}; ${PGWY_API_BASE} pkcs10 submit failed"
    rm -rf "$WORKDIR" 2>/dev/null
    return 1
  fi

  # ---- STEP 3: sign dataToSign with PgwySign.java ----
  START=$(date +"%s%3N")
  JAVAOUT=$(java -cp "$PGWY_JAVA_CLASSPATH" "$PGWY_JAVA_CLASS" "$PGWY_P12FILE" "$PGWY_P12PASSWORD" "$DATATOSIGN" "$SIGNEDFILE" 2>&1)
  JAVA_RC=$?
  STOP=$(date +"%s%3N")
  let PGWYdeltaTns="$STOP - $START"

  SIGNEDB64=$(echo "$JAVAOUT" | grep -E "^[A-Za-z0-9+/=]+$" | tail -n1)
  JAVAOUT_ONELINE="${JAVAOUT//$'\n'/ | }"

  printverbose "### STEP3 JAVA OUTPUT: $JAVAOUT ###"

  if [ $JAVA_RC -ne 0 ] || [ "x$SIGNEDB64" = "x" ] ; then
    printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[4]} -d "${DESCR[4]}" -1 "${CN}: ${JAVAOUT_ONELINE}" -2 "${JAVA_RC}"
    ERRSTATUS=$(expr $ERRSTATUS + 1)
    GLOBALMESSAGE="${GLOBALMESSAGE}; ${PGWY_API_BASE} signing failed"
    rm -rf "$WORKDIR" 2>/dev/null
    return 1
  fi

  # ---- STEP 4: POST pkcs10 + signature, finalize enrollment ----
  START=$(date +"%s%3N")
  HTTP2=$(curl -s -o "$CERTFILE" -w "%{http_code}" --max-time "${TIMEOUT}" \
    --cert-type P12 --cert "${PGWY_P12FILE}:${PGWY_P12PASSWORD}" \
    "${CURL_CACERT_OPTS[@]}" \
    -F "pkcs10=\"${PKCS10}\"" \
    -F "signature=\"${SIGNEDB64}\"" \
    "${PGWY_API_BASE}/pgwy/api/certificates/pkcs10/verification")
  STOP=$(date +"%s%3N")
  let PGWYdeltaTns="$STOP - $START"

  CERTSIZE=$(stat -c%s "$CERTFILE" 2>/dev/null || echo 0)

  printverbose "### STEP4 HTTP: $HTTP2, cert size: $CERTSIZE bytes ###"

  if [ "x$HTTP2" != "x200" ] ; then
    ERRBODY=$(cat "$CERTFILE" 2>/dev/null | tr -d '\000-\010\013\014\016-\037')
    ERRBODY_ONELINE="${ERRBODY//$'\n'/ }"
    printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[5]} -d "${DESCR[5]}" -1 "${CN}: HTTP ${HTTP2} ${ERRBODY_ONELINE}" -2 "${PGWYdeltaTns}"
    ERRSTATUS=$(expr $ERRSTATUS + 1)
    GLOBALMESSAGE="${GLOBALMESSAGE}; ${PGWY_API_BASE} finalize failed"
  else
    printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $INFO -e ${ERRNO[6]} -d "${DESCR[6]}" -1 "${CN}: certificate received (${CERTSIZE} bytes)" -2 "${PGWYdeltaTns}"
  fi

  rm -rf "$WORKDIR" 2>/dev/null
  if [ $? -ne 0 ] ; then
    printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $WARN -e ${ERRNO[10]} -d "${DESCR[10]}" -1 "${WORKDIR}"
    WARNSTATUS=$(expr $WARNSTATUS + 1)
  fi

}


# global ERRSTATUS for all pgwy endpoints (0 is ok)
ERRSTATUS=0
WARNSTATUS=0
GLOBALMESSAGE=""


for (( i = 0 ;  i < ${#NEXUS_API_APIBASE[@]} ; i++ )) ; do
    SCRIPTINDEX=$(addOneToIndex $SCRIPTINDEX)

    printverbose "## Current test: Nexus API enrollment against ${NEXUS_API_APIBASE[$i]} -x ${SCRIPTINDEX}"
    checkpgwyenroll -u "${NEXUS_API_APIBASE[$i]}" -p "${NEXUS_API_P12FILE[$i]}" -w "${NEXUS_API_P12PASSWORD[$i]}" -j "${NEXUS_API_JAVA_CLASSPATH[$i]}" -c "${NEXUS_API_JAVA_CLASS[$i]}" -a "${NEXUS_API_CACHAIN[$i]}" -x "${SCRIPTINDEX}"
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
