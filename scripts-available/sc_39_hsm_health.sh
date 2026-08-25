#!/bin/bash

SYSCHECK_HOME="${SYSCHECK_HOME:-/opt/syscheck}" # use default if unset
if [[ ! -f ${SYSCHECK_HOME}/syscheck.sh ]] ; then
  echo "Can't find ${SYSCHECK_HOME}/syscheck.sh"
  exit
fi

## Import common definitions ##
source "${SYSCHECK_HOME}/config/syscheck-scripts.conf"

# script name, used when integrating with nagios/icinga
SCRIPTNAME=hsm_health

# uniq ID of script (please use in the name of this file also for convenience when finding the next available number)
SCRIPTID=39

# how many info/warn/error messages
NO_OF_ERR=17

initscript $SCRIPTID $NO_OF_ERR

default_script_getopt $*

# main part of script

LC_ALL=C
export LC_ALL

ERRSTATUS=0
WARNSTATUS=0
GLOBALERRMESSAGE=""
GLOBALWARNMESSAGE=""
APP_SESSION_OK=0
ENV_SESSION_OK=0
APP_SESSION_ERROR=""
ENV_SESSION_ERROR=""
BATTERY_CONFIG_OK=1
TEMPERATURE_CONFIG_OK=1
STORAGE_CONFIG_OK=1

trim_value () {
  sed 's/^[[:space:]]*//;s/[[:space:]]*$//'
}

extract_arrow_field () {
  OUTPUT=$1
  FIELD=$2
  printf '%s\n' "${OUTPUT}" | awk -v field="${FIELD}" '{ line=$0; sub(/^[[:space:]]*/, "", line); if (index(line, field) == 1) { rest=substr(line, length(field) + 1); if (rest ~ /^[[:space:]]*->[[:space:]]*/) { sub(/^[[:space:]]*->[[:space:]]*/, "", rest); value=rest } } } END { if (value != "") print value }' | trim_value
}

extract_colon_field () {
  OUTPUT=$1
  FIELD=$2
  printf '%s\n' "${OUTPUT}" | awk -v field="${FIELD}" '{ line=$0; sub(/^[[:space:]]*/, "", line); if (index(line, field) == 1) { rest=substr(line, length(field) + 1); if (rest ~ /^[[:space:]]*:[[:space:]]*/) { sub(/^[[:space:]]*:[[:space:]]*/, "", rest); value=rest } } } END { if (value != "") print value }' | trim_value
}

is_nonnegative_number () {
  [[ $1 =~ ^[0-9]+([.][0-9]+)?$ ]]
}

is_nonnegative_integer () {
  [[ $1 =~ ^[0-9]+$ ]]
}

float_lt () {
  awk -v first="$1" -v second="$2" 'BEGIN { exit !(first < second) }'
}

float_le () {
  awk -v first="$1" -v second="$2" 'BEGIN { exit !(first <= second) }'
}

float_ge () {
  awk -v first="$1" -v second="$2" 'BEGIN { exit !(first >= second) }'
}

free_percent_lt () {
  awk -v free="$1" -v total="$2" -v threshold="$3" 'BEGIN { exit !((free * 100 / total) < threshold) }'
}

format_decimal () {
  VALUE=$1
  DECIMALS=$2
  awk -v value="${VALUE}" -v decimals="${DECIMALS}" 'BEGIN { printf "%.*f", decimals, value }'
}

parse_voltage () {
  VALUE=$1
  if [[ ${VALUE} =~ ^[[:space:]]*([0-9]+([.][0-9]+)?)[[:space:]]*[Vv][[:space:]]*$ ]] ; then
    printf '%s' "${BASH_REMATCH[1]}"
    return 0
  fi
  return 1
}

parse_temperature () {
  VALUE=$1
  if [[ ${VALUE} =~ ^[[:space:]]*([0-9]+([.][0-9]+)?)[[:space:]]*(deg[.]?[[:space:]]*[Cc]|[Cc])[[:space:]]*$ ]] ; then
    printf '%s' "${BASH_REMATCH[1]}"
    return 0
  fi
  return 1
}

append_error () {
  ERRSTATUS=1
  if [[ -z ${GLOBALERRMESSAGE} ]] ; then
    GLOBALERRMESSAGE=$1
  else
    GLOBALERRMESSAGE="${GLOBALERRMESSAGE}, $1"
  fi
}

