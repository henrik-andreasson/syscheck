#!/bin/bash

SYSCHECK_HOME="${SYSCHECK_HOME:-/opt/syscheck}" # use default if unset
if [ ! -f "${SYSCHECK_HOME}/syscheck.sh" ] ; then
  echo "Can't find ${SYSCHECK_HOME}/syscheck.sh"
  exit 1
fi

## Import common definitions ##
source "${SYSCHECK_HOME}/config/syscheck-scripts.conf"

# script name, used when integrating with nagios/icinga
SCRIPTNAME=ntp

# uniq ID of script
SCRIPTID=17

# how many info/warn/error messages
NO_OF_ERR=5
initscript "$SCRIPTID" "$NO_OF_ERR"

default_script_getopt "$@"

# main part of script

STATUS="unknown"
SYNCSERVER="unknown"
SYNCOFFSET="unknown"
REACHABLESOURCES=0
CLIENTSYNC=no
LEVEL=""
MESSAGEINDEX=0
KERNELSYNC=$("${TIMEDATECTLBIN}" show --property=NTPSynchronized 2>/dev/null)
KERNELSYNC=${KERNELSYNC#*=}
CHRONYACTIVE=0
TIMESYNCACTIVE=0

if "${SYSTEMCTLBIN}" is-active --quiet chronyd.service || "${SYSTEMCTLBIN}" is-active --quiet chrony.service ; then
  CHRONYACTIVE=1
fi

if "${SYSTEMCTLBIN}" is-active --quiet systemd-timesyncd.service ; then
  TIMESYNCACTIVE=1
fi

if [ "$CHRONYACTIVE" -eq 1 ] && [ "$TIMESYNCACTIVE" -eq 1 ] ; then
  STATUS="multiple time clients active"
  LEVEL=$ERROR
  MESSAGEINDEX=4
elif [ "$CHRONYACTIVE" -eq 0 ] && [ "$TIMESYNCACTIVE" -eq 0 ] ; then
  STATUS="no supported time client active"
  LEVEL=$ERROR
  MESSAGEINDEX=5
elif [ "$CHRONYACTIVE" -eq 1 ] ; then
  if ! TRACKING=$("${CHRONYBIN}" -n -c tracking 2>/dev/null) ; then
    STATUS="chrony tracking query failed"
    LEVEL=$ERROR
    MESSAGEINDEX=3
  elif [ -z "$TRACKING" ] ; then
    STATUS="chrony tracking query returned no data"
    LEVEL=$ERROR
    MESSAGEINDEX=3
  elif ! SOURCES=$("${CHRONYBIN}" -n -c sources 2>/dev/null) ; then
    STATUS="chrony sources query failed"
    LEVEL=$ERROR
    MESSAGEINDEX=3
  elif [ -z "$SOURCES" ] ; then
    STATUS="chrony sources query returned no data"
    LEVEL=$ERROR
    MESSAGEINDEX=3
  else
    IFS=, read -r REFID SYNCSERVER STRATUM REFTIME SYSTEMOFFSET SYNCOFFSET RMSOFFSET FREQUENCY RESIDUALFREQUENCY SKEW ROOTDELAY ROOTDISPERSION UPDATEINTERVAL LEAPSTATUS <<< "$TRACKING"
    SYNCOFFSET="${SYNCOFFSET}s"

    while IFS=, read -r SOURCEMODE SOURCESTATE SOURCENAME SOURCESTRATUM SOURCEPOLL SOURCEREACH SOURCELASTRX SOURCEOFFSET SOURCEMEASUREDOFFSET SOURCEERROR ; do
      if [ -n "$SOURCENAME" ] && [ "$SOURCEREACH" != "0" ] ; then
        REACHABLESOURCES=$((REACHABLESOURCES + 1))
      fi
    done <<< "$SOURCES"

    case "$LEAPSTATUS" in
      "Normal"|"Insert second"|"Delete second") CLIENTSYNC=yes ;;
      *) CLIENTSYNC=no ;;
    esac

    if [ "$REFID" = "7F7F0101" ] ; then
      CLIENTSYNC=no
    fi
  fi
else
  PACKETCOUNT=0
  LEAPSTATUS="unknown"

  if ! TIMESYNCSTATUS=$(LC_ALL=C "${TIMEDATECTLBIN}" --no-pager timesync-status 2>/dev/null) ; then
    STATUS="timesyncd query failed"
    LEVEL=$ERROR
    MESSAGEINDEX=3
  elif [ -z "$TIMESYNCSTATUS" ] ; then
    STATUS="timesyncd query returned no data"
    LEVEL=$ERROR
    MESSAGEINDEX=3
  else
    while IFS= read -r LINE ; do
      case "$LINE" in
        *"Server:"*) SYNCSERVER=${LINE#*: }; SYNCSERVER=${SYNCSERVER%% *} ;;
        *"Leap:"*) LEAPSTATUS=${LINE#*: } ;;
        *"Offset:"*) SYNCOFFSET=${LINE#*: } ;;
        *"Packet count:"*) PACKETCOUNT=${LINE#*: } ;;
      esac
    done <<< "$TIMESYNCSTATUS"

    if [[ "$PACKETCOUNT" =~ ^[0-9]+$ ]] && [ "$PACKETCOUNT" -gt 0 ] && [ "$SYNCSERVER" != "unknown" ] ; then
      REACHABLESOURCES=1
    fi

    if [ "$LEAPSTATUS" != "not synchronized" ] && [ "$LEAPSTATUS" != "unknown" ] && [ "$REACHABLESOURCES" -eq 1 ] ; then
      CLIENTSYNC=yes
    fi
  fi
fi

if [ -z "$LEVEL" ] ; then
  if [ "$CLIENTSYNC" != "yes" ] ; then
    STATUS="not synchronized"
    LEVEL=$ERROR
    MESSAGEINDEX=3
  elif [ "$KERNELSYNC" != "yes" ] ; then
    STATUS="synchronized, kernel state ${KERNELSYNC:-unknown}"
    LEVEL=$WARN
    MESSAGEINDEX=2
  elif [ "$REACHABLESOURCES" -eq 0 ] ; then
    STATUS="synchronized, no reachable sources"
    LEVEL=$WARN
    MESSAGEINDEX=2
  else
    STATUS="synchronized"
    LEVEL=$INFO
    MESSAGEINDEX=1
  fi
fi

SCRIPTINDEX=$(addOneToIndex "$SCRIPTINDEX")
printlogmess -n "$SCRIPTNAME" -i "$SCRIPTID" -x "$SCRIPTINDEX" -l "$LEVEL" -e "${ERRNO[$MESSAGEINDEX]}" -d "${DESCR[$MESSAGEINDEX]}" -1 "$STATUS" -2 "$SYNCSERVER" -3 "$SYNCOFFSET" -4 "$REACHABLESOURCES"
