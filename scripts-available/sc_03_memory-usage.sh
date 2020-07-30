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
SCRIPTNAME=memoryusage

# uniq ID of script (please use in the name of this file also for convinice for finding next availavle number)
SCRIPTID=03

# how many info/warn/error messages
NO_OF_ERR=4
initscript $SCRIPTID $NO_OF_ERR

default_script_getopt $*

# main part of script


checkmem(){
    INMEMORYLIMIT=$1
    INSWAPLIMIT=$2

    MEMORY=$(free | grep -v total | grep -v buffers | grep -v Swap | cut -f2 -d: | sed -E 's/[[:space:]]+/;/gi')
    SWAP=$(free | grep -v total | grep -v buffers | grep -v Mem | cut -f2 -d: | sed -E 's/[[:space:]]+/;/gi')

    TOTALMEMORY=`echo $MEMORY | cut -f2 -d\;`
    USEDMEMORY=`echo $MEMORY | cut -f3 -d\;`
    FREEMEMORY=`echo $MEMORY | cut -f4 -d\;`
    CACHEDMEMORY=`echo $MEMORY | cut -f6 -d\;`
    BUFFEREDMEMORY=`echo $MEMORY | cut -f7 -d\;`

    TOTALSWAP=`echo $SWAP | cut -f2 -d\;`
    USEDSWAP=`echo $SWAP | cut -f3 -d\;`
    FREESWAP=`echo $SWAP | cut -f4 -d\;`

    MEMORYTOGETHER=`expr $FREEMEMORY + $CACHEDMEMORY + $BUFFEREDMEMORY`

    MEMORYLIMIT=`expr $TOTALMEMORY \* $INMEMORYLIMIT \/ 100`
    SWAPLIMIT=`expr $TOTALSWAP \* $INSWAPLIMIT \/ 100`

    REALUSEDMEMORY=`expr $TOTALMEMORY - $MEMORYTOGETHER`


    SCRIPTINDEX=$(addOneToIndex $SCRIPTINDEX)
    if [ $REALUSEDMEMORY -gt $MEMORYLIMIT ] ; then
        printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[1]} -d "${DESCR[1]}" -1 "$REALUSEDMEMORY" -2 "$MEMORYLIMIT"
    else
        printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $INFO  -e ${ERRNO[2]} -d "${DESCR[2]}" -1 "$REALUSEDMEMORY" -2 "$MEMORYLIMIT"
    fi

    SCRIPTINDEX=$(addOneToIndex $SCRIPTINDEX)

    if [ $USEDSWAP -gt $SWAPLIMIT ] ; then
        printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[3]} -d "${DESCR[3]}" -1 "$USEDSWAP" -2 "$SWAPLIMIT"
    else
        printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $INFO  -e ${ERRNO[4]} -d "${DESCR[4]}" -1 "$USEDSWAP" -2 "$SWAPLIMIT"

    fi
}

# max 80% of memory and 50% of swap
checkmem ${MEM_PERCENT} ${SWAP_PERCENT}
