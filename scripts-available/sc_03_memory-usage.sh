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

    TOTALMEMORY=`free | grep Mem | awk '{print $2}'`
    USEDMEMORY=`free | grep Mem | awk '{print $3}'`


    TOTALSWAP=`free | grep Swap | awk '{print $2}'`
    USEDSWAP=`free | grep Swap | awk '{print $3}'`


    MEMORYLIMIT=`expr $TOTALMEMORY \* $INMEMORYLIMIT \/ 100`
    SWAPLIMIT=`expr $TOTALSWAP \* $INSWAPLIMIT \/ 100`


    if [ "x$HUMAN_READABLE" == "x1" ] ; then
        MEMORYDISPLAY=`numfmt --from-unit=Ki --to=iec-i ${USEDMEMORY}`
        MLIMITDISPLAY=`numfmt --from-unit=Ki --to=iec-i ${MEMORYLIMIT}`

        SWAPDISPLAY=`numfmt --from-unit=Ki --to=iec-i ${USEDSWAP}`
        SLIMITDISPLAY=`numfmt --from-unit=Ki --to=iec-i ${SWAPLIMIT}`
    else
        MEMORYDISPLAY=${USEDMEMORY}
        MLIMITDISPLAY=${MEMORYLIMIT}

        SWAPDISPLAY=${USEDSWAP}
        SLIMITDISPLAY=${SWAPLIMIT}
    fi

    SCRIPTINDEX=$(addOneToIndex $SCRIPTINDEX)
    if [ $USEDMEMORY -gt $MEMORYLIMIT ] ; then
        printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[1]} -d "${DESCR[1]}" -1 "$MEMORYDISPLAY" -2 "$MLIMITDISPLAY"
    else
        printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $INFO  -e ${ERRNO[2]} -d "${DESCR[2]}" -1 "$MEMORYDISPLAY" -2 "$MLIMITDISPLAY"
    fi

    SCRIPTINDEX=$(addOneToIndex $SCRIPTINDEX)

    if [ $USEDSWAP -gt $SWAPLIMIT ] ; then
        printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[3]} -d "${DESCR[3]}" -1 "$SWAPDISPLAY" -2 "$SLIMITDISPLAY"
    else
        printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $INFO  -e ${ERRNO[4]} -d "${DESCR[4]}" -1 "$SWAPDISPLAY" -2 "$SLIMITDISPLAY"

    fi
}

# max 80% of memory and 50% of swap
checkmem ${MEM_PERCENT} ${SWAP_PERCENT}
