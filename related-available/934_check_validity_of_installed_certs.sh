#!/bin/bash

#Scripts that creates replication privilegdes for the slave db to the master.

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




## Import common definitions ##
source $SYSCHECK_HOME/config/syscheck-scripts.conf

# uniq ID of script (please use in the name of this file also for convinice for finding next availavle number)
SCRIPTID=934

# Index is used to uniquely identify one test done by the script (a harddrive, crl or cert)
SCRIPTINDEX=00

getlangfiles $SCRIPTID || exit 1;
getconfig $SCRIPTID || exit 1;

ERRNO_1="${SCRIPTID}1"
ERRNO_2="${SCRIPTID}2"
ERRNO_3="${SCRIPTID}3"

schelp () {
        echo "$HELP"
        echo "$ERRNO_1/$DESCR_1 - $HELP_1"
        echo "$ERRNO_2/$DESCR_2 - $HELP_2"
        echo "${SCREEN_HELP}"
        exit
}


PRINTTOSCREEN=1

if [ "x$1" = "x-h" -o "x$1" = "x--help" ] ; then
        schelp
elif [ "x$1" = "x-s" -o  "x$1" = "x--screen" -o \
    "x$2" = "x-s" -o  "x$2" = "x--screen"   ] ; then
        PRINTTOSCREEN=1
fi


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
	    printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX} $ERROR $ERRNO_2 "$DESCR_2" "$keystoreFile" $timeDiffDays "$subject"
	elif [ $timeDiffDays -le $ERRORDAYS ] ; then
	    printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX} $ERROR $ERRNO_3 "$DESCR_3" "$keystoreFile" $timeDiffDays "$subject"
	else 
	    printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX} $INFO $ERRNO_1 "$DESCR_1" "$keystoreFile" $timeDiffDays "$subject"
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

