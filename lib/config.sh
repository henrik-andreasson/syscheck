
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
   isSyscheckOnHold ${SCRIPTID}

   set -o noclobber  # dont overwrite files
   #set -o xtrace    # enable debug, normally not enabled

   # generate the selected number of error levels
   i=1
   while [ $i -le $NOERRORS ] ; do
     ERRNO[$i]="${SCRIPTID}${i}"
     let i="$i + 1"
   done
   export ERRNO

   # default is no output, ie silent/cron mode
   PRINTTOSCREEN=0 ; export PRINTTOSCREEN

   # Index is used to uniquely identify one test done by the script (a harddrive, crl or cert)
   SCRIPTINDEX=00 ; export SCRIPTINDEX

   # extra output for operators troubleshooting
   PRINTVERBOSESCREEN=0 ; export PRINTVERBOSESCREEN

}

isSyscheckOnHold(){
    SCRIPTID=$1
    if [ -f ${SYSCHECK_HOME}/var/syscheck-on-hold ] ; then
        ONHOLDBY=$(cat ${SYSCHECK_HOME}/var/syscheck-on-hold | cut -f1 -d\:)
        ${SYSCHECK_HOME}/lib/printlogmess-cli.sh "common" "00" "0" $WARN "00" "SYSCHECK IS ON HOLD BY: ${ONHOLDBY} OPERATION CANCELED SCRIPTID: ${SCRIPTID}"
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
  /bin/echo -e "${SCRIPTID} - ${SCRIPT_HUMAN_NAME}"
  /bin/echo  "===================================="
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
