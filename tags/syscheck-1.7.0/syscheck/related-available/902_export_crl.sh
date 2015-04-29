#!/bin/bash

# Set SYSCHECK_HOME if not already set.

# 1. First check if SYSCHECK_HOME is set then use that
if [ "x${SYSCHECK_HOME}" = "x" ] ; then
# 2. Check if /etc/syscheck.conf exists then source that (put SYSCHECK_HOME=/path/to/syscheck in ther)
    if [ -e /etc/syscheck.conf ] ; then 
	source /etc/syscheck.conf 
    else
# 3. last resort use default path
	SYSCHECK_HOME="/usr/local/syscheck"
    fi
fi

if [ ! -f ${SYSCHECK_HOME}/syscheck.sh ] ; then echo "$0: Can't find syscheck.sh in SYSCHECK_HOME ($SYSCHECK_HOME)" ;exit ; fi




## Import common definitions ##
. $SYSCHECK_HOME/config/related-scripts.conf

# uniq ID of script (please use in the name of this file also for convinice for finding next availavle number)
SCRIPTID=902

# Index is used to uniquely identify one test done by the script (a harddrive, crl or cert)
SCRIPTINDEX=00

getlangfiles $SCRIPTID
getconfig $SCRIPTID

ERRNO_1="01"
ERRNO_2="02"
ERRNO_3="03"

mkdir -p ${OUTPATH2}

### end config ###

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


if [ "x$1" = "x" -o ! -r "$1" ] ; then 
	printlogmess ${SCRIPTID} ${SCRIPTINDEX}   $ERROR $ERRNO_3 "$DESCR_2"  
	printtoscreen $ERROR $ERRNO_3 "$DESCR_2"
	# no file as input
	exit
fi


SCRIPTINDEX=$(addOneToIndex $SCRIPTINDEX)

date >> ${CRLLOG} 

CRLISSUER=`openssl crl -inform der -in $1 -issuer -noout`
if [ $? -ne 0 ] ; then 
    printlogmess ${SCRIPTID} ${SCRIPTINDEX}   $ERROR $ERRNO_3 "$DESCR_3" "$?" 
    exit
fi

CRLISSUER2=`echo ${CRLISSUER} | perl -ane 's/\//_/gio,s/issuer=//,s/=/-/gio,s/\ /_/gio,print'`
if [ $? -ne 0 ] ; then 
    printlogmess ${SCRIPTID} ${SCRIPTINDEX}   $ERROR $ERRNO_3 "$DESCR_3" "$?" 
    exit
fi

CRLLASTUPDATE=`openssl crl -inform der -in $1 -lastupdate -noout`
if [ $? -ne 0 ] ; then 
    printlogmess ${SCRIPTID} ${SCRIPTINDEX}   $ERROR $ERRNO_3 "$DESCR_3" "$?" 
    exit
fi

CRLLASTUPDATE2=`echo ${CRLLASTUPDATE} | perl -ane 's/lastUpdate=//gio,s/\ /_/gio,s/:/./gio,print'`
if [ $? -ne 0 ] ; then 
    printlogmess ${SCRIPTID} ${SCRIPTINDEX}   $ERROR $ERRNO_3 "$DESCR_3" "$?" 
    exit
fi

CRL=`openssl crl -inform der -in $1`
if [ $? -ne 0 ] ; then 
    printlogmess ${SCRIPTID} ${SCRIPTINDEX}   $ERROR $ERRNO_3 "$DESCR_3" "$?" 
    exit
fi

CRLSTRING=`echo $CRL | perl -ane 's/\n//gio,print'`
if [ $? -ne 0 ] ; then 
    printlogmess ${SCRIPTID} ${SCRIPTINDEX}   $ERROR $ERRNO_3 "$DESCR_3" "$?" 
    exit
fi


echo "CRLSTRING: $CRLSTRING"          >> ${CRLLOG}
echo "CRLLASTUPDATE: $CRLLASTUPDATE2" >> ${CRLLOG}
echo "CRLISSUER: $CRLISSUER2"         >> ${CRLLOG}



OUTFILE="${OUTPATH2}/${CRLISSUER2}.crl"

SCRIPTINDEX=$(addOneToIndex $SCRIPTINDEX)
openssl crl -inform der -in $1 > ${OUTFILE}
if [ $? -eq 0 ] ; then 
    printlogmess ${SCRIPTID} ${SCRIPTINDEX}   $INFO $ERRNO_1 "$DESCR_1" "$?" 
else
    printlogmess ${SCRIPTID} ${SCRIPTINDEX}   $ERROR $ERRNO_3 "$DESCR_3" "$?" 
fi

for (( j=0; j < ${#REMOTE_HOST[@]} ; j++ )){
    printtoscreen "Copying file: ${OUTFILE} to:${REMOTE_HOST[$j]} dir:${REMOTE_DIR[$j]} remotreuser:${REMOTE_USER[$j]} sshkey:${SSHKEY[$j]}"
    ${SYSCHECK_HOME}/related-enabled/917_archive_file.sh ${OUTFILE} ${REMOTE_HOST[$j]} ${REMOTE_DIR[$j]} ${REMOTE_USER[$j]} ${SSHKEY[$j]}
}

