#!/bin/bash

# The script fetches a crl from the ca and copies to a local dir or scp the crl to a webserver.

# Set SYSCHECK_HOME if not already set.

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

# source env vars from system that dont get included when running from cron



# Import common resources
source $SYSCHECK_HOME/config/related-scripts.conf


## local definitions ##
# uniq ID of script (please use in the name of this file also for convinice for finding next availavle number)
SCRIPTID=905

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
ERRNO_9=09
ERRNO_10=10



if [ "x$1" = "x--help" -o "x$1" = "x-h" ] ; then
        echo "$0 <-s|--screen>"
        exit
elif [ "x$1" = "x-s" -o  "x$1" = "x--screen"  ] ; then
    PRINTTOSCREEN=1
fi 


### get crl ###
### CRLFILE will be overwritten and migth be empty 
### soo call me with a temporary file!!!
get () {
    CRLNAME=$1
    CRLFILE=$2
    cd ${EJBCA_HOME}
    printtoscreen "${EJBCA_HOME}/bin/ejbca.sh ca getcrl $CRLNAME $CRLFILE"
    CMD=$(${EJBCA_HOME}/bin/ejbca.sh ca getcrl $CRLNAME "$CRLFILE")
    if [ $? != 0 -o  ! -r $CRLFILE  ] ; then
        printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   $ERROR $ERRNO_6 "$PUBL_DESCR_6" "$CRLNAME/$CRLFILE"
    fi
    printtoscreen $CMD

}


### put crl ###
put () {

    REMOTEHOST=$1
    CRLFILE=$2
    REMOTEDIR=$3
    SSHKEY=$4
    SSHUSER=$5
    
    $SYSCHECK_HOME/related-enabled/906_ssh-copy-to-remote-machine.sh -s $CRLFILE $REMOTEHOST $REMOTEDIR $SSHUSER $SSHKEY

    if [ $? = 0 ] ; then
        printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   $INFO $ERRNO_8 "$PUBL_DESCR_8" $CRLNAME $REMOTEHOST 
    else
	printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   $ERROR $ERRNO_2 "$PUBL_DESCR_2" $CRLNAME $REMOTEHOST
    fi
}


