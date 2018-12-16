#!/bin/bash

#Scripts that creates replication privilegdes for the slave db to the master.

# Set SYSCHECK_HOME if not already set.

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

## Import common definitions ##
source $SYSCHECK_HOME/config/common.conf

# scriptname used to map and explain scripts in icinga and other
SCRIPTNAME=logbook

# uniq ID of script (please use in the name of this file also for convinice for finding next availavle number)
SCRIPTID=701

# Index is used to uniquely identify one test done by the script (a harddrive, crl or cert)
SCRIPTINDEX=00

getlangfiles $SCRIPTID || exit 1;
getconfig $SCRIPTID || exit 1;

ERRNO_1="${SCRIPTID}1"
ERRNO_2="${SCRIPTID}2"
ERRNO_3="${SCRIPTID}3"
ERRNO_4="${SCRIPTID}4"

printf "$0: ${LOGBOOK_GREETING}\n\n"

ExecutingUserName=$(whoami)
ExecutingUserId=$(id -u)

if [ "x${ExecutingUserName}" = "xroot" ] ; then
    printf " ${DONT_RUN_AS_ROOT}\n"
    exit
fi

printhelp () {
	/bin/echo -e "$HELP"
	/bin/echo -e "$0 [ -r <days> |  -p ] (read is default)"
	exit
}

DAYS=1

#TEMP=`/usr/bin/getopt --options "hr:p" --long "help,read:,post" -- "$@"`
while getopts :r:ph opt ; do
  case "$opt" in
    r ) READ=1
            if [ -n $OPTARG ] ; then
                      DAYS=$OPTARG
            fi
            shift;;
    p ) POST=1; shift;;
    h ) printhelp; exit;;
    --) break ;;
  esac
done



if [ "x$READ" != "x1" -a "x$POST" != "x1"  ] ; then
    READ=1 # defaults to read
fi

if [ "x$POST" = "x1" ] ; then
    printf "${LOGBOOK_NEW_ENTRY} ${MESSAGELENGTH}\n"
    read -e -n ${MESSAGELENGTH} -r -p "> " LOGENTRY

    if [ "x$LOGENTRY" = "x" ] ; then
        printf "${LOGBOOK_EMPTY_ENTRY}\n"
    else
        su - root -c "${SYSCHECK_HOME}/lib/logbook-cli.sh ${SCRIPTID} ${SCRIPTINDEX} $INFO $ERRNO_1 \"$DESCR_1\" \"${ExecutingUserName}\" \"$LOGENTRY\""
    fi
fi


if [ $DAYS -gt 1 ] ; then
  i=0
  while [ $i -lt $DAYS ] ; do
    datestr=$(date +"%Y%m%d" -d "now - $i day")
    printf "${LOGBOOK_ENTRIES_FOR_DATE}: $datestr\n"
    if [ ${LOGBOOK_OUTPUTTYPE} = "JSON" ] ; then
      LOGENTRIES=$(grep "${SYSTEMNAME} ${datestr}" ${LOGBOOK_FILENAME})
      IFS=$'\n'
      for row in $LOGENTRIES ; do
        echo $row |  python -c 'import json,sys;obj=json.load(sys.stdin);print obj["LEGACYFMT"]';
      done
    else
      grep "${SYSTEMNAME} ${datestr}" ${LOGBOOK_FILENAME}
    fi
    let i="i + 1"
  done
else
  daysago=0
  if [ "x$READ" = "x1" ] ; then
    while [ true ] ; do
      datestr=$(date +"%Y%m%d" -d "now - $daysago day")
      printf "${LOGBOOK_ENTRIES_FOR_DATE}: $datestr\n"
      if [ "x${LOGBOOK_OUTPUTTYPE}" = "xJSON" ] ; then
        LOGENTRIES=$(grep "${SYSTEMNAME} ${datestr}" ${LOGBOOK_FILENAME})
        IFS=$'\n'
        for row in $LOGENTRIES ; do
          echo $row |  python -c 'import json,sys;obj=json.load(sys.stdin);print obj["LEGACYFMT"]';
        done
      else
        grep "${SYSTEMNAME} ${datestr}" ${LOGBOOK_FILENAME}
      fi
      let daysago="daysago + 1"
      printf "${LOGBOOK_END_OF_ENTRIES_PRESS_ENTER}"
      read a
    done
  fi
fi
