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
SCRIPTNAME=remote_ssh_command

# uniq ID of script (please use in the name of this file also for convinice for finding next availavle number)
SCRIPTID=915

# how many info/warn/error messages
NO_OF_ERR=4
initscript $SCRIPTID $NO_OF_ERR


# get command line arguments
INPUTARGS=`/usr/bin/getopt --options "hsvocku" --long "help,screen,verbose,host:,command:,key:,user:" -- "$@"`
if [ $? != 0 ] ; then schelp ; fi
#echo "TEMP: >$TEMP<"
eval set -- "$INPUTARGS"

while true; do
  case "$1" in
    -s|--screen  ) PRINTTOSCREEN=1; shift;;
    -v|--verbose ) PRINTVERBOSESCREEN=1 ; shift;;
    -o|--host    ) SSHHOST=$2 ; shift 2;;
    -c|--command ) SSHCMD=$2 ; shift 2;;
    -u|--user )    SSHTOUSER=$2 ; shift 2;;
    -k|--key )     SSHFROMKEY="$2" ; shift 2;;
    -h|--help )    schelp;exit;shift;;
    --) break;;
  esac
done


# main part of script

if [ "x$SSHHOST" = "x"  ] ; then
	printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[2]} -d "${DESCR[2]}"
	exit -1
fi

if [ "x$SSHCMD" = "x"  ] ; then
        printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[3]} -d "${DESCR[3]}"
        exit -1
fi

if [ "x$SSHTOUSER" = "x"  ] ; then
  printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[3]} -d "${DESCR[3]}"
  exit -1
fi



ssh ${SSHOPTIONS} -i ${SSHFROMKEY} -l ${SSHTOUSER} ${SSHHOST} ${SSHCMD} 2>&1
retcode=$?

if [ $retcode -eq 0 ] ; then
	printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $INFO -e ${ERRNO[1]} -d "${DESCR[1]}" -1 "${SSHTOUSER}" -2 "${SSHHOST}" -3 "${SSHCMD}"
else
	printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX}  -l $ERROR -e ${ERRNO[4]} -d "${DESCR[4]}" -1 "$retcode"
	exit $retcode
fi