append_warning () {
  WARNSTATUS=1
  if [[ -z ${GLOBALWARNMESSAGE} ]] ; then
    GLOBALWARNMESSAGE=$1
  else
    GLOBALWARNMESSAGE="${GLOBALWARNMESSAGE}, $1"
  fi
}

validate_configuration () {
  if ! is_nonnegative_number "${BATTERY_WARNING_MARGIN_V}" ; then
    BATTERY_CONFIG_OK=0
  fi

  if ! is_nonnegative_number "${TEMPERATURE_WARNING_MARGIN_C}" ; then
    TEMPERATURE_CONFIG_OK=0
  fi

  if ! is_nonnegative_number "${STORAGE_WARNING_FREE_PERCENT}" || ! is_nonnegative_number "${STORAGE_ERROR_FREE_PERCENT}" ; then
    STORAGE_CONFIG_OK=0
  elif ! float_le "${STORAGE_WARNING_FREE_PERCENT}" "100" || ! float_le "${STORAGE_ERROR_FREE_PERCENT}" "100" || ! float_lt "${STORAGE_ERROR_FREE_PERCENT}" "${STORAGE_WARNING_FREE_PERCENT}" ; then
    STORAGE_CONFIG_OK=0
  fi
}

run_lunacm_sessions () {
  if [[ ! -x ${LUNACM} ]] ; then
    APP_SESSION_ERROR="LunaCM executable not found or not executable: ${LUNACM}"
    ENV_SESSION_ERROR="${APP_SESSION_ERROR}"
    return
  fi

  if ! command -v timeout >/dev/null 2>&1 ; then
    APP_SESSION_ERROR="timeout command not found"
    ENV_SESSION_ERROR="${APP_SESSION_ERROR}"
    return
  fi

  if ! is_nonnegative_integer "${LUNA_APPLICATION_SLOT}" ; then
    APP_SESSION_ERROR="Invalid application partition slot: ${LUNA_APPLICATION_SLOT}"
  fi

  if ! is_nonnegative_integer "${LUNA_ADMIN_SLOT}" ; then
    ENV_SESSION_ERROR="Invalid HSM administrative slot: ${LUNA_ADMIN_SLOT}"
  fi

  if ! is_nonnegative_integer "${LUNACM_TIMEOUT}" || (( LUNACM_TIMEOUT <= 0 )) ; then
    APP_SESSION_ERROR="Invalid LunaCM timeout: ${LUNACM_TIMEOUT}"
    ENV_SESSION_ERROR="${APP_SESSION_ERROR}"
    return
  fi

  if [[ -z ${APP_SESSION_ERROR} ]] ; then
    APP_OUTPUT=$({ echo "slot set -slot ${LUNA_APPLICATION_SLOT}"; echo "slot list"; echo "role show -name co"; echo "partition showinfo"; echo "exit"; } | timeout "${LUNACM_TIMEOUT}" "${LUNACM}" 2>&1)
    APP_RETURN_CODE=$?
    APP_OUTPUT=$(printf '%s\n' "${APP_OUTPUT}" | tr -d '\r')

    if (( APP_RETURN_CODE == 124 )) ; then
      APP_SESSION_ERROR="LunaCM application partition session timed out after ${LUNACM_TIMEOUT} seconds"
    elif (( APP_RETURN_CODE != 0 )) ; then
      APP_SESSION_ERROR="LunaCM application partition session failed with return code ${APP_RETURN_CODE}"
    else
      APP_COMMAND_ERRORS=$(printf '%s\n' "${APP_OUTPUT}" | grep -E 'Command Result[[:space:]]*:' | grep -Ev 'Command Result[[:space:]]*:[[:space:]]*No Error[[:space:]]*$' | paste -sd ';' -)
      APP_COMMAND_SUCCESS_COUNT=$(printf '%s\n' "${APP_OUTPUT}" | grep -Ec 'Command Result[[:space:]]*:[[:space:]]*No Error[[:space:]]*$')
      APP_CURRENT_SLOT=$(extract_colon_field "${APP_OUTPUT}" "Current Slot Id")
      if [[ -n ${APP_COMMAND_ERRORS} ]] ; then
        APP_SESSION_ERROR="LunaCM application partition command failed: ${APP_COMMAND_ERRORS}"
      elif (( APP_COMMAND_SUCCESS_COUNT < 4 )) ; then
        APP_SESSION_ERROR="LunaCM application partition session returned only ${APP_COMMAND_SUCCESS_COUNT} successful command results; expected at least 4"
      elif [[ ${APP_CURRENT_SLOT} != ${LUNA_APPLICATION_SLOT} ]] ; then
        APP_SESSION_ERROR="LunaCM did not select application partition slot ${LUNA_APPLICATION_SLOT}; current slot is ${APP_CURRENT_SLOT:-unknown}"
      else
        APP_SESSION_OK=1
      fi
    fi
  fi

  if [[ -z ${ENV_SESSION_ERROR} ]] ; then
    ENV_OUTPUT=$({ echo "slot set -slot ${LUNA_ADMIN_SLOT}"; echo "slot list"; echo "hsm envshow"; echo "exit"; } | timeout "${LUNACM_TIMEOUT}" "${LUNACM}" 2>&1)
    ENV_RETURN_CODE=$?
    ENV_OUTPUT=$(printf '%s\n' "${ENV_OUTPUT}" | tr -d '\r')

    if (( ENV_RETURN_CODE == 124 )) ; then
      ENV_SESSION_ERROR="LunaCM environmental session timed out after ${LUNACM_TIMEOUT} seconds"
    elif (( ENV_RETURN_CODE != 0 )) ; then
      ENV_SESSION_ERROR="LunaCM environmental session failed with return code ${ENV_RETURN_CODE}"
    else
      ENV_COMMAND_ERRORS=$(printf '%s\n' "${ENV_OUTPUT}" | grep -E 'Command Result[[:space:]]*:' | grep -Ev 'Command Result[[:space:]]*:[[:space:]]*No Error[[:space:]]*$' | paste -sd ';' -)
      ENV_COMMAND_SUCCESS_COUNT=$(printf '%s\n' "${ENV_OUTPUT}" | grep -Ec 'Command Result[[:space:]]*:[[:space:]]*No Error[[:space:]]*$')
      ENV_CURRENT_SLOT=$(extract_colon_field "${ENV_OUTPUT}" "Current Slot Id")
      if [[ -n ${ENV_COMMAND_ERRORS} ]] ; then
        ENV_SESSION_ERROR="LunaCM environmental command failed: ${ENV_COMMAND_ERRORS}"
      elif (( ENV_COMMAND_SUCCESS_COUNT < 3 )) ; then
        ENV_SESSION_ERROR="LunaCM environmental session returned only ${ENV_COMMAND_SUCCESS_COUNT} successful command results; expected at least 3"
      elif [[ ${ENV_CURRENT_SLOT} != ${LUNA_ADMIN_SLOT} ]] ; then
        ENV_SESSION_ERROR="LunaCM did not select HSM administrative slot ${LUNA_ADMIN_SLOT}; current slot is ${ENV_CURRENT_SLOT:-unknown}"
      else
        ENV_SESSION_OK=1
      fi
    fi
  fi
}

