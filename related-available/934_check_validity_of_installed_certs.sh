#!/bin/bash

SYSCHECK_HOME="${SYSCHECK_HOME:-/opt/syscheck}" # use default if  unset
if [ ! -f ${SYSCHECK_HOME}/syscheck.sh ] ; then
  echo "Can't find $SYSCHECK_HOME/syscheck.sh"
  exit
fi

if [ ! -f ${SYSCHECK_HOME}/syscheck.sh ] ; then echo "Can't find $SYSCHECK_HOME/syscheck.sh" ;exit ; fi

## Import common definitions ##
source $SYSCHECK_HOME/config/syscheck-scripts.conf

# script name, used when integrating with nagios/icinga
SCRIPTNAME=cert_validity

# uniq ID of script (please use in the name of this file also for convinice for finding next availavle number)
SCRIPTID=934

# how many info/warn/error messages
NO_OF_ERR=3
initscript $SCRIPTID $NO_OF_ERR || exit 1;

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

# reads out the cert from the keystore, then call checkDER -> checkPEM
checkJKS() {
    keystoreFile=$1
    alias=$2
    certFile=$(tempfile -p "syscheck934") || exit
    trap "rm -f -- '$certFile'" EXIT

    if [ "x$alias" = "x" ] ; then
        # we'll try to guess the alias
        alias=$(echo  "" | keytool -list -keystore  "$keystoreFile" -rfc 2>/dev/null | grep "Alias name"   | sed 's/Alias name: //')
    fi
    if [ "x$alias" = "x" ] ; then
        alias="mykey"
    fi

    # a little hacky but we do not want to enter the password
    echo  "" | keytool -export  -keystore  "$keystoreFile"  -file "$certFile"  -alias "$alias" 2>/dev/null
    # TODO check error

    checkDER $certFile

}

checkPEM() {
    keystoreFile=$1
    # TODO also send org file that was input file

    if [ "x$keystoreFile" == "x" ] ; then
            echo "arg1, needs to be a filename  ($keystoreFile)"
            exit
    fi
    #notAfter=May 22 12:41:47 2020 GMT
    #subject=CN = admin.lcsim.certificateservices.se, serialNumber = 2018, O = Logica SE IM Certificate Service

    nowDate=$(TZ="GMT" date +"%b %d %H:%m:%S %Y %Z")
    notAfter=$(openssl x509 -in $keystoreFile -enddate -noout| sed 's/notAfter=//')
    if [ $? -ne 0 ] ; then echo asdf ; exit ; fi
    # TODO check error


    subject=$(openssl x509 -in $keystoreFile -subject -noout)
    # TODO check error

    timeDiffMin=$($SYSCHECK_HOME/lib/cmp_dates.py "$nowDate"  "$notAfter"  --minutes )
    # TODO check error

    let timeDiffHours="$timeDiffMin / 60"
    let timeDiffDays="$timeDiffMin / 60 / 24"

    if [ $timeDiffDays -le $WARNINGDAYS ] ; then
	    printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX} $ERROR ${ERRNO[2]} "${DESCR[2]}" "$keystoreFile" $timeDiffDays "$subject"
	elif [ $timeDiffDays -le $ERRORDAYS ] ; then
	    printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX} $ERROR ${ERRNO[3]} "${DESCR[3]}" "$keystoreFile" $timeDiffDays "$subject"
	else
	    printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX} $INFO ${ERRNO[1]} "${DESCR[1]}" "$keystoreFile" $timeDiffDays "$subject"
	fi

}

# converts to pem then calls checkPEM
checkDER() {
    keystoreFile=$1

    if [ "x$keystoreFile" == "x" ] ; then
            echo "arg1, needs to be a filename  ($keystoreFile)"
            exit
    fi

    certFile=$(tempfile -p "syscheck934") || exit
    trap "rm -f -- '$certFile'" EXIT

    openssl x509 -in $keystoreFile -out $certFile -inform der -outform pem
    # TODO check error

    checkPEM $certFile

}


checkP12() {
    keystoreFile=$1
    keystorePass=$2

    certFile=$(tempfile -p "syscheck934") || exit
    trap "rm -f -- '$certFile'" EXIT

    openssl pkcs12 -info -in $keystoreFile -clcerts -nokeys -out $certFile -passin "pass:$keystorePass" 2>/dev/null
    # TODO check error

    checkPEM $certFile
}


for (( j=0; j < ${#CERT_TYPE[@]} ; j++ )){

	SCRIPTINDEX=$(addOneToIndex $SCRIPTINDEX)


    if [ ${CERT_TYPE[$j]} = "PEM" ] ; then
        checkPEM ${CERT_FILE[$j]}
    elif [ ${CERT_TYPE[$j]} = "DER" ] ; then
        checkDER ${CERT_FILE[$j]}

    elif [ ${CERT_TYPE[$j]} = "P12" ] ; then
        checkP12 "${CERT_FILE[$j]}" "${CERT_PASS[$j]}"

    elif [ ${CERT_TYPE[$j]} = "JKS" ] ; then
        checkJKS ${CERT_FILE[$j]}

#    elif [ ${CERT_TYPE[$j]} = "P11" ] ; then
#        checkP11 ${CERT_FILE[$j]}
# TODO support P11

    else
        echo "TYPE not supported"
    fi

}
