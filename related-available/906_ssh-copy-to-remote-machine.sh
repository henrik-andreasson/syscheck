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
NO_OF_ERR=7
initscript $SCRIPTID $NO_OF_ERR


# get command line arguments
INPUTARGS=`/usr/bin/getopt --options "hsvofuk" --long "help,screen,verbose,host:,key:,user:,file:,dir:" -- "$@"`
if [ $? != 0 ] ; then schelp ; fi
#echo "TEMP: >$TEMP<"
eval set -- "$INPUTARGS"

while true; do
  case "$1" in
    -s|--screen  ) PRINTTOSCREEN=1; shift;;
    -v|--verbose ) PRINTVERBOSESCREEN=1 ; shift;;
    -o|--host    ) SSHHOST=$2 ; shift 2;;
    -f|--file )    SSHFILE="$2" ; shift 2;;
    -u|--user )    SSHTOUSER=$2 ; shift 2;;
    -d|--dir )     SSHDIR=$2 ; shift 2;;
    -k|--key )     SSHFROMKEY="$2" ; shift 2;;
    -h|--help )   schelp;exit;shift;;
    --) break;;
  esac
done


# main part of script

if [ "x$SSHFILE" = "x" ] ; then
    printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[2]} -d "${DESCR[2]}"
    exit
fi

if [ "x$SSHHOST" = "x"  ] ; then
	printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX}  -l $ERROR -e ${ERRNO[3]} -d "${DESCR[3]}"
	exit
fi
BASE_FILE_NAME=$(basename $SSHFILE)

SCRIPTINDEX=$(addOneToIndex $SCRIPTINDEX)
CHECK_REMOTE_FILE_ALREADY_EXIST=$(${SYSCHECK_HOME}/related-available/915_remote_command_via_ssh.sh --host="${SSHHOST}" --user="${SSHTOUSER}" --key="${SSHFROMKEY}" --command="ls -1  \"${SSHDIR}/${BASE_FILE_NAME}\"" | tail -1)
FIXED_REMOTE_FILE_ALREADY_EXIST=$(echo "${CHECK_REMOTE_FILE_ALREADY_EXIST}" | grep "${BASE_FILE_NAME}")
if [ "x$FIXED_REMOTE_FILE_ALREADY_EXIST" == "x${SSHDIR}/${BASE_FILE_NAME}" ] ; then
  printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX}  -l $ERROR -e ${ERRNO[7]} -d "${DESCR[7]}" -1 "${SSHHOST}" -2 "${CHECK_REMOTE_FILE_ALREADY_EXIST}" -3 "${SSHFILE}"
  exit -1
fi

SCRIPTINDEX=$(addOneToIndex $SCRIPTINDEX)
FILESIZE=$(du --block-size=M "${SSHFILE}" | grep "${SSHFILE}" | awk '{print $1}' | sed 's/M//')
CHECK_REMOTE_SPACE=$(${SYSCHECK_HOME}/related-available/915_remote_command_via_ssh.sh --host="${SSHHOST}" --user="${SSHTOUSER}" --key="${SSHFROMKEY}" --command="df  --block-size=M \"${SSHDIR}\"" | tail -1 | awk '{print $4}' | sed 's/M//' )
if [ $? -ne 0 ] ; then
   printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[4]} -d "${DESCR[4]}" -1 "$runresult"
   exit -1
fi

FIXED_REMOTE_SPACE=$(echo "${CHECK_REMOTE_SPACE}" | grep -v "${SYSTEMNAME}")
if [ $FIXED_REMOTE_SPACE -lt $FILESIZE ] ; then
  printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX}  -l $ERROR -e ${ERRNO[5]} -d "${DESCR[5]}" -1 "${SSHHOST}" -2 "${SSHDIR}" -3 "${CHECK_REMOTE_SPACE}" -4 "${FILESIZE}"  -5 "${SSHFILE}"
  exit -1
fi

SCRIPTINDEX=$(addOneToIndex $SCRIPTINDEX)
runresult=$(echo "put ${SSHFILE}" | sftp -r ${SSHTIMEOUT} -i ${SSHFROMKEY} -b - ${SSHTOUSER}@${SSHHOST}:${SSHDIR} 2>&1)
if [ $? -ne 0 ] ; then
	printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[4]} -d "${DESCR[4]}" -1 "$runresult"
	exit -1
fi


SCRIPTINDEX=$(addOneToIndex $SCRIPTINDEX)
CHECK_REMOTE_FILESIZE=$(${SYSCHECK_HOME}/related-available/915_remote_command_via_ssh.sh --host="${SSHHOST}" --user="${SSHTOUSER}" --key="${SSHFROMKEY}" --command="du  --block-size=M \"${SSHDIR}/${BASE_FILE_NAME}\"" | tail -1)
if [ $? -ne 0 ] ; then
   printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[4]} -d "${DESCR[4]}" -1 "$CHECK_REMOTE_FILESIZE"
   exit -1
fi

FIXED_REMOTE_FILESIZE=$(echo "${CHECK_REMOTE_FILESIZE}" | grep "${BASE_FILE_NAME}" | awk '{print $1}' | sed 's/M//')
if [ $FIXED_REMOTE_FILESIZE -ne $FILESIZE ] ; then
  printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX}  -l $ERROR -e ${ERRNO[6]} -d "${DESCR[6]}" -1 "${SSHHOST}" -2 "${SSHDIR}" -3 "${CHECK_REMOTE_FILESIZE}" -4 "${FILESIZE}"  -5 "${SSHFILE}"
  exit -1
else
  printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $INFO -e ${ERRNO[1]} -d "${DESCR[1]}"
fi
