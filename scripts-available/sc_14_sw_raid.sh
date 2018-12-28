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
SCRIPTNAME=swraid

# uniq ID of script (please use in the name of this file also for convinice for finding next availavle number)
SCRIPTID=14

# how many info/warn/error messages
NO_OF_ERR=3
initscript $SCRIPTID $NO_OF_ERR

# get command line arguments
INPUTARGS=`/usr/bin/getopt --options "hsvc" --long "help,screen,verbose,cert" -- "$@"`
if [ $? != 0 ] ; then schelp ; fi
#echo "TEMP: >$TEMP<"
eval set -- "$INPUTARGS"

while true; do
  case "$1" in
    -s|--screen  ) PRINTTOSCREEN=1; shift;;
    -v|--verbose ) PRINTVERBOSESCREEN=1 ; shift;;
    -c|--cert )   CERTFILE=$2; shift 2;;
    -h|--help )   schelp;exit;shift;;
    --) break;;
  esac
done

# main part of script

swraidcheck () {
	ARRAY=$1
        DISC=$2
	SCRIPTINDEX=$3

        COMMAND=`mdadm --detail $ARRAY 2>&1| grep $DISC `

        STATUSactive=`echo $COMMAND | grep 'active sync' `
        STATUSfault=`echo $COMMAND | grep 'fault' `
        if [ "x$STATUSactive" != "x" ] ; then
		# ok
                printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   $INFO ${ERRNO[1]} "${DESCR[1]}" "$ARRAY / $DISC"
        elif [ "x$STATUSfault" != "x" ] ; then
		# fault
                printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   $ERROR ${ERRNO[2]} "${DESCR[2]}" "$ARRAY / $DISC ($COMMAND)"
        else
		# failed some other way
                printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   $ERROR ${ERRNO[3]} "${DESCR[3]}" "$ARRAY / $DISC ($COMMAND)"

        fi
}

for (( i = 0 ;  i < ${#MDDEV[@]} ; i++ )) ; do
    SCRIPTINDEX=$(addOneToIndex $SCRIPTINDEX)
    swraidcheck ${#MDDEV[$i]} ${#DDDEV[$i]} $SCRIPTINDEX
done
