#!/bin/bash

SYSCHECK_HOME="${SYSCHECK_HOME:-/opt/syscheck}" # use default if  unset
if [ ! -f ${SYSCHECK_HOME}/syscheck.sh ] ; then
  echo "Can't find $SYSCHECK_HOME/syscheck.sh"
  exit
fi

if [ ! -f ${SYSCHECK_HOME}/syscheck.sh ] ; then echo "Can't find $SYSCHECK_HOME/syscheck.sh" ;exit ; fi

# Import common resources
source $SYSCHECK_HOME/config/related-scripts.conf

# script name, used when integrating with nagios/icinga
SCRIPTNAME=copy_htmf_config

# uniq ID of script (please use in the name of this file also for convinice for finding next availavle number)
SCRIPTID=921

# how many info/warn/error messages
NO_OF_ERR=1
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

${SYSCHECK_HOME}/related-enabled/915_remote_command_via_ssh.sh ${HOSTNAME_NODE2} "mkdir -p ${REMOTE_DIR}" ${SSH_USER} ${SSHKEY}
if [ $? -ne 0 ] ; then
	echo "couldn't make dir"
	exit
fi


for (( j=0; j < ${#HTMF_FILE[@]} ; j++ )){
	printtoscreen "Copying file: ${HTMF_FILE[$j]} to:${HOSTNAME_NODE2} dir:${REMOTE_DIR} remotreuser:${REMOTE_USER} sshkey: ${SSHKEY}"
	${SYSCHECK_HOME}/related-enabled/906_ssh-copy-to-remote-machine.sh "${HTMF_FILE[$j]}" ${HOSTNAME_NODE2} ${REMOTE_DIR} ${REMOTE_USER} ${SSHKEY}
	if [ $? -ne 0 ] ; then
		echo "couln't copy file \"${HTMF_FILE[$j]}\""
		exit
	fi

}
