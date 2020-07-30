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
        printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX}  $ERROR ${ERRNO[6]} "$PUBL_DESCR[6]" "$CRLNAME/$CRLFILE"
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
        printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX}  $INFO ${ERRNO[8]} "$PUBL_DESCR[8]" $CRLNAME $REMOTEHOST
    else
	printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX}  $ERROR ${ERRNO[2]} "$PUBL_DESCR[2]" $CRLNAME $REMOTEHOST
    fi
}


### check crl ###
checkcrl () {

    CRLFILE=$1
    if [ "x$CRLFILE" = "x" ] ; then
      printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[5]} -d "${DESCR[5]}" -1 "No CRL Configured"
      return
    fi

    # Limitminutes is now optional, if not configured the limits is crl WARN: validity/2 ERROR: validity/4 eg: CRL is valid to 12h, warn will be 6h and error 3h
    LIMITMINUTES=$2
    if [ "x$LIMITMINUTES" != "xdefault" ] ; then
      ARGWARNMIN="--warnminutes=$LIMITMINUTES"
    fi

    ERRMINUTES=$3
    if [ "x$ERRMINUTES" != "xdefault" ] ; then
      ARGERRMIN="--errorminutes=$ERRMINUTES"
    fi


# file not found where it should be
    if [ ! -f $CRLFILE ] ; then
	     printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX}  $ERROR ${ERRNO[4]} "$PUBL_DESCR[4]" "$CRLFILE"
       return 4
    fi

# stat return check
    CRL_FILE_SIZE=`stat -c"%s" $CRLFILE`
    if [ $? -ne 0 ] ; then
	     printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX}  $ERROR ${ERRNO[5]} "$PUBL_DESCR[5]" "$CRLFILE"
       return 5
    fi

# crl of 0 size?
    if [ "x$CRL_FILE_SIZE" = "x0" ] ; then
	     printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX}  $ERROR ${ERRNO[6]} "$PUBL_DESCR[6]" "$CRLFILE"
        return 6
    fi


      LASTUPDATE=$(openssl crl -inform der -in $outname -lastupdate -noout | sed 's/lastUpdate=//')
      if [ "x${LASTUPDATE}" = "x" ] ; then
        printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[1]} -d "${DESCR[1]}" -1 "$CRLFILE (Cant parse file,lastupdate)"

      fi

      NEXTUPDATE=$(openssl crl -inform der -in $outname -nextupdate -noout | sed 's/nextUpdate=//')
      if [ "x${NEXTUPDATE}" = "x" ] ; then
        printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[1]} -d "${DESCR[1]}" -1 "$CRLFILE (Cant parse file,nextupdate)"

      fi

      CRLMESSAGE=$(${SYSCHECK_HOME}/lib/cmp_dates.py "$LASTUPDATE" "$NEXTUPDATE" ${ARGWARNMIN} ${ARGERRMIN} )
      CRLCHECK=$?
      #th these values  0 -> ok,  1 -> warn ,  2 -> error,  3 -> expired.')

      if [ "x$CRLCHECK" = "x" ] ; then
        printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[1]} -d "${DESCR[1]}" -1 "$CRLFILE (Cant parse file)"
        return 7

      elif [ $CRLCHECK -eq 3 ] ; then
        printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[6]} -d "${DESCR[6]}" -1 "$CRLFILE: ${CRLMESSAGE}"
        return 7

      elif [ $CRLCHECK -eq 2 ] ; then
        printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[7]} -d "${DESCR[7]}" -1 "$CRLFILE: ${CRLMESSAGE}"
        return 7

      elif [ $CRLCHECK -eq 1 ] ; then
        printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $WARN -e ${ERRNO[8]} -d "${DESCR[8]}" -1 "$CRLFILE: ${CRLMESSAGE}"
        return 7

      elif [ $CRLCHECK -eq 0 ] ; then
        printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $INFO -e ${ERRNO[2]} -d "${DESCR[2]}" -1 "$CRLFILE: ${CRLMESSAGE}"
        return 0
      else
        printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[1]} -d "${DESCR[1]}" -1 "$CRLFILE: problem calculating validity"
        return 8

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
	    printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX}  $INFO ${ERRNO[1]} "$PUBL_DESCR[1]" ${CRLCANAME[$i]}
	else
	    printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX}  $ERROR ${ERRNO[3]} "$PUBL_DESCR[3]" ${CRL_NAME[$i]} "${CRLTO_DIR[$i]}/${CRL_NAME[$i]}"
	fi

    else
        SCRIPTINDEX=$(addOneToIndex $SCRIPTINDEX)
    	put ${REMOTE_HOST[$i]} ${CRLFILE} ${CRLTO_DIR[$i]} ${SSHKEY[$i]}  ${SSHUSER[$i]}

    fi

    rm -rf $tempdir
}
