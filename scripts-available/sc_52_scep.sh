#!/bin/bash
#
# sc_52_scep.sh
#
# Tests SCEP (RFC 8894) certificate enrollment against any SCEP server
# (e.g. a Nexus PGWY SCEP endpoint):
# GetCACaps -> GetCACert -> PKCSReq (-> CertPoll) -> CertRep.
#
# The SCEP protocol work is done by lib/scep_client.py, which only needs
# python3 (standard library) and the openssl CLI - no sscep, no pip packages.
#
# Each configured test can:
#   - expect success  (normal enrollment, optionally followed by a renewal
#                      signed with the certificate that was just issued)
#   - expect failure  (negative test, e.g. wrong challenge password - proves
#                      that the CA actually enforces the policy)

SYSCHECK_HOME="${SYSCHECK_HOME:-/opt/syscheck}" # use default if unset
if [ ! -f ${SYSCHECK_HOME}/syscheck.sh ] ; then
  echo "Can't find $SYSCHECK_HOME/syscheck.sh"
  exit
fi

# Import common definitions
source $SYSCHECK_HOME/config/syscheck-scripts.conf

# script name, used when integrating with nagios/icinga
SCRIPTNAME=scep

# uniq ID of script (please use in the name of this file also for convinice for finding next availavle number)
SCRIPTID=52

# how many info/warn/error messages
NO_OF_ERR=12
initscript $SCRIPTID $NO_OF_ERR

default_script_getopt $*

PYTHON_BIN="${PYTHON_BIN:-/usr/bin/python3}"
SCEP_CLIENT="${SCEP_CLIENT:-${SYSCHECK_HOME}/lib/scep_client.py}"
OPENSSL_BIN="${OPENSSL_BIN:-/usr/bin/openssl}"

# global counters across all configured tests (index 0, 1, ...)
ERRSTATUS=0
WARNSTATUS=0
GLOBALMESSAGE=""

# value of KEY=... from the client output
scep_get() {
  echo "${SCEP_OUT}" | sed -n "s/^$1=//p" | tail -1
}

# run the python client, sets SCEP_OUT and SCEP_RC
scep_run() {
  SCEP_OUT=$("${PYTHON_BIN}" "${SCEP_CLIENT}" --openssl "${OPENSSL_BIN}" --timeout "${TIMEOUT:-30}" "$@" 2>&1)
  SCEP_RC=$?
}

