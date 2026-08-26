#!/bin/bash

SYSCHECK_HOME="${SYSCHECK_HOME:-/opt/syscheck}" # use default if  unset
if [ ! -f ${SYSCHECK_HOME}/syscheck.sh ] ; then
  echo "Can't find $SYSCHECK_HOME/syscheck.sh"
  exit
fi

## Import common definitions ##
source $SYSCHECK_HOME/config/common.conf

# source libsycheck
source ${SYSCHECK_HOME}/lib/libsyscheck.sh

# use the printlog function
source $SYSCHECK_HOME/lib/printlogmess.sh

# script name, used when integrating with nagios/icinga
SCRIPTNAME=logbook

# uniq ID of script (please use in the name of this file also for convinice for finding next availavle number)
SCRIPTID=701

# Index is used to uniquely identify one test done by the script (a harddrive, crl or cert)
SCRIPTINDEX=00


# Render logbook rows read on stdin. JSON rows carry the human-readable line in
# LEGACYFMT; a row that is not valid JSON is printed as-is rather than dropped,
# so a single corrupt line cannot hide the rest of the day's entries.
# One python3 for the whole batch, not one per row.
render_logbook_entries() {
  if [ "x${LOGBOOK_OUTPUTTYPE}" = "xJSON" ] ; then
    python3 -c '
import json, sys

for line in sys.stdin:
    line = line.strip()
    if not line:
        continue
    try:
        print(json.loads(line)["LEGACYFMT"])
    except (ValueError, KeyError):
        print(line)
'
  else
    cat
  fi
}


# main part start

printf "$0: ${LOGBOOK_GREETING}\n\n"

ExecutingUserName=$(whoami)
ExecutingUserId=$(id -u)


# how many info/warn/error messages
NO_OF_ERR=1
initscript $SCRIPTID $NO_OF_ERR

# get command line arguments
# the short options here must stay in sync with the case arms below, see the
# same note in lib/libsyscheck.sh
INPUTARGS=`/usr/bin/getopt --options "hsvrp" --long "help,screen,verbose,read,post" -- "$@"`
if [ $? != 0 ] ; then
  schelp
  exit 1
fi
eval set -- "$INPUTARGS"

while true; do
  case "$1" in
    -s|--screen  ) PRINTTOSCREEN=1; shift;;
    -v|--verbose ) PRINTVERBOSESCREEN=1 ; shift;;
    -r|--read    ) READ=1 ; shift;;
    -p|--post    ) POST=1 ; shift;;
    -h|--help )   schelp; exit;;
    --) break;;
    # backstop: never let an unhandled option reach the top of the loop
    * ) echo "${0##*/}: unhandled option '$1'" >&2 ; exit 1 ;;
  esac
done

# main part of script

if [ "x${ExecutingUserName}" = "xroot" ] ; then
    printf " ${DONT_RUN_AS_ROOT}\n"
    exit
fi


DAYS=1

if [ "x$READ" != "x1" -a "x$POST" != "x1"  ] ; then
    READ=1 # defaults to read
fi

if [ "x$POST" = "x1" ] ; then
    printf "${LOGBOOK_NEW_ENTRY} ${MESSAGELENGTH}\n"
    read -e -n ${MESSAGELENGTH} -r -p "> " LOGENTRY

    if [ "x$LOGENTRY" = "x" ] ; then
        printf "${LOGBOOK_EMPTY_ENTRY}\n"
    else
        sudo "${SYSCHECK_HOME}/lib/logbook-cli.sh" -n "${SCRIPTNAME}" -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $INFO -e ${ERRNO[1]} -d "${DESCR[1]}" -1 "${ExecutingUserName}" -2 "$LOGENTRY"
    fi
fi


if [ $DAYS -gt 1 ] ; then
  i=0
  while [ $i -lt $DAYS ] ; do
    datestr=$(date +"%Y%m%d" -d "now - $i day")
    printf "${LOGBOOK_ENTRIES_FOR_DATE}: $datestr\n"
    grep "${SYSTEMNAME} ${datestr}" "${LOGBOOK_FILENAME}" | render_logbook_entries
    let i="i + 1"
  done
else
  daysago=0
  if [ "x$READ" = "x1" ] ; then
    while [ true ] ; do
      datestr=$(date +"%Y%m%d" -d "now - $daysago day")
      printf "${LOGBOOK_ENTRIES_FOR_DATE}: $datestr\n"
      grep "${SYSTEMNAME} ${datestr}" "${LOGBOOK_FILENAME}" | render_logbook_entries
      let daysago="daysago + 1"
      printf "${LOGBOOK_END_OF_ENTRIES_PRESS_ENTER}"
      read a || break
    done
  fi
fi
