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
SCRIPTNAME=certpublish_remote_command

# uniq ID of script (please use in the name of this file also for convinice for finding next availavle number)
SCRIPTID=919

# how many info/warn/error messages
NO_OF_ERR=3
initscript $SCRIPTID $NO_OF_ERR || exit 1;


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


# get command line arguments
INPUTARGS=`/usr/bin/getopt --options "hsv" --long "help,screen,verbose,cert:" -- "$@"`
if [ $? != 0 ] ; then schelp ; fi
#echo "TEMP: >$TEMP<"
eval set -- "$INPUTARGS"

while true; do
  case "$1" in
    -c|--cert )   CERTFILE=$2; shift 2;;
    -s|--screen  ) PRINTTOSCREEN=1; shift;;
    -v|--verbose ) PRINTVERBOSESCREEN=1 ; shift;;
    -h|--help )   schelp;exit;shift;;
    --) break;;
  esac
done

# main part of script

if [ ! -r "$CERTFILE" ] ; then
	printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[3]} -d "${DESCR[3]}"
	printtoscreen $ERROR -e ${ERRNO[3]} -d "${DESCR[3]}"
	exit
fi


CERTSERIAL=`openssl x509 -inform der -in ${CERTFILE} -serial -noout | sed 's/serial=//'`
if [ $? -ne 0 ] ; then
    printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[3]} -d "${DESCR[3]}" -1 "$?"
fi

CERTDN=$(openssl x509 -inform der -in ${CERTFILE} -subject -noout |  sed 's/\//_/gi' | sed 's/subject=//gi' | sed s/=/-/gi | sed  's/\ /_/gi')
if [ $? -ne 0 ] ; then
    printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[3]} -d "${DESCR[3]}" -1 "$?"
fi

CERTUID=$(openssl x509 -inform der -in ${CERTFILE} -subject -noout | grep -oi 'uid=[[:alnum:][:space:]]*' |sed 's/uid=//gi')
if [ $? -ne 0 ] ; then
    printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[4]} -d "${DESCR[3]}" -1 "$?"
fi

CERTCN=$(openssl x509 -inform der -in ${CERTFILE} -subject -noout |  grep -oi 'cn=[[:alnum:][:space:]]*'  |sed 's/cn=//gi')
if [ $? -ne 0 ] ; then
    printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[3]} -d "${DESCR[3]}" -1 "$?"
fi

CERTSN=$(openssl x509 -inform der -in ${CERTFILE} -subject -noout |  grep -oi 'serialnumber=[[:alnum:][:space:]]*' |sed 's/serialnumber=//gi')
if [ $? -ne 0 ] ; then
    printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[3]} -d "${DESCR[3]}" -1 "$?"
fi

CERTSTRING=$(openssl x509 -inform der -in ${CERTFILE}| tr '\n' ';')
if [ $? -ne 0 ] ; then
    printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[3]} -d "${DESCR[3]}" -1 "$?"
fi

for (( j=0; j < ${#REMOTE_HOST[@]} ; j++ )){

    if [ ${REMOTE_ARG[$j]} = "SN" ] ; then
	    RemoteCmd="${REMOTE_CMD[$j]} ${CERTSN}"

    elif [ ${REMOTE_ARG[$j]} = "UID" ] ; then
	    RemoteCmd="${REMOTE_CMD[$j]} ${CERTUID}"

    elif [ ${REMOTE_ARG[$j]} = "CN" ] ; then
	    RemoteCmd="${REMOTE_CMD[$j]} ${CERTCN}"

    elif [ ${REMOTE_ARG[$j]} = "CERTSERIAL" ] ; then
	    RemoteCmd="${REMOTE_CMD[$j]} ${CERTSERIAL}"

    elif [ ${REMOTE_ARG[$j]} = "DN" ] ; then
	    RemoteCmd="${REMOTE_CMD[$j]} ${CERTDN}"

    elif [ ${REMOTE_ARG[$j]} = "CERTSTRING" ] ; then
	    RemoteCmd="${REMOTE_CMD[$j]} ${CERTSTRING}"

    else
	    RemoteCmd="${REMOTE_CMD[$j]}"
    fi

    printtoscreen "remotecommand arg: ${REMOTE_ARG[$j]} host:${REMOTE_HOST[$j]} cmd:${RemoteCmd} remotreuser:${REMOTE_USER[$j]} sshkey:${SSHKEY[$j]}"
    ${SYSCHECK_HOME}/related-enabled/915_remote_command_via_ssh.sh ${REMOTE_HOST[$j]} ${RemoteCmd} ${REMOTE_USER[$j]} ${SSHKEY[$j]}
}
