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
SCRIPTNAME=firewall

# uniq ID of script (please use in the name of this file also for convinice for finding next availavle number)
SCRIPTID=09

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

IPTABLES_TMP_FILE="/tmp/iptables.out"

SCRIPTINDEX=$(addOneToIndex $SCRIPTINDEX)
$IPTABLES_BIN -L -n> $IPTABLES_TMP_FILE
if [ $? -ne 0 ] ; then
	printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   $ERROR ${ERRNO[1]} "${DESCR[1]}"
	exit
fi
FIREWALLFAILED="0"


SCRIPTINDEX=$(addOneToIndex $SCRIPTINDEX)
# rule that must exist
rule1check=`grep "$IPTABLES_RULE1" $IPTABLES_TMP_FILE`
if [ "x$rule1check" = "x" ] ; then
	FIREWALLFAILED=1
fi

# rule that must not exist
rule2check=`grep "$IPTABLES_RULE2" $IPTABLES_TMP_FILE`
if [ "x$rule2check" != "x" ] ; then
	FIREWALLFAILED=1
fi

if [ $FIREWALLFAILED -ne 0 ] ; then
	printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   $ERROR ${ERRNO[2]} "${DESCR[2]}"
else
	printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   $INFO ${ERRNO[3]} "${DESCR[3]}"
fi

rm $IPTABLES_TMP_FILE