### check crl ###
checkcrl () {

    CRLFILE=$1
    WTIME=$2
    ETIME=$2

    wishour=$(echo $WTIME | grep -i "h")
    wismin=$(echo $WTIME  | grep -i "m")
    wdigits=$(echo $WTIME| perl -ane 'm/(\d+)/,print "$1"')
    wunit="hours"
    wcmdopts=""
    if [ "x$wismin" != "x" ] ; then
	wcmdopts="--return-in-minutes"
	wunit="minutes"
    elif [ "x$wishour" != "x" ] ; then
#	TIME=$digits
	wunit="hours"
    else
	# todo fail not known time
	# default to use only number as before
#	TIME=$digits
	wunit="hours"
    fi
    WTIME=$wdigits

    eishour=$(echo $ETIME | grep -i "h")
    eismin=$(echo $ETIME  | grep -i "m")
    edigits=$(echo $ETIME| perl -ane 'm/(\d+)/,print "$1"')
    eunit="hours"
    ecmdopts=""
    if [ "x$eismin" != "x" ] ; then
	ecmdopts="--return-in-minutes"
	eunit="minutes"
    elif [ "x$eishour" != "x" ] ; then
#	TIME=$digits
	eunit="hours"
    else
	# todo fail not known time
	# default to use only number as before
#	TIME=$digits
	eunit="hours"
    fi
    ETIME=$edigits
	

# file not found where it should be
    if [ ! -f $CRLFILE ] ; then
	printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   $ERROR $ERRNO_4 "$PUBL_DESCR_4" $CRLFILE
        return 4
    fi

# stat return check
    CRL_FILE_SIZE=`stat -c"%s" $CRLFILE`
    if [ $? -ne 0 ] ; then
	printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   $ERROR $ERRNO_5 "$PUBL_DESCR_5" $CRLFILE
        return 5
    fi

# crl of 0 size?
    if [ "x$CRL_FILE_SIZE" = "x0" ] ; then
	printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   $ERROR $ERRNO_6 "$PUBL_DESCR_6" $CRLFILE
        return 6
    fi

# now we can check the crl:s best before date is in the future with atleast HOURTHRESHOLD hours (defined in resources)
    TEMPDATE=`openssl crl -inform der -in $CRLFILE -nextupdate -noout`
    DATE=${TEMPDATE:11}
    WTIMELEFT=$(${SYSCHECK_HOME}/lib/cmp_dates.pl "$DATE" ${wcmdopts})
    ETIMELEFT=$(${SYSCHECK_HOME}/lib/cmp_dates.pl "$DATE" ${ecmdopts})

    SCRIPTINDEX=$(addOneToIndex $SCRIPTINDEX)
    
    if [ "$ETIMELEFT" -lt "$ETIME" ] ; then
	printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   $ERROR $ERRNO_7 "$PUBL_DESCR_7" $CRLFILE "timeleft: ${ETIMELEFT}${eunit} limit: ${ETIME}${eunit}"
	return 7

    elif [ "$WTIMELEFT" -lt "$WTIME" ] ; then
	printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   $WARN $ERRNO_9 "$PUBL_DESCR_9" $CRLFILE "timeleft: ${WTIMELEFT}${wunit} limit: ${WTIME}${wunit}"
	return 7

    else
	printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   $INFO $ERRNO_10 "$PUBL_DESCR_10" $CRLFILE "timeleft: ${WTIMELEFT}${wunit} limit: ${WTIME}${wunit}"
	printtoscreen "$INFO $ERRNO_10 $PUBL_DESCR_10 $CRLFILE timeleft: ${WTIMELEFT}${wunit} limit: ${WTIME}${wunit}"
	return 0
    fi
}


for (( i=0; i < ${#CRLCANAME[@]} ; i++ )){

    tempdir=$(mktemp -d)
    trap 'rm -rf "$tempdir"' EXIT

    CRLFILE=${tempdir}/${CRL_NAME[$i]}

    SCRIPTINDEX=$(addOneToIndex $SCRIPTINDEX)
    get ${CRLCANAME[$i]} "${CRLFILE}"

    SCRIPTINDEX=$(addOneToIndex $SCRIPTINDEX)
    echo "${CRLFILE} ${CRLWARNTIME[$i]} ${CRLERRORTIME[$i]}"
    checkcrl "${CRLFILE}" ${CRLWARNTIME[$i]} ${CRLERRORTIME[$i]}

    if [ $? -ne 0 ] ; then
	# check crl didn't pass the crl so we'll not publish this one and continue with the next
    	rm -rf $tempdir
	continue
    fi
	
    SCRIPTINDEX=$(addOneToIndex $SCRIPTINDEX) 
    if [ "x${REMOTE_HOST[$i]}" = "xlocalhost" ] ; then
	cp -f ${CRLFILE} "${CRLTO_DIR[$i]}/${CRL_NAME[$i]}"
	if [ $? -eq 0 ] ;then
	    printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   $INFO $ERRNO_1 "$PUBL_DESCR_1" ${CRLCANAME[$i]} 
	else
	    printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   $ERROR $ERRNO_3 "$PUBL_DESCR_3" ${CRL_NAME[$i]} "${CRLTO_DIR[$i]}/${CRL_NAME[$i]}"
	fi
	
    else
        SCRIPTINDEX=$(addOneToIndex $SCRIPTINDEX)
    	put ${REMOTE_HOST[$i]} ${CRLFILE} ${CRLTO_DIR[$i]} ${SSHKEY[$i]}  ${SSHUSER[$i]}
	
    fi

    rm -rf $tempdir
}