check_co_activation () {
  SCRIPTINDEX=$(addOneToIndex $SCRIPTINDEX)

  if (( APP_SESSION_OK != 1 )) ; then
    printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[2]} -d "${DESCR[2]}" -1 "${APP_SESSION_ERROR}"
    append_error "CO activation"
  elif printf '%s\n' "${APP_OUTPUT}" | grep -Eq '^[[:space:]]*Activated\.[[:space:]]*$' ; then
    printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $INFO -e ${ERRNO[1]} -d "${DESCR[1]}" -1 "Activated."
  else
    CO_STATE=$(printf '%s\n' "${APP_OUTPUT}" | awk '/State of role/ { in_role=1 } in_role && /^[[:space:]]*(Activated\.|Not initialized|Initialized)/ { line=$0; sub(/^[[:space:]]*/, "", line); print line; exit }')
    printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[2]} -d "${DESCR[2]}" -1 "Expected Activated.; reported ${CO_STATE:-no activation state}"
    append_error "CO activation"
  fi
}

check_partition_status () {
  SCRIPTINDEX=$(addOneToIndex $SCRIPTINDEX)

  if (( APP_SESSION_OK != 1 )) ; then
    printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[4]} -d "${DESCR[4]}" -1 "${APP_SESSION_ERROR}"
    append_error "partition status"
    return
  fi

  PARTITION_STATUS=$(extract_arrow_field "${APP_OUTPUT}" "Partition Status")
  if [[ ${PARTITION_STATUS} == "L3 Device" ]] ; then
    printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $INFO -e ${ERRNO[3]} -d "${DESCR[3]}" -1 "${PARTITION_STATUS}"
  else
    printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[4]} -d "${DESCR[4]}" -1 "${PARTITION_STATUS:-missing}"
    append_error "partition status"
  fi
}

