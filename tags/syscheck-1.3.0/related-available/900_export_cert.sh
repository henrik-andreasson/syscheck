#!/bin/sh


# Set default home if not already set.
SYSCHECK_HOME=${SYSCHECK_HOME:-"/usr/local/syscheck"}


## Import common definitions ##
. $SYSCHECK_HOME/resources.sh

# uniq ID of script (please use in the name of this file also for convinice for finding next availavle number)
SCRIPTID=900

getlangfiles $SCRIPTID || exit 1;
getconfig $SCRIPTID || exit 1;

ERRNO_1="${SCRIPTID}1"
ERRNO_2="${SCRIPTID}2"
ERRNO_3="${SCRIPTID}3"

PRINTTOSCREEN=
if [ "x$1" = "x-h" -o "x$1" = "x--help" ] ; then
	echo "$ECRT_HELP"
	echo "$ERRNO_1/$ECRT_DESCR_1 - $ECRT_HELP_1"
	echo "$ERRNO_2/$ECRT_DESCR_2 - $ECRT_HELP_2"
	echo "$ERRNO_3/$ECRT_DESCR_3 - $ECRT_HELP_3"
	echo "${SCREEN_HELP}"
	exit
elif [ "x$1" = "x-s" -o  "x$1" = "x--screen" -o \
    "x$2" = "x-s" -o  "x$2" = "x--screen"   ] ; then
    PRINTTOSCREEN=1
    shift
fi 


if [ "x$1" = "x" -o ! -r "$1" ] ; then 
	printlogmess $ERROR $ERRNO_3 "$ECRT_DESCR_2"  
	printtoscreen $ERROR $ERRNO_3 "$ECRT_DESCR_2"
	exit
fi

CERTFILE=
if [ ! -f $1 ] ; then
    printlogmess $ERROR $ERRNO_3 "$ECRT_DESCR_3" "$?"
    exit
else
	CERTFILE=$1	
fi

date >> ${CERTLOG} 
CERTSERIAL=`openssl x509 -inform der -in ${CERTFILE} -serial -noout | sed 's/serial=//'`
if [ $? -ne 0 ] ; then 
    printlogmess $ERROR $ERRNO_3 "$ECRT_DESCR_3" "$?"
    exit; 
fi

CERTSUBJECT=`openssl x509 -inform der -in ${CERTFILE} -subject -noout | perl -ane 's/\//_/gio,s/subject=//,s/=/-/gio,s/\ /_/gio,print'`
if [ $? -ne 0 ] ; then 
    printlogmess $ERROR $ERRNO_3 "$ECRT_DESCR_3" "$?" 
fi

echo "CERTSERIAL: $CERTSERIAL" >> ${CERTLOG}
echo "CERTSUBJECT: $CERTSUBJECT" >> ${CERTLOG}
CERT=`openssl x509 -inform der -in ${CERTFILE}`
if [ $? -ne 0 ] ; then 
    printlogmess $ERROR $ERRNO_3 "$ECRT_DESCR_3" "$?" 
fi

# putting the base64 string in the log (livrem och h�ngslen)
CERTSTRING=`echo $CERT| perl -ane 's/\n//gio,print'`
echo "CERTSTRING: $CERTSTRING " >> ${CERTLOG}
echo                            >> ${CERTLOG}

OUTFILE="${OUTPATH2}/archived-cert-${DATE}-${CERTSUBJECT}-${CERTSERIAL}"
openssl x509 -inform der -in ${CERTFILE} > ${OUTFILE}
if [ $? -eq 0 ] ; then 
    printlogmess $INFO $ERRNO_1 "$ECRT_DESCR_1" "$?" 
else
    printlogmess $ERROR $ERRNO_3 "$ECRT_DESCR_3" "$?" 
fi

