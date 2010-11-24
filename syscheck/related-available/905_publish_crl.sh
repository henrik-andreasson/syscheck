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
	SYSCHECK_HOME="/usr/local/syscheck"
    fi
fi

if [ ! -f ${SYSCHECK_HOME}/syscheck.sh ] ; then echo "$0: Can't find syscheck.sh in SYSCHECK_HOME ($SYSCHECK_HOME)" ;exit ; fi

# source env vars from system that dont get included when running from cron



# Import common resources
. $SYSCHECK_HOME/config/related-scripts.conf


## local definitions ##
SCRIPTID=905
getlangfiles $SCRIPTID
getconfig $SCRIPTID

ERRNO_1=${SCRIPTID}1
ERRNO_2=${SCRIPTID}2
ERRNO_3=${SCRIPTID}3
ERRNO_4=${SCRIPTID}4
ERRNO_5=${SCRIPTID}5
ERRNO_6=${SCRIPTID}6
ERRNO_7=${SCRIPTID}7
ERRNO_8=${SCRIPTID}8



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
    ${EJBCA_HOME}/bin/ejbca.sh ca getcrl $CRLNAME "$CRLFILE"
    if [ $? != 0 -o  ! -r $CRLFILE  ] ; then
        printlogmess $ERROR $ERRNO_6 "$PUBL_DESCR_6" "$CRLNAME/$CRLFILE"
    fi

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
        printlogmess $INFO $ERRNO_8 "$PUBL_DESCR_8" $CRLNAME $CRLHOST 
    else
	printlogmess $ERROR $ERRNO_2 "$PUBL_DESCR_2" $CRLNAME $CRLHOST
    fi
}


### check crl ###
checkcrl () {

    CRLFILE=$1


# file not found where it should be
    if [ ! -f $CRLFILE ] ; then
	printlogmess $ERROR $ERRNO_4 "$PUBL_DESCR_4" $CRLFILE
        return 4
    fi

# stat return check
    CRL_FILE_SIZE=`stat -c"%s" $CRLFILE`
    if [ $? -ne 0 ] ; then
	printlogmess $ERROR $ERRNO_5 "$PUBL_DESCR_5" $CRLFILE
        return 5
    fi

# crl of 0 size?
    if [ "x$CRL_FILE_SIZE" = "x0" ] ; then
	printlogmess $ERROR $ERRNO_6 "$PUBL_DESCR_6" $CRLFILE
        return 6
    fi

# now we can check the crl:s best before date is in the future with atleast HOURTHRESHOLD hours (defined in resources)
    TEMPDATE=`openssl crl -inform der -in $CRLFILE -nextupdate -noout`
    DATE=${TEMPDATE:11}
    HOURSLEFT=`${SYSCHECK_HOME}/lib/cmp_dates.pl "$DATE"`
    
    if [ "$HOURSLEFT" -lt "$HOURTHRESHOLD" ] ; then
	printlogmess $ERROR $ERRNO_7 "$PUBL_DESCR_7" $CRLFILE "hoursleft: ${HOURSLEFT} limit: ${HOURTHRESHOLD}"
	return 7
    else
#	printlogmess $INFO $ERRNO_1 "$PUBL_DESCR_1" $CRLFILE
	return 0
    fi
}


for (( i=0; i < ${#CRLCANAME[@]} ; i++ )){

    tempdir=$(mktemp -d)
    trap 'rm -rf "$tempdir"' EXIT

    CRLFILE=${tempdir}/${CRL_NAME[$i]}

    get ${CRLCANAME[$i]} "${CRLFILE}"
    checkcrl "${CRLFILE}"
    if [ $? -ne 0 ] ; then
	# check crl didn't pass the crl so we'll not publish this one and continue with the next
    	rm -rf $tempdir
	continue
    fi
	
    if [ "x${REMOTE_HOST[$i]}" = "xlocalhost" ] ; then
	cp -f ${CRLFILE} "${CRLTO_DIR[$i]}/${CRL_NAME[$i]}"
	if [ $? -eq 0 ] ;then
	    printlogmess $INFO $ERRNO_1 "$PUBL_DESCR_1" ${CRLCANAME[$i]}
	else
	    printlogmess $ERROR $ERRNO_3 "$PUBL_DESCR_3" ${CRL_NAME[$i]} "${CRLTO_DIR[$i]}/${CRL_NAME[$i]}"
	fi
	
    else
    	put ${REMOTE_HOST[$i]} ${CRLFILE} ${CRLTO_DIR[$i]} ${SSHKEY[$i]}  ${SSHUSER[$i]}
	
    fi

    rm -rf $tempdir
}


