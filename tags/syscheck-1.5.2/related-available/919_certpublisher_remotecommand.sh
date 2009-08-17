#!/bin/sh


# Set default home if not already set.
SYSCHECK_HOME=${SYSCHECK_HOME:-"/usr/local/syscheck"}


## Import common definitions ##
. $SYSCHECK_HOME/resources.sh

# uniq ID of script (please use in the name of this file also for convinice for finding next availavle number)
SCRIPTID=919

getlangfiles $SCRIPTID || exit 1;
getconfig $SCRIPTID || exit 1;

ERRNO_1="${SCRIPTID}1"
ERRNO_2="${SCRIPTID}2"
ERRNO_3="${SCRIPTID}3"

PRINTTOSCREEN=

help () {
	echo "$REMCMD_HELP"
	echo "$0 -c|--cert <certfile-in-der-format> [-s|--screen] [-h|--help]"
	echo "$ERRNO_1/$REMCMD_DESCR_1 - $REMCMD_HELP_1"
	echo "$ERRNO_2/$REMCMD_DESCR_2 - $REMCMD_HELP_2"
	echo "$ERRNO_3/$REMCMD_DESCR_3 - $REMCMD_HELP_3"
	echo "${SCREEN_HELP}"
	exit
}

TEMP=`/usr/bin/getopt --options ":c:s" --long "help,screen,cert:" -- "$@"`
if [ $? != 0 ] ; then help ; fi
eval set -- "$TEMP"

while true; do
  case "$1" in
    -c|--cert )   CERTFILE=$2; shift 2;;
    -s|--screen ) PRINTTOSCREEN=1; shift;;
    -h|--help )   help;shift;;
    --) break ;;
    * ) 
	printlogmess $ERROR $ERRNO_3 "$REMCMD_DESCR_3"
	printtoscreen $ERROR $ERRNO_3 "$REMCMD_DESCR_3"
	exit 1
      ;;
  esac
done

if [ ! -r "$CERTFILE" ] ; then 
	printlogmess $ERROR $ERRNO_3 "$REMCMD_DESCR_3"  
	printtoscreen $ERROR $ERRNO_3 "$REMCMD_DESCR_3"
	exit
fi


CERTSERIAL=`openssl x509 -inform der -in ${CERTFILE} -serial -noout | sed 's/serial=//'`
if [ $? -ne 0 ] ; then 
    printlogmess $ERROR $ERRNO_3 "$REMCMD_DESCR_3" "$?"
fi

CERTDN=`openssl x509 -inform der -in ${CERTFILE} -subject -noout | perl -ane 's/\//_/gio,s/subject=//,s/=/-/gio,s/\ /_/gio,print'`
if [ $? -ne 0 ] ; then 
    printlogmess $ERROR $ERRNO_3 "$REMCMD_DESCR_3" "$?" 
fi

CERTUID=`openssl x509 -inform der -in ${CERTFILE} -subject -noout | perl -ane 'm/uid=(.*?)\//gio, print "$1"'`
if [ $? -ne 0 ] ; then 
    printlogmess $ERROR $ERRNO_4 "$REMCMD_DESCR_3" "$?" 
fi

CERTCN=`openssl x509 -inform der -in ${CERTFILE} -subject -noout | perl -ane 'm/cn=(.*?)\//gio, print "$1"'`
if [ $? -ne 0 ] ; then 
    printlogmess $ERROR $ERRNO_3 "$REMCMD_DESCR_3" "$?" 
fi

CERTSN=`openssl x509 -inform der -in ${CERTFILE} -subject -noout | perl -ane 'm/serialnumber=(.*?)\//gio, print "$1"'`
if [ $? -ne 0 ] ; then 
    printlogmess $ERROR $ERRNO_3 "$REMCMD_DESCR_3" "$?" 
fi

CERTSTRING=`openssl x509 -inform der -in ${CERTFILE}| perl -ane 's/\n//gio,print'`
if [ $? -ne 0 ] ; then 
    printlogmess $ERROR $ERRNO_3 "$REMCMD_DESCR_3" "$?" 
fi

for (( j=0; j < ${#REMOTE_HOST[@]} ; j++ )){

    if [ ${REMOTE_ARG[$j]} = "SN" ] ; then
	    RemoteCmd="${REMOTE_CMD[$j]} ${CERTSN}"

    elif [ ${REMOTE_ARG[$j]} = "UID" ] ; then
	    RemoteCmd="${REMOTE_CMD[$j]} ${CERTUID}"

    elif [ ${REMOTE_ARG[$j]} = "CN" ] ; then
	    RemoteCmd="${REMOTE_CMD[$j]} ${CERTCN}"

    elif [ ${REMOTE_ARG[$j]} = "CERTSERIAL" ] ; then
	    RemoteCmd="${REMOTE_CMD[$j]} ${CERTSERIAL}"

    elif [ ${REMOTE_ARG[$j]} = "DN" ] ; then
	    RemoteCmd="${REMOTE_CMD[$j]} ${CERTDN}"

    elif [ ${REMOTE_ARG[$j]} = "CERTSTRING" ] ; then
	    RemoteCmd="${REMOTE_CMD[$j]} ${CERTSTRING}"

    else
	    RemoteCmd="${REMOTE_CMD[$j]}"
    fi

    printtoscreen "remotecommand arg: ${REMOTE_ARG[$j]} host:${REMOTE_HOST[$j]} cmd:${RemoteCmd} remotreuser:${REMOTE_USER[$j]} sshkey:${SSHKEY[$j]}"
    ${SYSCHECK_HOME}/related-enabled/915_remote_command_via_ssh.sh ${REMOTE_HOST[$j]} ${RemoteCmd} ${REMOTE_USER[$j]} ${SSHKEY[$j]}
}
