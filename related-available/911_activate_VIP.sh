#!/bin/bash

SYSCHECK_HOME="${SYSCHECK_HOME:-/opt/syscheck}" # use default if  unset
if [ ! -f ${SYSCHECK_HOME}/syscheck.sh ] ; then
  echo "Can't find $SYSCHECK_HOME/syscheck.sh"
  exit
fi

if [ ! -f ${SYSCHECK_HOME}/syscheck.sh ] ; then echo "Can't find $SYSCHECK_HOME/syscheck.sh" ;exit ; fi

## Import common definitions ##
source $SYSCHECK_HOME/config/related-scripts.conf

# script name, used when integrating with nagios/icinga
SCRIPTNAME=activate_vip

# uniq ID of script (please use in the name of this file also for convinice for finding next availavle number)
SCRIPTID=911


# how many info/warn/error messages
NO_OF_ERR=4
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

IP_GATEWAY=`$ROUTE -n | awk '/0.0.0.0/'| awk '{print $2}' |awk '!/0.0.0.0/'`

SCRIPTINDEX=$(addOneToIndex $SCRIPTINDEX)
res=$($IFCONFIG ${IF_VIRTUAL} 2>&1 | grep 'inet addr' | grep  ${HOSTNAME_VIRTUAL} )
if [ "x$res" != "x" ] ; then
	printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $INFO -e ${ERRNO[3]} -d "${DESCR[3]}" -1 "$res"
	exit
fi

SCRIPTINDEX=$(addOneToIndex $SCRIPTINDEX)
res=$(ping -c4 ${HOSTNAME_VIRTUAL} )
if [ $? -eq 0 ] ; then
	printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[4]} -d "${DESCR[4]}" -1 "$res"
	exit
fi

SCRIPTINDEX=$(addOneToIndex $SCRIPTINDEX)
res=($IFCONFIG ${IF_VIRTUAL} inet ${HOSTNAME_VIRTUAL} netmask ${NETMASK_VIRTUAL} up)
if [ $? -ne 0 ] ; then
	printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[2]} -d "${DESCR[2]}" -1 "$res"
	exit
fi

SCRIPTINDEX=$(addOneToIndex $SCRIPTINDEX)
date > ${SYSCHECK_HOME}/var/this_node_has_the_vip
printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $INFO -e ${ERRNO[1]} -d "${DESCR[1]}"

SCRIPTINDEX=$(addOneToIndex $SCRIPTINDEX)
res=$(arping -f -q -U ${IP_GATEWAY} -I ${IF_VIRTUAL} -s ${HOSTNAME_VIRTUAL} )
if [ $? -ne 0 ] ; then
    	printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX}  $WARN ${ERRNO[6]} -d "${DESCR[6]}" -1 "$res"
else
	printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $INFO -e ${ERRNO[5]} -d "${DESCR[5]}"
fi
