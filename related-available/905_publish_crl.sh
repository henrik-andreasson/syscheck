#!/bin/bash

SYSCHECK_HOME="${SYSCHECK_HOME:-/opt/syscheck}" # use default if  unset
if [ ! -f ${SYSCHECK_HOME}/syscheck.sh ] ; then
  echo "Can't find $SYSCHECK_HOME/syscheck.sh"
  exit
fi

if [ ! -f ${SYSCHECK_HOME}/syscheck.sh ] ; then echo "Can't find $SYSCHECK_HOME/syscheck.sh" ;exit ; fi

# Import common resources
source $SYSCHECK_HOME/config/related-scripts.conf

# script name, used when integrating with nagios/icinga
SCRIPTNAME=publish_crl

# uniq ID of script (please use in the name of this file also for convinice for finding next availavle number)
SCRIPTID=905

# how many info/warn/error messages
NO_OF_ERR=3
initscript $SCRIPTID $NO_OF_ERR


# get command line arguments
INPUTARGS=`/usr/bin/getopt --options "hsv" --long "help,screen,verbose" -- "$@"`
if [ $? != 0 ] ; then schelp ; fi
#echo "TEMP: >$TEMP<"
eval set -- "$INPUTARGS"

while true; do
  case "$1" in
    -s|--screen  ) PRINTTOSCREEN=1; shift;;
    -v|--verbose ) PRINTVERBOSESCREEN=1 ; shift;;
    -h|--help )   schelp;exit;shift;;
    --) break;;
  esac
done


# main part of script

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
        printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   $ERROR ${ERRNO[6]} "$PUBL_DESCR[6]" "$CRLNAME/$CRLFILE"
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
        printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   $INFO ${ERRNO[8]} "$PUBL_DESCR[8]" $CRLNAME $REMOTEHOST
    else
	printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   $ERROR ${ERRNO[2]} "$PUBL_DESCR[2]" $CRLNAME $REMOTEHOST
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
	printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   $ERROR ${ERRNO[4]} "$PUBL_DESCR[4]" $CRLFILE
        return 4
    fi

# stat return check
    CRL_FILE_SIZE=`stat -c"%s" $CRLFILE`
    if [ $? -ne 0 ] ; then
	printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   $ERROR ${ERRNO[5]} "$PUBL_DESCR[5]" $CRLFILE
        return 5
    fi

# crl of 0 size?
    if [ "x$CRL_FILE_SIZE" = "x0" ] ; then
	printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   $ERROR ${ERRNO[6]} "$PUBL_DESCR[6]" $CRLFILE
        return 6
    fi

# now we can check the crl:s best before date is in the future with atleast HOURTHRESHOLD hours (defined in resources)
    TEMPDATE=`openssl crl -inform der -in $CRLFILE -nextupdate -noout`
    DATE=${TEMPDATE:11}
    WTIMELEFT=$(${SYSCHECK_HOME}/lib/cmp_dates.pl "$DATE" ${wcmdopts})
    ETIMELEFT=$(${SYSCHECK_HOME}/lib/cmp_dates.pl "$DATE" ${ecmdopts})

    SCRIPTINDEX=$(addOneToIndex $SCRIPTINDEX)

    if [ "$ETIMELEFT" -lt "$ETIME" ] ; then
	printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   $ERROR ${ERRNO[7]} "$PUBL_DESCR[7]" $CRLFILE "timeleft: ${ETIMELEFT}${eunit} limit: ${ETIME}${eunit}"
	return 7

    elif [ "$WTIMELEFT" -lt "$WTIME" ] ; then
	printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   $WARN ${ERRNO[9]} "$PUBL_DESCR[9]" $CRLFILE "timeleft: ${WTIMELEFT}${wunit} limit: ${WTIME}${wunit}"
	return 7

    else
	printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   $INFO ${ERRNO[10]} "$PUBL_DESCR[10]" $CRLFILE "timeleft: ${WTIMELEFT}${wunit} limit: ${WTIME}${wunit}"
	printtoscreen "$INFO ${ERRNO[10]} $PUBL_DESCR[10] $CRLFILE timeleft: ${WTIMELEFT}${wunit} limit: ${WTIME}${wunit}"
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
	    printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   $INFO ${ERRNO[1]} "$PUBL_DESCR[1]" ${CRLCANAME[$i]}
	else
	    printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   $ERROR ${ERRNO[3]} "$PUBL_DESCR[3]" ${CRL_NAME[$i]} "${CRLTO_DIR[$i]}/${CRL_NAME[$i]}"
	fi

    else
        SCRIPTINDEX=$(addOneToIndex $SCRIPTINDEX)
    	put ${REMOTE_HOST[$i]} ${CRLFILE} ${CRLTO_DIR[$i]} ${SSHKEY[$i]}  ${SSHUSER[$i]}

    fi

    rm -rf $tempdir
}