scep_enroll() {
  local NAME="$1"
  local URL="$2"
  local CHALLENGE="$3"
  local SUBJECT="$4"
  local EXPECT="$5"
  local RENEW="$6"
  local EXTRA="$7"
  local IDX="$8"

  # %TS% in the subject is replaced with epoch seconds, so every run gets a
  # unique DN (useful if the CA rejects duplicate subjects)
  SUBJECT="${SUBJECT//%TS%/$(date +%s)}"

  # 1. python3 + client present?
  if [ ! -x "${PYTHON_BIN}" ] || [ ! -f "${SCEP_CLIENT}" ] ; then
    printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[1]} -d "${DESCR[1]}" -1 "${PYTHON_BIN}" -2 "${SCEP_CLIENT}"
    ERRSTATUS=$(expr $ERRSTATUS + 1)
    GLOBALMESSAGE="${GLOBALMESSAGE}; python3/scep_client.py missing"
    return
  fi

  local WORKDIR=$(mktemp -d /tmp/syscheck-scep.XXXXXX)
  local OPTS=(-u "${URL}" -p "${CHALLENGE}" -s "${SUBJECT}" -o "${WORKDIR}")
  # EXTRA is intentionally word-split (e.g. "--digest sha256 --cipher aes128")
  scep_run "${OPTS[@]}" ${EXTRA}

  local MSG="$(scep_get MESSAGE)"
  local MS="$(scep_get TIME_MS)"
  printverbose "scep_client rc=${SCEP_RC}: ${SCEP_OUT//$'\n'/ | }"

  # transport / local / bad-response errors are always errors, also in a negative test
  case ${SCEP_RC} in
    1|2)
      printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[2]} -d "${DESCR[2]}" -1 "${NAME}" -2 "${URL}" -3 "${MSG}"
      ERRSTATUS=$(expr $ERRSTATUS + 1)
      GLOBALMESSAGE="${GLOBALMESSAGE}; ${NAME} connection/local error"
      rm -rf "${WORKDIR}"
      return
      ;;
    5)
      printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[5]} -d "${DESCR[5]}" -1 "${NAME}" -2 "${MSG}"
      ERRSTATUS=$(expr $ERRSTATUS + 1)
      GLOBALMESSAGE="${GLOBALMESSAGE}; ${NAME} invalid SCEP response"
      rm -rf "${WORKDIR}"
      return
      ;;
  esac

  # negative test: a rejection is the expected result
  if [ "x${EXPECT}" == "xfailure" ] ; then
    if [ ${SCEP_RC} -eq 3 ] ; then
      printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $INFO -e ${ERRNO[7]} -d "${DESCR[7]}" -1 "${NAME}" -2 "$(scep_get FAILINFO)" -3 "${MS}"
    else
      printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[8]} -d "${DESCR[8]}" -1 "${NAME}" -2 "$(scep_get STATUS)" -3 "$(scep_get CERT_SUBJECT)"
      ERRSTATUS=$(expr $ERRSTATUS + 1)
      GLOBALMESSAGE="${GLOBALMESSAGE}; ${NAME} was NOT rejected"
    fi
    rm -rf "${WORKDIR}"
    return
  fi

  if [ ${SCEP_RC} -eq 3 ] ; then
    printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[3]} -d "${DESCR[3]}" -1 "${NAME}" -2 "$(scep_get FAILINFO)" -3 "${MSG}"
    ERRSTATUS=$(expr $ERRSTATUS + 1)
    GLOBALMESSAGE="${GLOBALMESSAGE}; ${NAME} rejected ($(scep_get FAILINFO))"
    rm -rf "${WORKDIR}"
    return
  fi
  if [ ${SCEP_RC} -eq 4 ] ; then
    printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $WARN -e ${ERRNO[4]} -d "${DESCR[4]}" -1 "${NAME}" -2 "${MSG}"
    WARNSTATUS=$(expr $WARNSTATUS + 1)
    GLOBALMESSAGE="${GLOBALMESSAGE}; ${NAME} pending"
    rm -rf "${WORKDIR}"
    return
  fi

  # SCEP_RC == 0: issued. Warn on weak/odd but working responses.
  local NOTES=""
  [ "x$(scep_get CHAIN_VERIFY)" != "xok" ] && NOTES="${NOTES} response signer not verifiable against GetCACert certs;"
  [ "x$(scep_get RESP_LEGACY_CIPHER)" == "xyes" ] && NOTES="${NOTES} response encrypted with legacy cipher (DES/RC2);"
  if [ "x${NOTES}" != "x" ] ; then
    printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $WARN -e ${ERRNO[9]} -d "${DESCR[9]}" -1 "${NAME}" -2 "${NOTES}"
    WARNSTATUS=$(expr $WARNSTATUS + 1)
    GLOBALMESSAGE="${GLOBALMESSAGE}; ${NAME}${NOTES}"
  fi
  printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $INFO -e ${ERRNO[6]} -d "${DESCR[6]}" -1 "${NAME}" -2 "$(scep_get CERT_SUBJECT)" -3 "$(scep_get CERT_SERIAL)" -4 "${MS}"

  # optional renewal: new key, request signed with the cert we just got
  if [ "x${RENEW}" == "x1" ] ; then
    SCRIPTINDEX=$(addOneToIndex $SCRIPTINDEX)
    scep_run -u "${URL}" -p "${CHALLENGE}" -s "${SUBJECT}-renew" \
             --sign-cert "${WORKDIR}/cert.pem" --sign-key "${WORKDIR}/key.pem" ${EXTRA}
    if [ ${SCEP_RC} -eq 0 ] ; then
      printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $INFO -e ${ERRNO[6]} -d "${DESCR[6]}" -1 "${NAME} renewal" -2 "$(scep_get CERT_SUBJECT)" -3 "$(scep_get CERT_SERIAL)" -4 "$(scep_get TIME_MS)"
    else
      printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[3]} -d "${DESCR[3]}" -1 "${NAME} renewal" -2 "$(scep_get FAILINFO)" -3 "$(scep_get MESSAGE)"
      ERRSTATUS=$(expr $ERRSTATUS + 1)
      GLOBALMESSAGE="${GLOBALMESSAGE}; ${NAME} renewal failed"
    fi
  fi
  rm -rf "${WORKDIR}"
}

for (( i = 0 ; i < ${#SCEP_URL[@]} ; i++ )) ; do
  SCRIPTINDEX=$(addOneToIndex $SCRIPTINDEX)

  printverbose "## Current test: SCEP ${SCEP_NAME[$i]} url: ${SCEP_URL[$i]} expect: ${SCEP_EXPECT[$i]:-success} -x ${SCRIPTINDEX}"
  scep_enroll "${SCEP_NAME[$i]:-scep$i}" "${SCEP_URL[$i]}" "${SCEP_CHALLENGE[$i]}" "${SCEP_SUBJECT[$i]:-/CN=syscheck-scep-%TS%}" \
              "${SCEP_EXPECT[$i]:-success}" "${SCEP_RENEW[$i]:-0}" "${SCEP_EXTRA_OPTS[$i]}" "${SCRIPTINDEX}"
done

# send the summary GLOBALMESSAGE (00)
export SCRIPTINDEX="00"
if [ "x${ERRSTATUS}" != "x0" ] ; then
     printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[10]} -d "${DESCR[10]}" -1 "${GLOBALMESSAGE}" -2 "${ERRSTATUS}" -3 "${WARNSTATUS}"
elif [ "x${WARNSTATUS}" != "x0" ] ; then
     printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $WARN  -e ${ERRNO[11]} -d "${DESCR[11]}" -1 "${GLOBALMESSAGE}" -2 "${ERRSTATUS}" -3 "${WARNSTATUS}"
else
     printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $INFO  -e ${ERRNO[12]} -d "${DESCR[12]}"
fi
