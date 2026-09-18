#!/bin/bash

SYSCHECK_HOME="${SYSCHECK_HOME:-/opt/syscheck}" # use default if  unset
if [ ! -f ${SYSCHECK_HOME}/syscheck.sh ] ; then
  echo "Can't find $SYSCHECK_HOME/syscheck.sh"
  exit
fi

## Import common definitions ##
source $SYSCHECK_HOME/config/related-scripts.conf

# script name, used when integrating with nagios/icinga
SCRIPTNAME=deactivate_ca

# uniq ID of script (please use in the name of this file also for convinice for finding next availavle number)
SCRIPTID=910

# how many info/warn/error messages
NO_OF_ERR=2

initscript $SCRIPTID $NO_OF_ERR
getconfig "909"


# get command line arguments
INPUTARGS=`/usr/bin/getopt --options "hsv" --long "help,screen,verbose" -- "$@"`
if [ $? != 0 ] ; then schelp ; fi
#echo "TEMP: >$TEMP<"
eval set -- "$INPUTARGS"

while true; do
  case "$1" in
    -s|--screen  ) PRINTTOSCREEN=1; shift;;
    -v|--verbose ) PRINTVERBOSESCREEN=1 ; shift;;
    -h|--help )   schelp;exit;shift;;
    --) break;;
  esac
done

# main part of script

cd $EJBCA_HOME
for (( i = 0 ;  i < ${#CANAME[@]} ; i++ )) ; do

	SCRIPTINDEX=$(addOneToIndex $SCRIPTINDEX)
	NAME=${CANAME[$i]}
	printtoscreen "Deactivating CA :  ${CANAME[$i]}"
        CAOUT=$(mktemp)
        ./bin/ejbca.sh ca deactivateca $NAME 2>&1 | tee "${CAOUT}"
        retcode=${PIPESTATUS[0]}
        error=$(cat "${CAOUT}")
        rm -f "${CAOUT}"

        if [ "$retcode" -eq 0 ] ; then
	    printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $INFO -e ${ERRNO[1]} -d "${DESCR[1]}" -1 "$NAME"
	else
	    printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[2]} -d "${DESCR[2]}" -1 "$NAME" -2 "$error"
	fi


done
