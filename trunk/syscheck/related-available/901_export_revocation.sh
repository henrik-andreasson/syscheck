#!/bin/sh

# Set default home if not already set.
SYSCHECK_HOME=${SYSCHECK_HOME:-"/usr/local/syscheck"}

## Import common definitions ##
. $SYSCHECK_HOME/resources.sh

# uniq ID of script (please use in the name of this file also for convinice for finding next availavle number)
SCRIPTID=901

getlangfiles $SCRIPTID ;

ERRNO_1="${SCRIPTID}1"
ERRNO_2="${SCRIPTID}2"
ERRNO_3="${SCRIPTID}3"

### config ###
OUTPATH=/misc/pkg/ejbca/archival/revoked-certs/
REVLOG=${OUTPATH}/revokedcert.log
DATE=`date +'%Y-%m-%d_%H.%m.%S'`
DATE2=`date +'%Y/%m/%d'`

OUTPATH2="${OUTPATH}/${DATE2}"
mkdir -p ${OUTPATH2}

### end config ###

PRINTTOSCREEN=0
if [ "x$1" = "x-h" -o "x$1" = "x--help" ] ; then
	echo "$EREV_HELP"
	echo "$ERRNO_1/$EREV_DESCR_1 - $EREV_HELP_1"
	echo "$ERRNO_2/$EREV_DESCR_2 - $EREV_HELP_2"
	echo "$ERRNO_3/$EREV_DESCR_3 - $EREV_HELP_3"
	echo "${SCREEN_HELP}"
	exit
elif [ "x$1" = "x-s" -o  "x$1" = "x--screen" -o \
    "x$2" = "x-s" -o  "x$2" = "x--screen"   ] ; then
    PRINTTOSCREEN=1
fi 


if [ "x$1" = "x" -o ! -r "$1" ] ; then 
	printlogmess $ERROR $ERRNO_2 "$EREV_DESCR_2"  
	printtoscreen $ERROR $ERRNO_2 "$EREV_DESCR_2"
	exit
fi



date >> ${REVLOG} 
CERTSERIAL=`openssl x509 -inform der -in $1 -serial -noout | sed 's/serial=//'`
if [ $? -ne 0 ] ; then 
    printlogmess $ERROR $ERRNO_3 "$EREV_DESCR_3" "$?" 
fi


CERTISSUER=`openssl x509 -inform der -in $1 -issuer -noout | perl -ane 's/\//_/gio,s/issuer=//,s/=/-/gio,s/\ /_/gio,print'`
if [ $? -ne 0 ] ; then 
    printlogmess $ERROR $ERRNO_3 "$EREV_DESCR_3" "$?" 
fi

echo "CERTSERIAL: $CERTSERIAL" >> ${REVLOG}
echo "CERTISSUER: $CERTISSUER" >> ${REVLOG}
CERT=`openssl x509 -inform der -in $1`
if [ $? -ne 0 ] ; then 
    printlogmess $ERROR $ERRNO_3 "$EREV_DESCR_3" "$?" 
fi
CERTSTRING=`echo $CERT| perl -ane 's/\n//gio,print'`

echo "CERTSTRING: $CERTSTRING " >> ${REVLOG}
echo                            >> ${REVLOG}

OUTFILE="${OUTPATH2}/revoked-cert-${DATE}-${CERTISSUER}-${CERTSERIAL}"
openssl x509 -inform der -in $1 > ${OUTFILE}
if [ $? -eq 0 ] ; then 
    printlogmess $INFO $ERRNO_1 "$EREV_DESCR_1" "$?" 
else
    printlogmess $ERROR $ERRNO_3 "$EREV_DESCR_3" "$?" 
fi
