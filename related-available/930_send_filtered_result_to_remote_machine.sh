#!/bin/bash

SYSCHECK_HOME="${SYSCHECK_HOME:-/opt/syscheck}" # use default if  unset
if [ ! -f ${SYSCHECK_HOME}/syscheck.sh ] ; then
  echo "Can't find $SYSCHECK_HOME/syscheck.sh"
  exit
fi

if [ ! -f ${SYSCHECK_HOME}/syscheck.sh ] ; then echo "Can't find $SYSCHECK_HOME/syscheck.sh" ;exit ; fi

## Import common definitions ##
source $SYSCHECK_HOME/config/related-scripts.conf

# script name, used when integrating with nagios/icinga
SCRIPTNAME=send_syscheck_result_to_remote_machine

# uniq ID of script (please use in the name of this file also for convinice for finding next availavle number)
SCRIPTID=930

# how many info/warn/error messages
NO_OF_ERR=3
initscript $SCRIPTID $NO_OF_ERR

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

for (( j=0; j < ${#REMOTE_HOSTNAME[@]} ; j++ )){
	printtoscreen "Copying file: ${LOCAL_FILE[$j]} to:${REMOTE_HOSTNAME[$j]} dir:${REMOTE_DIR[$j]} remotreuser:${REMOTE_USER[$j]} sshkey: ${SSHKEY[$j]}"
	SCRIPTINDEX=$(addOneToIndex $SCRIPTINDEX)
	SSHCOPYRES=$(${SYSCHECK_HOME}/related-enabled/906_ssh-copy-to-remote-machine.sh "${LOCAL_FILE[$j]}" ${REMOTE_HOSTNAME[$j]} ${REMOTE_DIR[$j]}/${REMOTE_FILE[$j]} ${REMOTE_USER[$j]} ${SSHKEY[$j]})
	if [ $? -ne 0 ] ; then
      		printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX}  $ERROR ${ERRNO[2]} "${DESCR[2]}" ${LOCAL_FILE[$j]} "file: ${LOCAL_FILE[$j]} to:${REMOTE_HOSTNAME[$j]} dir:${REMOTE_DIR[$j]} remotreuser:${REMOTE_USER[$j]} sshkey: ${SSHKEY[$j]} result: ${SSHCOPYRES}"
	else
		printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX}  $INFO ${ERRNO[1]} "${DESCR[1]}" ${LOCAL_FILE[$j]} ${SSHCOPYRES}
	fi
}
