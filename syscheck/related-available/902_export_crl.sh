#!/bin/sh

# Set default home if not already set.
SYSCHECK_HOME=${SYSCHECK_HOME:-"/usr/local/syscheck"}

## Import common definitions ##
. $SYSCHECK_HOME/resources.sh

# uniq ID of script (please use in the name of this file also for convinice for finding next availavle number)
SCRIPTID=902

getlangfiles $SCRIPTID
getconfig $SCRIPTID

ERRNO_1="${SCRIPTID}1"
ERRNO_2="${SCRIPTID}2"
ERRNO_3="${SCRIPTID}3"

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
	printlogmess $ERROR $ERRNO_3 "$DESCR_2"  
	printtoscreen $ERROR $ERRNO_3 "$DESCR_2"
	exit
fi



date >> ${CRLLOG} 

CRLISSUER=`openssl crl -inform der -in $1 -issuer -noout`
if [ $? -ne 0 ] ; then 
    printlogmess $ERROR $ERRNO_3 "$DESCR_3" "$?" 
fi

CRLISSUER2=`echo ${CRLISSUER} | perl -ane 's/\//_/gio,s/issuer=//,s/=/-/gio,s/\ /_/gio,print'`
if [ $? -ne 0 ] ; then 
    printlogmess $ERROR $ERRNO_3 "$DESCR_3" "$?" 
fi

CRLLASTUPDATE=`openssl crl -inform der -in $1 -lastupdate -noout`
if [ $? -ne 0 ] ; then 
    printlogmess $ERROR $ERRNO_3 "$DESCR_3" "$?" 
fi

CRLLASTUPDATE2=`echo ${CRLLASTUPDATE} | perl -ane 's/lastUpdate=//gio,s/\ /_/gio,s/:/./gio,print'`
if [ $? -ne 0 ] ; then 
    printlogmess $ERROR $ERRNO_3 "$DESCR_3" "$?" 
fi

CRL=`openssl crl -inform der -in $1`
if [ $? -ne 0 ] ; then 
    printlogmess $ERROR $ERRNO_3 "$DESCR_3" "$?" 
fi

CRLSTRING=`echo $CRL | perl -ane 's/\n//gio,print'`
if [ $? -ne 0 ] ; then 
    printlogmess $ERROR $ERRNO_3 "$DESCR_3" "$?" 
fi


echo "CRLSTRING: $CRLSTRING"          >> ${CRLLOG}
echo "CRLLASTUPDATE: $CRLLASTUPDATE2" >> ${CRLLOG}
echo "CRLISSUER: $CRLISSUER2"         >> ${CRLLOG}

#OUTFILE="${OUTPATH2}/archived-crl-${DATE}-${CRLLASTUPDATE2}-${CRLISSUER2}"

OUTFILE="${OUTPATH2}/${CRLISSUER2}.crl"

openssl crl -inform der -in $1 > ${OUTFILE}
if [ $? -eq 0 ] ; then 
    printlogmess $INFO $ERRNO_1 "$DESCR_1" "$?" 
else
    printlogmess $ERROR $ERRNO_3 "$DESCR_3" "$?" 
fi

for (( j=0; j < ${#REMOTE_HOST[@]} ; j++ )){
    printtoscreen "Copying file: ${OUTFILE} to:${REMOTE_HOST[$j]} dir:${REMOTE_DIR[$j]} remotreuser:${REMOTE_USER[$j]} sshkey:${SSHKEY[$j]}"
    ${SYSCHECK_HOME}/related-enabled/917_archive_file.sh ${OUTFILE} ${REMOTE_HOST[$j]} ${REMOTE_DIR[$j]} ${REMOTE_USER[$j]} ${SSHKEY[$j]}
}

