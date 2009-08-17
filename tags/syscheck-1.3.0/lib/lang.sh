
getlangfiles(){
    SCRIPTID=$1

    commonlangfile="$SYSCHECK_HOME/lang/common.${SYSCHECK_LANG}"
    if [ -r $commonlangfile ] ; then
	. $commonlangfile
    else
	echo "cant open langfile ($commonlangfile)"
	exit
    fi
    
    scriptlangfile="$SYSCHECK_HOME/lang/${SCRIPTID}.${SYSCHECK_LANG}"
    if [ -r $scriptlangfile ] ; then
	. $scriptlangfile
    else
	echo "cant open langfile ($scriptlangfile)"
	exit
    fi

}