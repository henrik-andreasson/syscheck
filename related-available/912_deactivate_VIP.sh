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
SCRIPTNAME=deactivate_vip

# uniq ID of script (please use in the name of this file also for convinice for finding next availavle number)
SCRIPTID=912


# how many info/warn/error messages
NO_OF_ERR=3
initscript $SCRIPTID $NO_OF_ERR


ERRNO[1]="${SCRIPTID}1"
ERRNO[2]="${SCRIPTID}2"
ERRNO[3]="${SCRIPTID}3"


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

CHECK_VIP=`$IFCONFIG ${IF_VIRTUAL} | grep 'inet addr' | grep  ${HOSTNAME_VIRTUAL}`
if [ "x${CHECK_VIP}" = "x" ] ; then
        printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $INFO -e ${ERRNO[3]} -d "$DESCR[3]"
        exit
fi


$IFCONFIG ${IF_VIRTUAL} down

if [ $? -eq 0 ] ; then
    printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $INFO -e ${ERRNO[1]} -d "$DESCR[1]" -1 "$?"
    rm ${SYSCHECK_HOME}/var/this_node_has_the_vip

else
    printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[2]} -d "$DESCR[2]" -1 "$?"
fi

#ifconfig $IF_VIRTUAL del $HOSTNAME_VIRTUAL
