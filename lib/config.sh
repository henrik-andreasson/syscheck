
initscript(){
   SCRIPTID=$1
      exit
   getconfig ${SCRIPTID}
   getlangfiles ${SCRIPTID}
   isSyscheckOnHold ${SCRIPTID}
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
    SCRIPTID=$1
    
    scriptconfig="$SYSCHECK_HOME/config/${SCRIPTID}.conf"
    if [ -r $scriptconfig ] ; then
	. $scriptconfig
    else
	echo "cant open configfile ($scriptconfig)"
	exit
    fi

}
