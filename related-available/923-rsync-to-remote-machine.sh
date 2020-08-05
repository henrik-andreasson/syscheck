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
SCRIPTNAME=rsync_to_remote_machine

# uniq ID of script (please use in the name of this file also for convinice for finding next available number)
SCRIPTID=923

# how many info/warn/error messages
NO_OF_ERR=4
initscript $SCRIPTID $NO_OF_ERR


# get command line arguments
INPUTARGS=`/usr/bin/getopt --options "hsvfoku" --long "help,screen,verbose,files:,host:,key:,user:" -- "$@"`
if [ $? != 0 ] ; then schelp ; fi
#echo "TEMP: >$TEMP<"
eval set -- "$INPUTARGS"

while true; do
  case "$1" in
    -s|--screen  ) PRINTTOSCREEN=1; shift;;
    -v|--verbose ) PRINTVERBOSESCREEN=1 ; shift;;
    -o|--host    ) SSHHOST=$2 ; shift 2;;
    -f|--files )   FILES="$2" ; shift 2;;
    -u|--user )    SSHTOUSER=$2 ; shift 2;;
    -d|--dir )     SSHTODIR=$2 ; shift 2;;
    -k|--key )     SSHFROMKEY="$2" ; shift 2;;
    -h|--help )    schelp;exit;shift;;
    --) break;;
  esac
done

# main part of script

# arg1, if you use regexps, be sure to use "" , ex: "*.txt" on the command line
if [ "x$FILES" = "x" ] ; then
    printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[2]} -d "${DESCR[2]}"
    exit
else
    FILES="$1"
fi

# arg2, SSHHOST is MANDATORY, to which host to rsync the files
if [ "x$SSHHOST" = "x"  ] ; then
	printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[3]} -d "${DESCR[3]}"
	exit
fi

runresult=`rsync --recursive ${RSYNC_OPTIONS} -e "ssh ${SSHFROMKEY} ${SSHTOUSER}" ${FILES} ${SSHHOST}:${SSHDIR} 2>&1`
if [ $? -eq 0 ] ; then
	printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $INFO -e ${ERRNO[1]} -d "${DESCR[1]}"
else
	printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[4]} -d "${DESCR[4]}" "$runresult"
	exit -1
fi
