
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