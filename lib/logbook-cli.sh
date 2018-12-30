#!/bin/bash

SYSCHECK_HOME="${SYSCHECK_HOME:-/opt/syscheck}" # use default if  unset
if [ ! -f ${SYSCHECK_HOME}/syscheck.sh ] ; then
  echo "Can't find $SYSCHECK_HOME/syscheck.sh"
  exit
fi

if [ ! -f ${SYSCHECK_HOME}/syscheck.sh ] ; then echo "Can't find $SYSCHECK_HOME/syscheck.sh" ;exit ; fi

## Import common definitions ##
source $SYSCHECK_HOME/config/common.conf

# source libsycheck 
source ${SYSCHECK_HOME}/lib/libsyscheck.sh

# use the printlog function
source $SYSCHECK_HOME/lib/printlogmess.sh




logbookmess "$1" "$2" "$3" "$4" "$5" "$6" "$7" "$8" "$9"
