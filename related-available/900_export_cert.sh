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
SCRIPTNAME=export_cert

# uniq ID of script (please use in the name of this file also for convinice for finding next availavle number)
SCRIPTID=900

# how many info/warn/error messages
NO_OF_ERR=3
initscript $SCRIPTID $NO_OF_ERR


# get command line arguments
INPUTARGS=`/usr/bin/getopt --options "hsvc" --long "help,screen,verbose,cert" -- "$@"`
if [ $? != 0 ] ; then schelp ; fi
#echo "TEMP: >$TEMP<"
eval set -- "$INPUTARGS"

while true; do
  case "$1" in
    -s|--screen  ) PRINTTOSCREEN=1; shift;;
    -v|--verbose ) PRINTVERBOSESCREEN=1 ; shift;;
    -c|--cert )   CERTFILE=$2; shift 2;;
    -h|--help )   schelp;exit;shift;;
    --) break;;
  esac
done


# main part of script

if [ "x$CERTFILE" = "x" -o ! -r "$CERTFILE" ] ; then
	printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX}  $ERROR ${ERRNO[3]} "${DESCR[3]}"
	printtoscreen $ERROR ${ERRNO[3]} "${DESCR[3]}"
	exit
fi


if [ ! -d ${OUTPATH2} ] ; then
    mkdir -p ${OUTPATH2}
fi

date >> ${CERTLOG}
CERTSERIAL=`openssl x509 -inform der -in ${CERTFILE} -serial -noout | sed 's/serial=//'`
if [ $? -ne 0 ] ; then
    printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX}  $ERROR ${ERRNO[3]} "${DESCR[3]}" "$?"
    exit;
fi

CERTSUBJECT=`openssl x509 -inform der -in ${CERTFILE} -subject -noout | sed 's/\//_/gi' | sed 's/subject=//gi' | sed s/=/-/gi | sed  's/\ /_/gi'`
if [ $? -ne 0 ] ; then
    printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX}  $ERROR ${ERRNO[3]} "${DESCR[3]}" "$?"
fi

echo "CERTSERIAL: $CERTSERIAL" >> ${CERTLOG}
echo "CERTSUBJECT: $CERTSUBJECT" >> ${CERTLOG}
CERT=`openssl x509 -inform der -in ${CERTFILE}`
if [ $? -ne 0 ] ; then
    printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX}  $ERROR ${ERRNO[3]} "${DESCR[3]}" "$?"
fi

# putting the base64 string in the log (livrem och h�ngslen)
CERTSTRING=$(echo $CERT| tr '\n' ';')
echo "CERTSTRING: $CERTSTRING " >> ${CERTLOG}
echo                            >> ${CERTLOG}

SCRIPTINDEX=$(addOneToIndex $SCRIPTINDEX)
OUTFILE="${OUTPATH2}/archived-cert-${DATE}-${CERTSUBJECT}-${CERTSERIAL}"
openssl x509 -inform der -in ${CERTFILE} > ${OUTFILE}
if [ $? -eq 0 ] ; then
    printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX}  $INFO ${ERRNO[1]} "${DESCR[1]}" "$?"
else
    printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX}  $ERROR ${ERRNO[3]} "${DESCR[3]}" "$?"
fi

for (( j=0; j < ${#REMOTE_HOST[@]} ; j++ )){
    printtoscreen "Copying file: ${OUTFILE} to:${REMOTE_HOST[$j]} dir:${REMOTE_DIR[$j]} remotreuser:${REMOTE_USER[$j]} sshkey:${SSHKEY[$j]}"
    ${SYSCHECK_HOME}/related-enabled/917_archive_file.sh ${OUTFILE} ${REMOTE_HOST[$j]} ${REMOTE_DIR[$j]} ${REMOTE_USER[$j]} ${SSHKEY[$j]}
}
