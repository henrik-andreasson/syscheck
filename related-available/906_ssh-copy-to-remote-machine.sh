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
SCRIPTNAME=ssh_copy_remote_machine

# uniq ID of script (please use in the name of this file also for convinice for finding next availavle number)
SCRIPTID=906




# how many info/warn/error messages
NO_OF_ERR=3
initscript $SCRIPTID $NO_OF_ERR


ERRNO[1]="01"
ERRNO[2]="02"
ERRNO[3]="03"
ERRNO[4]="04"


# get command line arguments
INPUTARGS=`/usr/bin/getopt --options "hsvofuk" --long "help,screen,verbose,host:,command:,key:,user:" -- "$@"`
if [ $? != 0 ] ; then schelp ; fi
#echo "TEMP: >$TEMP<"
eval set -- "$INPUTARGS"

while true; do
  case "$1" in
    -s|--screen  ) PRINTTOSCREEN=1; shift;;
    -v|--verbose ) PRINTVERBOSESCREEN=1 ; shift;;
    -o|--host    ) SSHHOST=$2 ; shift 2;;
    -f|--file ) SSHFILE="$2" ; shift 2;;
    -u|--user )    SSHTOUSER=$2 ; shift 2;;
    -k|--key )     SSHFROMKEY="-i $2" ; shift 2;;
    -h|--help )   schelp;exit;shift;;
    --) break;;
  esac
done


# main part of script

# arg1, if you use regexps, be sure to use "" , ex: "*.txt" on the command line
if [ "x$SSHFILE" = "x" ] ; then
    printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[2]} -d "${DESCR[2]}"
    exit
fi

if [ "x$SSHHOST" = "x"  ] ; then
	printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX}  $ERROR ${ERRNO[3]} "${DESCR[3]}"
	exit
fi


SCRIPTINDEX=$(addOneToIndex $SCRIPTINDEX)
runresult=`scp -r ${SSHTIMEOUT} ${SSHFROMKEY} ${SSHFILE} ${SSHTOUSER}${SSHHOST}:${SSHDIR} 2>&1`
if [ $? -eq 0 ] ; then
	printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX}  $INFO ${ERRNO[1]} "${DESCR[1]}"
else
	printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX}  $ERROR ${ERRNO[4]} "${DESCR[4]}" "$runresult"
	exit -1
fi