check_fan () {
  FAN_FIELD=$1
  FAN_NAME=$2
  SCRIPTINDEX=$(addOneToIndex $SCRIPTINDEX)

  if (( ENV_SESSION_OK != 1 )) ; then
    printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[6]} -d "${DESCR[6]}" -1 "${FAN_NAME}" -2 "${ENV_SESSION_ERROR}"
    append_error "${FAN_NAME}"
    return
  fi

  FAN_STATUS=$(extract_colon_field "${ENV_OUTPUT}" "${FAN_FIELD}")
  FAN_STATUS_NORMALIZED=$(printf '%s' "${FAN_STATUS}" | tr '[:upper:]' '[:lower:]')
  if [[ ${FAN_STATUS_NORMALIZED} == active || ${FAN_STATUS_NORMALIZED} == standby ]] ; then
    printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $INFO -e ${ERRNO[5]} -d "${DESCR[5]}" -1 "${FAN_NAME}" -2 "${FAN_STATUS_NORMALIZED}"
  else
    printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[6]} -d "${DESCR[6]}" -1 "${FAN_NAME}" -2 "${FAN_STATUS:-missing}"
    append_error "${FAN_NAME}"
  fi
}

check_battery_voltage () {
  SCRIPTINDEX=$(addOneToIndex $SCRIPTINDEX)

  if (( ENV_SESSION_OK != 1 )) ; then
    printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[9]} -d "${DESCR[9]}" -1 "${ENV_SESSION_ERROR}"
    append_error "battery voltage"
    return
  fi

  if (( BATTERY_CONFIG_OK != 1 )) ; then
    printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[9]} -d "${DESCR[9]}" -1 "Invalid battery warning margin: ${BATTERY_WARNING_MARGIN_V}"
    append_error "battery voltage"
    return
  fi

  BATTERY_TEXT=$(extract_colon_field "${ENV_OUTPUT}" "Battery Voltage")
  BATTERY_THRESHOLD_TEXT=$(extract_colon_field "${ENV_OUTPUT}" "Battery Warning Threshold Voltage")
  BATTERY_VOLTAGE=$(parse_voltage "${BATTERY_TEXT}")
  BATTERY_PARSE_RESULT=$?
  BATTERY_THRESHOLD=$(parse_voltage "${BATTERY_THRESHOLD_TEXT}")
  BATTERY_THRESHOLD_PARSE_RESULT=$?

  if (( BATTERY_PARSE_RESULT != 0 || BATTERY_THRESHOLD_PARSE_RESULT != 0 )) ; then
    printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[9]} -d "${DESCR[9]}" -1 "Current '${BATTERY_TEXT:-missing}', threshold '${BATTERY_THRESHOLD_TEXT:-missing}'"
    append_error "battery voltage"
    return
  fi

  BATTERY_VOLTAGE_DISPLAY=$(format_decimal "${BATTERY_VOLTAGE}" 3)
  BATTERY_THRESHOLD_DISPLAY=$(format_decimal "${BATTERY_THRESHOLD}" 3)
  BATTERY_MARGIN_DISPLAY=$(format_decimal "${BATTERY_WARNING_MARGIN_V}" 3)
  BATTERY_DISTANCE=$(awk -v current="${BATTERY_VOLTAGE}" -v threshold="${BATTERY_THRESHOLD}" 'BEGIN { printf "%.3f", current - threshold }')
  BATTERY_DETAILS="current ${BATTERY_VOLTAGE_DISPLAY} V, threshold ${BATTERY_THRESHOLD_DISPLAY} V, remaining ${BATTERY_DISTANCE} V, warning margin ${BATTERY_MARGIN_DISPLAY} V"

  if float_le "${BATTERY_VOLTAGE}" "${BATTERY_THRESHOLD}" ; then
    printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[9]} -d "${DESCR[9]}" -1 "${BATTERY_DETAILS}"
    append_error "battery voltage"
  elif float_le "${BATTERY_DISTANCE}" "${BATTERY_WARNING_MARGIN_V}" ; then
    printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $WARN -e ${ERRNO[8]} -d "${DESCR[8]}" -1 "${BATTERY_DETAILS}"
    append_warning "battery voltage"
  else
    printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $INFO -e ${ERRNO[7]} -d "${DESCR[7]}" -1 "${BATTERY_DETAILS}"
  fi
}

