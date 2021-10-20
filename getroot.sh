#!/bin/bash

SYSCHECK_HOME="${SYSCHECK_HOME:-/opt/syscheck}" # use default if  unset
if [ ! -f ${SYSCHECK_HOME}/syscheck.sh ] ; then
  echo "Can't find $SYSCHECK_HOME/syscheck.sh"
  exit
fi

if [ ! -f ${SYSCHECK_HOME}/syscheck.sh ] ; then echo "Can't find $SYSCHECK_HOME/syscheck.sh" ;exit ; fi

## Import common definitions ##
source $SYSCHECK_HOME/config/common.conf

# source libsycheck
source ${SYSCHECK_HOME}/lib/libsyscheck.sh

# use the printlog function
source $SYSCHECK_HOME/lib/printlogmess.sh

# script name, used when integrating with nagios/icinga
SCRIPTNAME=getroot

# uniq ID of script (please use in the name of this file also for convinice for finding next availavle number)
SCRIPTID=700

# Index is used to uniquely identify one test done by the script (a harddrive, crl or cert)
SCRIPTINDEX=00

# how many info/warn/error messages
NO_OF_ERR=4
initscript $SCRIPTID $NO_OF_ERR


# get command line arguments
INPUTARGS=`/usr/bin/getopt --options "hr:p" --long "help,reason:,pause" -- "$@"`
if [ $? != 0 ] ; then schelp ; fi
eval set -- "$INPUTARGS"

while true; do
  case "$1" in
    -v|--verbose ) PRINTVERBOSESCREEN=1 ; shift;;
    -r|--reason ) REASON=$2 ; shift 2;;
    -p|--pause ) PAUSE=1 ; shift 1;;
    -h|--help )   schelp;exit;shift;;
    --) break;;
  esac
done

# main part of script


printf "$0: ${GETROOT_INTRO}\n\n"

ExecutingUserName=$(whoami)
ExecutingUserId=$(id -u)

if [ "x${ExecutingUserName}" = "xroot" ] ; then
    printf "${DONT_RUN_AS_ROOT}\n"
    exit
fi

if [ -f  ${SYSCHECK_HOME}/var/syscheck-on-hold ] ; then
  if [ "x${PAUSE}" != "x1" ] ;then
	   read -e -i "y" -r -p "${ASK_TO_REMOVE_SYSCHECK_ONHOLD} Y/n?" SYSCHECKONHOLDDONE
  else
    SYSCHECKONHOLDDONE=y
  fi
	if [ "x${SYSCHECKONHOLDDONE}" = "xy" -o "x$SYSCHECKONHOLDDONE" = "xY" ] ; then
		REASON=$(cat ${SYSCHECK_HOME}/var/syscheck-on-hold)
		sudo rm ${SYSCHECK_HOME}/var/syscheck-on-hold
		sudo ${SYSCHECK_HOME}/lib/printlogmess-cli.sh -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $INFO -e ${ERRNO[4]} -d "${DESCR[4]}" -1 "${ExecutingUserName} (${ExecutingUserId})" -2 "$REASON"
		printf "${SCRIPTID} ${SCRIPTINDEX} $INFO  ${ERRNO[4]} ${ExecutingUserName} (${ExecutingUserId}) ${DESCR[4]} $REASON\n"
		sudo ${SYSCHECK_HOME}/lib/logbook-cli.sh -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $INFO -e ${ERRNO[4]} -d "${DESCR[4]}" -1 "${ExecutingUserName}" -2 "$REASON"
		exit
	fi
fi

if [ "x${REASON}" == "x" ] ;then
  printf "${WHY_GET_ROOT}\n"
  read -e -i "${TEMPLATE_WHY}" -r -p "> " REASON
fi

if [ "x$REASON" = "x${TEMPLATE_WHY}" ] ; then
        REASON="NOREASON"
elif [ "x$REASON" = "x" ] ; then
      REASON="NOREASON"
fi

if [ "x${PAUSE}" != "x1" ] ;then
  read -e -i "y" -r -p "${SET_SYSCHECK_ONHOLD} Y/n?" SYSCHECKONHOLD
else
  SYSCHECKONHOLD=y
fi

if [ "x$SYSCHECKONHOLD" = "xy" -o "x$SYSCHECKONHOLD" = "xY" ] ; then
    sudo ${SYSCHECK_HOME}/lib/printlogmess-cli.sh -n "${SCRIPTNAME}" -i "${SCRIPTID}" -x "${SCRIPTINDEX}" -l $INFO -e ${ERRNO[3]} -d "${DESCR[3]}" -1 "${ExecutingUserName} (${ExecutingUserId})" -2 "$REASON"
    sudo ${SYSCHECK_HOME}/lib/logbook-cli.sh      -n "${SCRIPTNAME}" -i "${SCRIPTID}" -x "${SCRIPTINDEX}" -l $INFO -e ${ERRNO[3]} -d "${DESCR[3]}" -1 "${ExecutingUserName}" -2 "$REASON"
    printf "$(date):${REASON}:${ExecutingUserName}" | sudo tee ${SYSCHECK_HOME}/var/syscheck-on-hold > /dev/null
else
    sudo ${SYSCHECK_HOME}/lib/printlogmess-cli.sh -n "${SCRIPTNAME}" -i "${SCRIPTID}" -x "${SCRIPTINDEX}" -l $INFO -e ${ERRNO[1]} -d "${DESCR[1]}" -1 "${ExecutingUserName} (${ExecutingUserId})" -2 "$REASON"
    sudo ${SYSCHECK_HOME}/lib/logbook-cli.sh      -n "${SCRIPTNAME}" -i "${SCRIPTID}" -x "${SCRIPTINDEX}" -l $INFO -e ${ERRNO[1]} -d "${DESCR[1]}" -1 "${ExecutingUserName}" -2 "$REASON"
fi

sudo su -

if [ -f  ${SYSCHECK_HOME}/var/syscheck-on-hold ] ; then

  if [ "x${PAUSE}" != "x1" ] ;then
	   read -e -i "y" -r -p "${ASK_TO_REMOVE_SYSCHECK_ONHOLD} Y/n?" SYSCHECKONHOLDDONE
  else
     SYSCHECKONHOLDDONE=y
  fi


	if [ "x${SYSCHECKONHOLDDONE}" = "xy" -o "x$SYSCHECKONHOLDDONE" = "xY" ] ; then
		sudo rm ${SYSCHECK_HOME}/var/syscheck-on-hold
		sudo ${SYSCHECK_HOME}/lib/printlogmess-cli.sh -n "${SCRIPTNAME}" -i "${SCRIPTID}" -x "${SCRIPTINDEX}" -l $INFO -e "${ERRNO[4]}" -d "${DESCR[4]}" -1 "${ExecutingUserName} (${ExecutingUserId})" -2 "$REASON"
		sudo ${SYSCHECK_HOME}/lib/logbook-cli.sh      -n "${SCRIPTNAME}" -i "${SCRIPTID}" -x "${SCRIPTINDEX}" -l $INFO -e ${ERRNO[4]} -d "${DESCR[4]}"   -1 "${ExecutingUserName}" -2 "$REASON"
		exit
	fi
fi
