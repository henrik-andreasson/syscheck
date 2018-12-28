
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
