#!/bin/bash

# 1. First check if SYSCHECK_HOME is set then use that
if [ "x${SYSCHECK_HOME}" = "x" ] ; then
# 2. Check if /etc/syscheck.conf exists then source that (put SYSCHECK_HOME=/path/to/syscheck in ther)
    if [ -e /etc/syscheck.conf ] ; then
	source /etc/syscheck.conf
    else
# 3. last resort use default path
	SYSCHECK_HOME="/opt/syscheck"
    fi
fi

if [ ! -f ${SYSCHECK_HOME}/syscheck.sh ] ; then echo "$0: Can't find syscheck.sh in SYSCHECK_HOME ($SYSCHECK_HOME)" ;exit ; fi

## Import common definitions ##
source $SYSCHECK_HOME/config/related-scripts.conf

# script name, used when integrating with nagios/icinga
SCRIPTNAME=export_revocation

# uniq ID of script (please use in the name of this file also for convinice for finding next availavle number)
SCRIPTID=901

# Index is used to uniquely identify one test done by the script (a harddrive, crl or cert)
SCRIPTINDEX=00

getlangfiles $SCRIPTID
getconfig $SCRIPTID

ERRNO_1="01"
ERRNO_2="02"
ERRNO_3="03"

mkdir -p ${OUTPATH2}

PRINTTOSCREEN=0
if [ "x$1" = "x-h" -o "x$1" = "x--help" ] ; then
	echo "$HELP"
	echo "$ERRNO_1/$DESCR_1 - $HELP_1"
	echo "$ERRNO_2/$DESCR_2 - $HELP_2"
	echo "$ERRNO_3/$DESCR_3 - $HELP_3"
	echo "${SCREEN_HELP}"
	exit
elif [ "x$1" = "x-s" -o  "x$1" = "x--screen" -o \
    "x$2" = "x-s" -o  "x$2" = "x--screen"   ] ; then
    PRINTTOSCREEN=1
fi 


### is there even a file as argument1 ?
if [ "x$1" = "x" -o ! -r "$1" ] ; then 
	printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   $ERROR $ERRNO_2 "$DESCR_2"  
	printtoscreen $ERROR $ERRNO_2 "$DESCR_2"
	exit
fi

# for inital checks
SCRIPTINDEX=$(addOneToIndex $SCRIPTINDEX)

date >> ${REVLOG} 
CERTSERIAL=`openssl x509 -inform der -in $1 -serial -noout | sed 's/serial=//'`
if [ $? -ne 0 ] ; then 
	printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   $ERROR $ERRNO_3 "$DESCR_3" "$?" 
	# we really need a serial
	exit
fi


CERTSUBJECT=`openssl x509 -inform der -in $1 -subject -noout | perl -ane 's/\//_/gio,s/subject=//,s/=/-/gio,s/\ /_/gio,print'`
if [ $? -ne 0 ] ; then 
	printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   $ERROR $ERRNO_3 "$DESCR_3" "$?" 
	# also without subject we cant continiue
	exit
fi

echo "CERTSERIAL: $CERTSERIAL" >> ${REVLOG}
echo "CERTSUBJECT: $CERTSUBJECT" >> ${REVLOG}
CERT=`openssl x509 -inform der -in $1`
if [ $? -ne 0 ] ; then 
	printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   $ERROR $ERRNO_3 "$DESCR_3" "$?" 
	# if we cant parse the cert
	exit
fi

CERTSTRING=`echo $CERT| perl -ane 's/\n//gio,print'`

echo "CERTSTRING: $CERTSTRING " >> ${REVLOG}
echo                            >> ${REVLOG}

SCRIPTINDEX=$(addOneToIndex $SCRIPTINDEX) 
OUTFILE="${OUTPATH2}/revoked-cert-${DATE}-${CERTSUBJECT}-${CERTSERIAL}"
openssl x509 -inform der -in $1 > ${OUTFILE}
if [ $? -eq 0 ] ; then 
    printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   $INFO $ERRNO_1 "$DESCR_1" "$?" 
else
    printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   $ERROR $ERRNO_3 "$DESCR_3" "$?" 
fi

for (( j=0; j < ${#REMOTE_HOST[@]} ; j++ )){
    printtoscreen "Copying file: ${OUTFILE} to:${REMOTE_HOST[$j]} dir:${REMOTE_DIR[$j]} remotreuser:${REMOTE_USER[$j]} sshkey:${SSHKEY[$j]}"
    SCRIPTINDEX=$(addOneToIndex $SCRIPTINDEX)
    ${SYSCHECK_HOME}/related-enabled/917_archive_file.sh ${OUTFILE} ${REMOTE_HOST[$j]} ${REMOTE_DIR[$j]} ${REMOTE_USER[$j]} ${SSHKEY[$j]}
}

