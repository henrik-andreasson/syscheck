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

# help
if [ "x$1" = "x--help" ] ; then
    echo "$0 $HELP"
    echo "$ERRNO_1/$DESCR_1 - $HELP_1"
    echo "$ERRNO_2/$DESCR_2 - $HELP_2"
    echo "$ERRNO_3/$DESCR_3 - $HELP_3"
    echo "$ERRNO_4/$DESCR_4 - $HELP_4"
    echo "$ERRNO_5/$DESCR_5 - $HELP_5"
    exit
elif [ "x$1" = "x-s" -o  "x$1" = "x--screen"  ] ; then
    PRINTTOSCREEN=1
fi



checkcrl () {

	CRLNAME=$1
	if [ "x$CRLNAME" = "x" ] ; then
                printlogmess ${SCRIPTID} ${SCRIPTINDEX}   $ERROR $ERRNO_5 "$DESCR_5" "No CRL Configured"
		return
	fi
	LIMITMINUTES=$2
	if [ "x$LIMITMINUTES" = "x" ] ; then
                printlogmess ${SCRIPTID} ${SCRIPTINDEX}   $ERROR $ERRNO_5 "$DESCR_5" "No minutes configured"
		return
	fi
	cd /tmp
	outname=`mktemp`
	wget ${CRLNAME} --no-check-certificate -T 10 -t 1 -O $outname -o /dev/null
	if [ $? -ne 0 ] ; then
		printlogmess ${SCRIPTID} ${SCRIPTINDEX}   $ERROR $ERRNO_3 "$DESCR_3" "$CRLNAME"	
		return 1
	fi
	
# file not found where it should be
	if [ ! -f $outname ] ; then
		printlogmess ${SCRIPTID} ${SCRIPTINDEX}   $ERROR $ERRNO_1 "$DESCR_1" "$CRLNAME"
		return 2
	fi

	CRL_FILE_SIZE=`stat -c"%s" $outname`
# stat return check
	if [ $? -ne 0 ] ; then
		printlogmess ${SCRIPTID} ${SCRIPTINDEX}   $ERROR $ERRNO_4 "$DESCR_4" "$CRLNAME"	
		return 3
	fi

# crl of 0 size?
	if [ "x$CRL_FILE_SIZE" = "x0" ] ; then
		printlogmess ${SCRIPTID} ${SCRIPTINDEX}   $ERROR $ERRNO_4 "$DESCR_4" "$CRLNAME"	
		return 4
	fi

# now we can check the crl:s best before date is in the future with atleast HOURTHRESHOLD hours (defined in resources)
	TEMPDATE=`openssl crl -inform der -in $outname -nextupdate -noout`
	DATE=${TEMPDATE:11}
	CRLMINSLEFT=$(${SYSCHECK_HOME}/lib/cmp_dates.pl "$DATE" "$(date -u +"%Y-%m-%d %H:%M:%S %Z")")
	
	if [ "x$CRLMINSLEFT" = "x" ] ; then 
		printlogmess ${SCRIPTID} ${SCRIPTINDEX}   $ERROR $ERRNO_1 "$DESCR_1" "$CRLNAME (Cant parse file)"
		return 5
	fi
	if [ $CRLMINSLEFT -lt $LIMITMINUTES ] ; then
		printlogmess ${SCRIPTID} ${SCRIPTINDEX}   $ERROR $ERRNO_1 "$DESCR_1" "$CRLNAME (CRL Mins left :$CRLMINSLEFT/ Limit: $MINUTES)" 
	else
		printlogmess ${SCRIPTID} ${SCRIPTINDEX}   $INFO $ERRNO_2 "$DESCR_2" "$CRLNAME (CRL Mins left :$CRLMINSLEFT/ Limit: $MINUTES)"
	fi
	rm "$outname" 
}

#force Timezone to UTC
export TZ=UTC

for (( i = 0 ;  i < ${#CRLS[@]} ; i++ )) ; do
    SCRIPTINDEX=$(addOneToIndex $SCRIPTINDEX)
    checkcrl ${CRLS[$i]} ${MINUTES[$i]}
done

