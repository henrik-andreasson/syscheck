#!/bin/bash
#
# sc_51_nexus_acme.sh
#
# Tests ACME (RFC 8555) certificate enrollment against a Nexus PGWY ACME
# directory, using certbot in fully non-interactive mode. Forces a fresh
# renewal every run so the http-01 challenge round-trip is actually
# exercised each time (not skipped because "not yet due").

SYSCHECK_HOME="${SYSCHECK_HOME:-/opt/syscheck}" # use default if unset
if [ ! -f ${SYSCHECK_HOME}/syscheck.sh ] ; then
  echo "Can't find $SYSCHECK_HOME/syscheck.sh"
  exit
fi

# Import common definitions
source $SYSCHECK_HOME/config/syscheck-scripts.conf

# script name, used when integrating with nagios/icinga
SCRIPTNAME=nexusacme

# uniq ID of script (please use in the name of this file also for convinice for finding next availavle number)
SCRIPTID=51

# how many info/warn/error messages
NO_OF_ERR=8
initscript $SCRIPTID $NO_OF_ERR

default_script_getopt $*

CERTBOT_BIN="${CERTBOT_BIN:-/usr/bin/certbot}"

# global counters across all configured domains (index 0, 1, ... like sc_10/11)
ERRSTATUS=0
WARNSTATUS=0
GLOBALMESSAGE=""

acme_enroll() {
  local DOMAIN="$1"
  local EMAIL="$2"
  local SERVER="$3"
  local EAB_KID="$4"
  local EAB_HMACKEY="$5"
  local HTTP_PORT="$6"
  local IDX="$7"

  # 1. certbot binary present?
  if [ ! -x "${CERTBOT_BIN}" ] ; then
    printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[1]} -d "${DESCR[1]}" -1 "${CERTBOT_BIN}"
    ERRSTATUS=$(expr $ERRSTATUS + 1)
    GLOBALMESSAGE="${GLOBALMESSAGE}; certbot binary missing"
    return
  fi

  local PORT_OPTS=()
  if [ "x${HTTP_PORT}" != "x" ] && [ "${HTTP_PORT}" != "80" ] ; then
    PORT_OPTS=(--http-01-port "${HTTP_PORT}")
  fi

  local START_MS=$(date +%s%3N)
  local CERTBOT_OUT
  CERTBOT_OUT=$("${CERTBOT_BIN}" certonly \
    -a standalone \
    --non-interactive \
    --force-renewal \
    --agree-tos \
    --email "${EMAIL}" \
    --domain "${DOMAIN}" \
    --server "${SERVER}" \
    --eab-kid "${EAB_KID}" \
    --eab-hmac-key "${EAB_HMACKEY}" \
    --preferred-challenges http \
    "${PORT_OPTS[@]}" \
    -v 2>&1)
  local CB_RC=$?
  local END_MS=$(date +%s%3N)
  local DELTA_MS=$(expr $END_MS - $START_MS)

  # flatten multi-line certbot output so printlogmess doesn't truncate it
  local CERTBOT_OUT_FLAT="${CERTBOT_OUT//$'\n'/ | }"

  if [ $CB_RC -ne 0 ] ; then
    printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[2]} -d "${DESCR[2]}" -1 "${DOMAIN}" -2 "${CB_RC}" -3 "${CERTBOT_OUT_FLAT}"
    ERRSTATUS=$(expr $ERRSTATUS + 1)
    GLOBALMESSAGE="${GLOBALMESSAGE}; ${DOMAIN} certbot exit ${CB_RC}"
    return
  fi

  # double-check: cert actually landed and is fresh (mtime within this run)
  local CERTFILE="/etc/letsencrypt/live/${DOMAIN}/cert.pem"
  if [ ! -f "${CERTFILE}" ] ; then
    printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[3]} -d "${DESCR[3]}" -1 "${DOMAIN}" -2 "${CERTFILE}"
    ERRSTATUS=$(expr $ERRSTATUS + 1)
    GLOBALMESSAGE="${GLOBALMESSAGE}; ${DOMAIN} cert file missing after success exit"
    return
  fi

  local CERT_MTIME_EPOCH=$(stat -c %Y "${CERTFILE}" 2>/dev/null)
  local NOW_EPOCH=$(date +%s)
  local AGE_SEC=$(expr $NOW_EPOCH - $CERT_MTIME_EPOCH)
  if [ "${AGE_SEC}" -gt 120 ] ; then
    printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $WARN -e ${ERRNO[5]} -d "${DESCR[5]}" -1 "${DOMAIN}" -2 "${AGE_SEC}"
    WARNSTATUS=$(expr $WARNSTATUS + 1)
    GLOBALMESSAGE="${GLOBALMESSAGE}; ${DOMAIN} cert older than expected"
  fi

  printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $INFO -e ${ERRNO[4]} -d "${DESCR[4]}" -1 "${DOMAIN}" -2 "${DELTA_MS}"
}

for (( i = 0 ; i < ${#ACME_DOMAIN[@]} ; i++ )) ; do
  SCRIPTINDEX=$(addOneToIndex $SCRIPTINDEX)

  printverbose "## Current test: PGWY ACME domain: ${ACME_DOMAIN[$i]} server: ${ACME_SERVER[$i]} -x ${SCRIPTINDEX}"
  acme_enroll "${ACME_DOMAIN[$i]}" "${ACME_EMAIL[$i]}" "${ACME_SERVER[$i]}" "${ACME_EAB_KID[$i]}" "${ACME_EAB_HMACKEY[$i]}" "${ACME_HTTP_PORT[$i]}" "${SCRIPTINDEX}"
done

# send the summary GLOBALMESSAGE (00)
export SCRIPTINDEX="00"
if [ "x${ERRSTATUS}" != "x0" ] ; then
     printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[6]} -d "${DESCR[6]}" -1 "${GLOBALMESSAGE}" -2 "${ERRSTATUS}" -3 "${WARNSTATUS}"
elif [ "x${WARNSTATUS}" != "x0" ] ; then
     printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $WARN  -e ${ERRNO[7]} -d "${DESCR[7]}" -1 "${GLOBALMESSAGE}" -2 "${ERRSTATUS}" -3 "${WARNSTATUS}"
else
     printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $INFO  -e ${ERRNO[8]} -d "${DESCR[8]}"
fi
