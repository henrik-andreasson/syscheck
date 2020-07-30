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
SCRIPTNAME=send_result_as_message

# uniq ID of script (please use in the name of this file also for convinice for finding next availavle number)
SCRIPTID=932

# how many info/warn/error messages
NO_OF_ERR=2
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

for (( j=0; j < ${#SEND_MSG_COMMAND[@]} ; j++ )){
	printtoscreen "Sending status as message with: ${SEND_MSG_COMMAND[$j]} ${SEND_MSG_FILE[$j]}"
	SCRIPTINDEX=$(addOneToIndex $SCRIPTINDEX)
	SENDRES=$(${SEND_MSG_COMMAND[$j]} -c ${SEND_MSG_CONFIG[$j]} -m ${SEND_MSG_FILE[$j]} | tr -d '\n')
	if [ $? -ne 0 ] ; then
      		printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX}  $ERROR ${ERRNO[2]} "${DESCR[2]}" "${SEND_MSG_COMMAND[$j]} ${SEND_MSG_FILE[$j]}" "result: ${SENDRES}"
	else
		printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX}  $INFO ${ERRNO[1]} "${DESCR[1]}" "${SEND_MSG_COMMAND[$j]} ${SEND_MSG_FILE[$j]}" "result: ${SENDRES}"
	fi
}
