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

  LUNACM_STATUS=$(timeout 3 /bin/echo -e "par si\nexit"  | "${LUNACM}" )
  if [ $? != 0 ];then
      printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[3]} -d "${DESCR[3]}" -1 "HSM Not Installed"
      exit
  fi

  SCRIPTINDEX=$(addOneToIndex $SCRIPTINDEX)
  HSM_STATUS=$(echo "${LUNACM_STATUS}" |egrep "HSM Status" | head -1)
  STATUSOK=$(echo ${HSM_STATUS} |grep "OK" )

  if [ "x$STATUSOK" != "x" ] ; then
    printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $INFO -e ${ERRNO[1]} -d "${DESCR[1]}" -1 "${STATUSOK}"
  else
    printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[2]} -d "${DESCR[2]}" -1 "${STATUSOK}"
    exit
  fi

	SCRIPTINDEX=$(addOneToIndex $SCRIPTINDEX)
#  COMMAND=`timeout 3 echo -e "par si \n exit"| "${LUNACM}" |egrep "CONTAINER_ACTIVATED"`
  ACTIVATED=$(echo "${LUNACM_STATUS}" |egrep "CONTAINER_ACTIVATED" | sed 's/\s*//')
	if [ "x$ACTIVATED" != "x" ];then
    printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $INFO -e ${ERRNO[3]} -d "${DESCR[3]}" -1 "${ACTIVATED}"
  else
    printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[4]} -d "${DESCR[4]}" -1 "${ACTIVATED}"
  fi

  SCRIPTINDEX=$(addOneToIndex $SCRIPTINDEX)
  HSM_SERIAL=$(echo "${LUNACM_STATUS}" |egrep "HSM Serial Number" | sed 's/\s*HSM Serial Number ->\s*//')

  if [ "x$HSM_SERIAL" != "x" ] ; then
    printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $INFO -e ${ERRNO[5]} -d "${DESCR[5]}" -1 "${HSM_SERIAL}"
  else
    printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[6]} -d "${DESCR[6]}" -1 "${HSM_SERIAL}"
    exit
  fi

}

luna_hsm_check
