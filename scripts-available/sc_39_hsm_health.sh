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
SCRIPTNAME=hsm_health

# uniq ID of script (please use in the name of this file also for convinice for finding next availavle number)
SCRIPTID=39

# how many info/warn/error messages
NO_OF_ERR=6

initscript $SCRIPTID $NO_OF_ERR

default_script_getopt $*

# main part of script

luna_hsm_check () {

  LUNASTATUS=$(timeout 3 "${LUNADIAG}" "-s=${SLOT}" -o=0 -c=11)
  if [ $? != 0 ];then
      printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[3]} -d "${DESCR[3]}" -1 "HSM Not Installed"
      exit
  fi


  SCRIPTINDEX=$(addOneToIndex $SCRIPTINDEX)
  HSM_STATUS=$(echo ${LUNASTATUS} |egrep "HSM Status" )
  STATUSOK=$(echo ${HSM_STATUS} |grep "ok" )

  if [ "x$STATUSOK" != "x" ] ; then
    printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $INFO -e ${ERRNO[1]} -d "${DESCR[1]}" -1 "${STATUSOK}"
  else
    printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[2]} -d "${DESCR[2]}" -1 "${STATUSOK}"
    exit
  fi

	SCRIPTINDEX=$(addOneToIndex $SCRIPTINDEX)
#  COMMAND=`timeout 3 echo -e "par si \n exit"| "${LUNACM}" |egrep "CONTAINER_ACTIVATED"`
  ACTIVATED=$(echo ${LUNASTATUS} |egrep "CONTAINER_ACTIVATED" )
	if [ "x$ACTIVATED" != "x" ];then
    printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $INFO -e ${ERRNO[3]} -d "${DESCR[3]}" -1 "${ACTIVATED}"
  else
    printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[4]} -d "${DESCR[4]}" -1 "${ACTIVATED}"
  fi

  SCRIPTINDEX=$(addOneToIndex $SCRIPTINDEX)
  HSM_SERIAL=$(echo ${LUNASTATUS} |egrep "Token Serial Number" | sed 's/Token Serial Number ->//')

  if [ "x$HSM_SERIAL" != "x" ] ; then
    printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $INFO -e ${ERRNO[5]} -d "${DESCR[5]}" -1 "${HSM_SERIAL}"
  else
    printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[6]} -d "${DESCR[6]}" -1 "${HSM_SERIAL}"
    exit
  fi

}

luna_hsm_check
