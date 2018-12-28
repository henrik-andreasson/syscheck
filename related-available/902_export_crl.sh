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
SCRIPTNAME=export_crl

# uniq ID of script (please use in the name of this file also for convinice for finding next availavle number)
SCRIPTID=902

# how many info/warn/error messages
NO_OF_ERR=3
initscript $SCRIPTID $NO_OF_ERR

# get command line arguments
INPUTARGS=`/usr/bin/getopt --options "hsvc" --long "help,screen,verbose,crl" -- "$@"`
if [ $? != 0 ] ; then schelp ; fi
#echo "TEMP: >$TEMP<"
eval set -- "$INPUTARGS"

while true; do
  case "$1" in
    -s|--screen  ) PRINTTOSCREEN=1; shift;;
    -v|--verbose ) PRINTVERBOSESCREEN=1 ; shift;;
    -c|--crl )     CRLFILE=$2; shift 2;;
    -h|--help )    schelp;exit;shift;;
    --) break;;
  esac
done

# main part of script

if [ ! -d ${OUTPATH2} ] ; then
    mkdir -p ${OUTPATH2}
fi


if [ "x$CRLFILE" = "x" -o ! -r "$CRLFILE" ] ; then
	printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   $ERROR ${ERRNO[3]} "${DESCR[2]}"
	printtoscreen $ERROR ${ERRNO[3]} "${DESCR[2]}"
	# no file as input
	exit
fi


SCRIPTINDEX=$(addOneToIndex $SCRIPTINDEX)

date >> ${CRLLOG}

CRLISSUER=`openssl crl -inform der -in "$CRLFILE" -issuer -noout`
if [ $? -ne 0 ] ; then
    printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   $ERROR ${ERRNO[3]} "${DESCR[3]}" "$?"
    exit
fi

CRLISSUER2=`echo ${CRLISSUER} | perl -ane 's/\//_/gio,s/issuer=//,s/=/-/gio,s/\ /_/gio,print'`
if [ $? -ne 0 ] ; then
    printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   $ERROR ${ERRNO[3]} "${DESCR[3]}" "$?"
    exit
fi

CRLLASTUPDATE=`openssl crl -inform der -in "$CRLFILE" -lastupdate -noout`
if [ $? -ne 0 ] ; then
    printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   $ERROR ${ERRNO[3]} "${DESCR[3]}" "$?"
    exit
fi

CRLLASTUPDATE2=`echo ${CRLLASTUPDATE} | perl -ane 's/lastUpdate=//gio,s/\ /_/gio,s/:/./gio,print'`
if [ $? -ne 0 ] ; then
    printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   $ERROR ${ERRNO[3]} "${DESCR[3]}" "$?"
    exit
fi

CRL=`openssl crl -inform der -in "$CRLFILE"`
if [ $? -ne 0 ] ; then
    printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   $ERROR ${ERRNO[3]} "${DESCR[3]}" "$?"
    exit
fi

CRLSTRING=`echo $CRL | perl -ane 's/\n//gio,print'`
if [ $? -ne 0 ] ; then
    printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   $ERROR ${ERRNO[3]} "${DESCR[3]}" "$?"
    exit
fi


echo "CRLSTRING: $CRLSTRING"          >> ${CRLLOG}
echo "CRLLASTUPDATE: $CRLLASTUPDATE2" >> ${CRLLOG}
echo "CRLISSUER: $CRLISSUER2"         >> ${CRLLOG}



OUTFILE="${OUTPATH2}/${CRLISSUER2}.crl"

SCRIPTINDEX=$(addOneToIndex $SCRIPTINDEX)
openssl crl -inform der -in "$CRLFILE" > ${OUTFILE}
if [ $? -eq 0 ] ; then
    printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   $INFO ${ERRNO[1]} "${DESCR[1]}" "$?"
else
    printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   $ERROR ${ERRNO[3]} "${DESCR[3]}" "$?"
fi

for (( j=0; j < ${#REMOTE_HOST[@]} ; j++ )){
    printtoscreen "Copying file: ${OUTFILE} to:${REMOTE_HOST[$j]} dir:${REMOTE_DIR[$j]} remotreuser:${REMOTE_USER[$j]} sshkey:${SSHKEY[$j]}"
    ${SYSCHECK_HOME}/related-enabled/917_archive_file.sh ${OUTFILE} ${REMOTE_HOST[$j]} ${REMOTE_DIR[$j]} ${REMOTE_USER[$j]} ${SSHKEY[$j]}
}
