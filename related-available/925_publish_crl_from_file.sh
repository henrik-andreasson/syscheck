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
SCRIPTNAME=publish_crl_from_file

# uniq ID of script (please use in the name of this file also for convinice for finding next availavle number)
SCRIPTID=925

# how many info/warn/error messages
NO_OF_ERR=3
initscript $SCRIPTID $NO_OF_ERR


# get command line arguments
INPUTARGS=`/usr/bin/getopt --options "hsv" --long "help,screen,verbose,crlfile:" -- "$@"`
if [ $? != 0 ] ; then schelp ; fi
#echo "TEMP: >$TEMP<"
eval set -- "$INPUTARGS"

while true; do
  case "$1" in
    -c|--crlfile ) CRLFILE=$2; shift 2;;
    -s|--screen  ) PRINTTOSCREEN=1; shift;;
    -v|--verbose ) PRINTVERBOSESCREEN=1 ; shift;;
    -h|--help )   schelp;exit;shift;;
    --) break;;
  esac
done


# main part of script


if [ "x${CRLFILE}" = "x" ] ; then
    printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[2]} -d "${DESCR[2]}"
    exit
fi


if [ ! -r ${CRLFILE} ] ; then
    printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[3]} -d "${DESCR[3]}" -1 ${CRLFILE}
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
                printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e "${ERRNO[4]}" -d "${DESCR[4]}" -1 "$CRLHOST" -2 "$CRLFILE"
	else
                printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $INFO -e "${ERRNO[1]}" -d "${DESCR[1]}" -1 "$CRLHOST" -2 "$CRLFILE"
	fi
}


for (( i=0; i < ${#VERIFY_HOST[@]} ; i++ )){

    		put ${VERIFY_HOST[$i]} "${CRLFILE}" ${CRLTO_DIR[$i]} ${SSHKEY[$i]}  ${SSHUSER[$i]}

}
