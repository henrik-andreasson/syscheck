#!/bin/bash

scriptid(){
  echo "${SCRIPTID}"
}

scriptname(){
  echo "${SCRIPTNAME}"
}

script_human_name(){
  echo "${SCRIPT_HUMAN_NAME}"
}

default_script_getopt() {
  # get command line arguments
  INPUTARGS=`/usr/bin/getopt --options "hsvcin" --long "help,screen,verbose,scriptid,scriptname,scripthumanname" -- "$@"`
  if [ $? != 0 ] ; then schelp ; fi
  eval set -- "$INPUTARGS"

  while true; do
    case "$1" in
      -s|--screen  ) PRINTTOSCREEN=1; shift;;
      -v|--verbose ) PRINTVERBOSESCREEN=1 ; shift;;
      -i|--scriptid        ) scriptid          ; exit ; shift;;
      -n|--scriptname      ) scriptname        ; exit ; shift;;
      -a|--scripthumanname ) script_human_name ; exit ; shift;;
      -h|--help            ) schelp            ; exit ; shift;;
      --) break;;
    esac
  done

}

initscript(){
   SCRIPTID=$1
   if [ "x${SCRIPTID}" == "x" ] ; then
      echo "$0: Can't init syscheck script without SCRIPTID "
      exit
   fi
   NOERRORS=$2
   if [ "x${NOERRORS}" == "x" ] ; then
      echo "$0: Can't init syscheck script without NOERRORS "
      exit
   fi

   getconfig ${SCRIPTID}
   getlangfiles ${SCRIPTID}
   if [ ${SCRIPTID} -ne 700 ] ; then
	   isSyscheckOnHold ${SCRIPTID}
   fi

   set -o noclobber  # dont overwrite files
   #set -o xtrace    # enable debug, normally not enabled

   # generate the selected number of error levels
   i=1
   while [ $i -le $NOERRORS ] ; do
     ERRNO[$i]="${SCRIPTID}${i}"
     let i="$i + 1"
   done
   export ERRNO


   # Index is used to uniquely identify one test done by the script (a harddrive, crl or cert)
   SCRIPTINDEX=00 ; export SCRIPTINDEX

   # default is no output, ie silent/cron mode
   PRINTTOSCREEN=${PRINTTOSCREEN:-0} ; export PRINTTOSCREEN

   # default is no output, ie silent/cron mode
   PRINTVERBOSESCREEN=${PRINTVERBOSESCREEN:-0} ; export PRINTVERBOSESCREEN

}

isSyscheckOnHold(){
    SCRIPTID=$1
    if [ -f ${SYSCHECK_HOME}/var/syscheck-on-hold ] ; then
        ONHOLDBY=$(cat ${SYSCHECK_HOME}/var/syscheck-on-hold | cut -f1 -d\:)

        sudo ${SYSCHECK_HOME}/lib/printlogmess-cli.sh -n "common" -i "00" -x "0" -l $WARN -e "00" -d "SYSCHECK IS ON HOLD BY: ${ONHOLDBY} OPERATION CANCELED SCRIPTID: ${SCRIPTID}"
        printf "00" "0" $WARN "00" "SYSCHECK IS ON HOLD BY: ${ONHOLDBY} OPERATION CANCELED SCRIPTID: ${SCRIPTID}"
		exit
	fi
}

getconfig(){
    CONFIGNAME=$1

    scriptconfig="${SYSCHECK_HOME}/config/${CONFIGNAME}.conf"
    if [ -r $scriptconfig ] ; then
	     source $scriptconfig
    else
	     echo "cant open configfile ($scriptconfig)"
	     exit
    fi
}

schelp(){

  /bin/echo
  /bin/echo -e "Scriptid: ${SCRIPTID} - ${SCRIPT_HUMAN_NAME}"
  /bin/echo
  /bin/echo -e "$HELP"
  /bin/echo
  /bin/echo "${HELP_ERR_CODES} / ${HELP_DESCRIPTION} - ${HELP_WHAT_TO_DO}"
  /bin/echo

  i=1
  while [ $i -le $NOERRORS ] ; do
    /bin/echo -e "${ERRNO[$i]} / ${DESCR[$i]} - ${HELP[$i]}"
    let i="$i + 1"
  done
  /bin/echo
  /bin/echo -e "${SCREEN_HELP}"
  /bin/echo
}



getlangfiles(){
  SCRIPTID=$1
  SYSCHECK_LANG="${SYSCHECK_LANG:-english}"

  commonlangfile="$SYSCHECK_HOME/lang/common.${SYSCHECK_LANG}"
  if [ -r $commonlangfile ] ; then
    source $commonlangfile
  else
    echo "cant open langfile ($commonlangfile)"
    exit
  fi

  scriptlangfile="$SYSCHECK_HOME/lang/${SCRIPTID}.${SYSCHECK_LANG}"
  if [ -r $scriptlangfile ] ; then
    source $scriptlangfile
  else
    echo "cant open langfile ($scriptlangfile)"
    exit
  fi

}

x-days-ago-datestr(){
  days=$1
  if [ "x$1" == "x" ] ; then
    days = 0
  fi
  date +"%Y-%m-%d" --date "now - ${days} days"

}