check_temperature () {
  SCRIPTINDEX=$(addOneToIndex $SCRIPTINDEX)

  if (( ENV_SESSION_OK != 1 )) ; then
    printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[12]} -d "${DESCR[12]}" -1 "${ENV_SESSION_ERROR}"
    append_error "system temperature"
    return
  fi

  if (( TEMPERATURE_CONFIG_OK != 1 )) ; then
    printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[12]} -d "${DESCR[12]}" -1 "Invalid temperature warning margin: ${TEMPERATURE_WARNING_MARGIN_C}"
    append_error "system temperature"
    return
  fi

  TEMPERATURE_TEXT=$(extract_colon_field "${ENV_OUTPUT}" "System Temp")
  TEMPERATURE_THRESHOLD_TEXT=$(extract_colon_field "${ENV_OUTPUT}" "System Temperature Warning Threshold")
  TEMPERATURE=$(parse_temperature "${TEMPERATURE_TEXT}")
  TEMPERATURE_PARSE_RESULT=$?
  TEMPERATURE_THRESHOLD=$(parse_temperature "${TEMPERATURE_THRESHOLD_TEXT}")
  TEMPERATURE_THRESHOLD_PARSE_RESULT=$?

  if (( TEMPERATURE_PARSE_RESULT != 0 || TEMPERATURE_THRESHOLD_PARSE_RESULT != 0 )) ; then
    printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[12]} -d "${DESCR[12]}" -1 "Current '${TEMPERATURE_TEXT:-missing}', threshold '${TEMPERATURE_THRESHOLD_TEXT:-missing}'"
    append_error "system temperature"
    return
  fi

  TEMPERATURE_DISPLAY=$(format_decimal "${TEMPERATURE}" 1)
  TEMPERATURE_THRESHOLD_DISPLAY=$(format_decimal "${TEMPERATURE_THRESHOLD}" 1)
  TEMPERATURE_MARGIN_DISPLAY=$(format_decimal "${TEMPERATURE_WARNING_MARGIN_C}" 1)
  TEMPERATURE_DISTANCE=$(awk -v current="${TEMPERATURE}" -v threshold="${TEMPERATURE_THRESHOLD}" 'BEGIN { printf "%.1f", threshold - current }')
  TEMPERATURE_WARNING_BOUNDARY=$(awk -v threshold="${TEMPERATURE_THRESHOLD}" -v margin="${TEMPERATURE_WARNING_MARGIN_C}" 'BEGIN { printf "%.6f", threshold - margin }')
  TEMPERATURE_DETAILS="current ${TEMPERATURE_DISPLAY} C, threshold ${TEMPERATURE_THRESHOLD_DISPLAY} C, remaining ${TEMPERATURE_DISTANCE} C, warning margin ${TEMPERATURE_MARGIN_DISPLAY} C"

  if float_ge "${TEMPERATURE}" "${TEMPERATURE_THRESHOLD}" ; then
    printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[12]} -d "${DESCR[12]}" -1 "${TEMPERATURE_DETAILS}"
    append_error "system temperature"
  elif float_ge "${TEMPERATURE}" "${TEMPERATURE_WARNING_BOUNDARY}" ; then
    printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $WARN -e ${ERRNO[11]} -d "${DESCR[11]}" -1 "${TEMPERATURE_DETAILS}"
    append_warning "system temperature"
  else
    printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $INFO -e ${ERRNO[10]} -d "${DESCR[10]}" -1 "${TEMPERATURE_DETAILS}"
  fi
}

