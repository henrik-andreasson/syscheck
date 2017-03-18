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

# Import common definitions
. $SYSCHECK_HOME/config/syscheck-scripts.conf

## Local Definitions ##
SCRIPTID=08

# Index is used to uniquely identify one test done by the script (a harddrive, crl or cert)
SCRIPTINDEX=00

getlangfiles $SCRIPTID
getconfig $SCRIPTID

ERRNO_1=01
ERRNO_2=02
ERRNO_3=03
ERRNO_4=04
ERRNO_5=05
ERRNO_6=06
ERRNO_7=07
ERRNO_8=08

# help
if [ "x$1" = "x--help" ] ; then
    echo "$0 $HELP"
    echo "$ERRNO_1/$DESCR_1 - $HELP_1"
    echo "$ERRNO_2/$DESCR_2 - $HELP_2"
    echo "$ERRNO_3/$DESCR_3 - $HELP_3"
    echo "$ERRNO_4/$DESCR_4 - $HELP_4"
    echo "$ERRNO_5/$DESCR_5 - $HELP_5"
    echo "$ERRNO_6/$DESCR_6 - $HELP_6"
    echo "$ERRNO_7/$DESCR_7 - $HELP_7"
    echo "$ERRNO_8/$DESCR_8 - $HELP_8"
    exit
elif [ "x$1" = "x-s" -o  "x$1" = "x--screen"  ] ; then
    PRINTTOSCREEN=1
fi



checkcrl () {

	CRLNAME=$1
	if [ "x$CRLNAME" = "x" ] ; then
                printlogmess ${NAME} ${SCRIPTID} ${SCRIPTINDEX}   $ERROR $ERRNO_5 "$DESCR_5" "No CRL Configured"
		return
	fi


# Limitminutes is now optional, if not configured the limits is crl WARN: validity/2 ERROR: validity/4 eg: CRL is valid to 12h, warn will be 6h and error 3h
	LIMITMINUTES=$2
	ERRMINUTES=$3
	

	
	cd /tmp
	outname=`mktemp`
    if [ "x${CHECKTOOL}" = "xwget" ] ; then
        ${CHECKTOOL} ${CRLNAME}  -T ${TIMEOUT} -t ${RETRIES}           -O $outname -o /dev/null
        if [ $? -ne 0 ] ; then
            printlogmess ${NAME} ${SCRIPTID} ${SCRIPTINDEX}   $ERROR $ERRNO_3 "$DESCR_3" "$CRLNAME"
        return 1
        fi

    elif [ "x${CHECKTOOL}" = "xcurl" ] ; then
        ${CHECKTOOL} ${CRLNAME} --retry ${RETRIES} --connect-timeout ${TIMEOUT} --output $outname 2>/dev/null
        if [ $? -ne 0 ] ; then
            printlogmess ${NAME} ${SCRIPTID} ${SCRIPTINDEX}   $ERROR $ERRNO_3 "$DESCR_3" "$CRLNAME"
        return 1
        fi
    else
        printlogmess ${NAME} ${SCRIPTID} ${SCRIPTINDEX}   $ERROR $ERRNO_3 "$DESCR_3"
    fi

	
# file not found where it should be
	if [ ! -f $outname ] ; then
		printlogmess ${NAME} ${SCRIPTID} ${SCRIPTINDEX}   $ERROR $ERRNO_1 "$DESCR_1" "$CRLNAME"
		return 2
	fi

	CRL_FILE_SIZE=`stat -c"%s" $outname`
# stat return check
	if [ $? -ne 0 ] ; then
		printlogmess ${NAME} ${SCRIPTID} ${SCRIPTINDEX}   $ERROR $ERRNO_4 "$DESCR_4" "$CRLNAME"	
		return 3
	fi

# crl of 0 size?
	if [ "x$CRL_FILE_SIZE" = "x0" ] ; then
		printlogmess ${NAME} ${SCRIPTID} ${SCRIPTINDEX}   $ERROR $ERRNO_4 "$DESCR_4" "$CRLNAME"	
		return 4
	fi


	LASTUPDATE=$(openssl crl -inform der -in $outname -lastupdate -noout | sed 's/lastUpdate=//')
	NEXTUPDATE=$(openssl crl -inform der -in $outname -nextupdate -noout | sed 's/nextUpdate=//')

	if [ "x$LIMITMINUTES" != "x" ] ; then
        ARGWARNMIN="--warnminutes=$LIMITMINUTES"
    fi
    if [ "x$ERRMINUTES" != "x" ] ; then
        ARGERRMIN="--errorminutes=$ERRMINUTES"
    fi
    
    CRLMESSAGE=$(${SYSCHECK_HOME}/lib/cmp_dates.py "$LASTUPDATE" "$NEXTUPDATE" ${ARGWARNMIN} ${ARGERRMIN} )
    CRLCHECK=$?
    if [ "x$CRLCHECK" = "x" ] ; then 
            printlogmess ${NAME} ${SCRIPTID} ${SCRIPTINDEX}   $ERROR $ERRNO_1 "$DESCR_1" "$CRLNAME (Cant parse file)"
    elif [ $CRLCHECK -eq 3 ] ; then
            printlogmess ${NAME} ${SCRIPTID} ${SCRIPTINDEX}   $ERROR $ERRNO_6 "$DESCR_6" "$CRLNAME: ${CRLMESSAGE}"
    elif [ $CRLCHECK -eq 2 ] ; then
            printlogmess ${NAME} ${SCRIPTID} ${SCRIPTINDEX}   $ERROR $ERRNO_7 "$DESCR_7" "$CRLNAME: ${CRLMESSAGE}"
    elif [ $CRLCHECK -eq 1 ] ; then
            printlogmess ${NAME} ${SCRIPTID} ${SCRIPTINDEX}   $WARN $ERRNO_8 "$DESCR_8" "$CRLNAME: ${CRLMESSAGE}"
    elif [ $CRLCHECK -eq 0 ] ; then
            printlogmess ${NAME} ${SCRIPTID} ${SCRIPTINDEX}   $INFO $ERRNO_2 "$DESCR_2" "$CRLNAME: ${CRLMESSAGE}"
    else
            printlogmess ${NAME} ${SCRIPTID} ${SCRIPTINDEX}   $ERROR $ERRNO_1 "$DESCR_1" "$CRLNAME: problem calculating validity"
    fi
    rm "$outname" 
}

#force Timezone to UTC
export TZ=UTC

for (( i = 0 ;  i < ${#CRLS[@]} ; i++ )) ; do
    SCRIPTINDEX=$(addOneToIndex $SCRIPTINDEX)
    checkcrl ${CRLS[$i]} ${MINUTES[$i]} ${ERRMIN[$i]}
done

