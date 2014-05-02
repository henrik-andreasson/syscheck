#!/bin/bash

# The script fetches a crl from the ca and scp the crl to a webserver.
# Change $HTTPSERVER, $SSHUSER and $SSHSERVER_DIR. Define the crl's and the servers in the end.
# Usage:
# get example.crl # This gets the crl from the CA server.
# put 192.168.10.10 # This sends the crl to the webserver.

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
SCRIPTID=925
getlangfiles $SCRIPTID
getconfig $SCRIPTID

ERRNO_1=${SCRIPTID}1
ERRNO_2=${SCRIPTID}2
ERRNO_3=${SCRIPTID}3


if [ "x$1" = "x--help" -o "x$1" = "x-h" ] ; then
    /bin/echo -e  "$HELP"
    echo
    echo "$ERRNO_1/$DESCR_1 - $HELP_1"
    echo "$ERRNO_2/$DESCR_2 - $HELP_2"
    echo "$ERRNO_3/$DESCR_3 - $HELP_3"
    echo "$0 <-s|--screen>"
    exit
elif [ "x$1" = "x-s" -o  "x$1" = "x--screen"  ] ; then
    PRINTTOSCREEN=1
fi 


TEMP=`/usr/bin/getopt --options "hsc:" --long "help,screen,crlfile:" -- "$@"`
if [ $? != 0 ] ; then help ; fi
eval set -- "$TEMP"

while true; do
  case "$1" in
    -c|--crlfile ) CRLFILE=$2; shift 2;;
    -s|--screen ) PRINTTOSCREEN=1; shift;;
    -b|--batch )  BATCH=1; shift;;
    -h|--help )   schelp;shift;;
    --) break ;;
  esac
done


if [ "x${CRLFILE}" = "x" ] ; then
    printlogmess $ERROR $ERRNO_2 "$DESCR_2"
    exit
fi


if [ ! -r ${CRLFILE} ] ; then
    printlogmess $ERROR $ERRNO_3 "$DESCR_3" ${CRLFILE}
    exit
fi


put () {

	CRLHOST=$1
        CRLFILE=$2
	SSHSERVER_DIR=$3
	SSHKEY=$4
	SSHUSER=$5

	$SYSCHECK_HOME/related-enabled/906_ssh-copy-to-remote-machine.sh -s $CRLFILE $CRLHOST $SSHSERVER_DIR $SSHUSER $SSHKEY
	if [ $? != 0 ] ; then
                printlogmess $ERROR $ERRNO_4 "$DESCR_4" $CRLHOST $CRLFILE
	else
                printlogmess $INFO $ERRNO_1 "$DESCR_1" $CRLHOST $CRLFILE
	fi
}


for (( i=0; i < ${#VERIFY_HOST[@]} ; i++ )){

    		put ${VERIFY_HOST[$i]} "${CRLFILE}" ${CRLTO_DIR[$i]} ${SSHKEY[$i]}  ${SSHUSER[$i]} 

}