check_partition_storage () {
  SCRIPTINDEX=$(addOneToIndex $SCRIPTINDEX)

  if (( APP_SESSION_OK != 1 )) ; then
    printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[15]} -d "${DESCR[15]}" -1 "${APP_SESSION_ERROR}"
    append_error "partition storage"
    return
  fi

  if (( STORAGE_CONFIG_OK != 1 )) ; then
    printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[15]} -d "${DESCR[15]}" -1 "Invalid storage thresholds: warning ${STORAGE_WARNING_FREE_PERCENT} percent, error ${STORAGE_ERROR_FREE_PERCENT} percent"
    append_error "partition storage"
    return
  fi

  TOTAL_STORAGE=$(extract_colon_field "${APP_OUTPUT}" "Total Storage Space")
  USED_STORAGE=$(extract_colon_field "${APP_OUTPUT}" "Used Storage Space")
  FREE_STORAGE=$(extract_colon_field "${APP_OUTPUT}" "Free Storage Space")
  OBJECT_COUNT=$(extract_colon_field "${APP_OUTPUT}" "Object Count")

  if ! is_nonnegative_integer "${TOTAL_STORAGE}" || ! is_nonnegative_integer "${USED_STORAGE}" || ! is_nonnegative_integer "${FREE_STORAGE}" || ! is_nonnegative_integer "${OBJECT_COUNT}" ; then
    printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[15]} -d "${DESCR[15]}" -1 "Total '${TOTAL_STORAGE:-missing}', used '${USED_STORAGE:-missing}', free '${FREE_STORAGE:-missing}', objects '${OBJECT_COUNT:-missing}'"
    append_error "partition storage"
    return
  fi

  if (( TOTAL_STORAGE == 0 || USED_STORAGE > TOTAL_STORAGE || FREE_STORAGE > TOTAL_STORAGE )) ; then
    printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[15]} -d "${DESCR[15]}" -1 "Inconsistent values: total ${TOTAL_STORAGE} B, used ${USED_STORAGE} B, free ${FREE_STORAGE} B, objects ${OBJECT_COUNT}"
    append_error "partition storage"
    return
  fi

  TOTAL_MIB=$(awk -v bytes="${TOTAL_STORAGE}" 'BEGIN { printf "%.2f", bytes / 1048576 }')
  USED_MIB=$(awk -v bytes="${USED_STORAGE}" 'BEGIN { printf "%.2f", bytes / 1048576 }')
  FREE_MIB=$(awk -v bytes="${FREE_STORAGE}" 'BEGIN { printf "%.2f", bytes / 1048576 }')
  FREE_PERCENT=$(awk -v free="${FREE_STORAGE}" -v total="${TOTAL_STORAGE}" 'BEGIN { printf "%.4f", free * 100 / total }')
  STORAGE_DETAILS="total ${TOTAL_MIB} MiB, used ${USED_MIB} MiB, free ${FREE_MIB} MiB (${FREE_PERCENT} percent), objects ${OBJECT_COUNT}"

  if free_percent_lt "${FREE_STORAGE}" "${TOTAL_STORAGE}" "${STORAGE_ERROR_FREE_PERCENT}" ; then
    printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[15]} -d "${DESCR[15]}" -1 "${STORAGE_DETAILS}; error below ${STORAGE_ERROR_FREE_PERCENT} percent"
    append_error "partition storage"
  elif free_percent_lt "${FREE_STORAGE}" "${TOTAL_STORAGE}" "${STORAGE_WARNING_FREE_PERCENT}" ; then
    printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $WARN -e ${ERRNO[14]} -d "${DESCR[14]}" -1 "${STORAGE_DETAILS}; warning below ${STORAGE_WARNING_FREE_PERCENT} percent"
    append_warning "partition storage"
  else
    printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $INFO -e ${ERRNO[13]} -d "${DESCR[13]}" -1 "${STORAGE_DETAILS}"
  fi
}

validate_configuration
run_lunacm_sessions
check_co_activation
check_partition_status
check_fan "Fan 1 Status" "Fan 1"
check_fan "Fan 2 Status" "Fan 2"
check_battery_voltage
check_temperature
check_partition_storage

# send the summary message (00)
SCRIPTINDEX=00
if (( ERRSTATUS != 0 )) ; then
  printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[17]} -d "${DESCR[17]}" -1 "${GLOBALERRMESSAGE}"
elif (( WARNSTATUS != 0 )) ; then
  printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $INFO -e ${ERRNO[16]} -d "${DESCR[16]}" -1 "; warnings: ${GLOBALWARNMESSAGE}"
else
  printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $INFO -e ${ERRNO[16]} -d "${DESCR[16]}" -1 ""
fi
