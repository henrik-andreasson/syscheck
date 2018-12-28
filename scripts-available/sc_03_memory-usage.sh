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


checkmem(){
    INMEMORYLIMIT=$1
    INSWAPLIMIT=$2

    MEMORY=`free | grep -v total | grep -v buffers | grep -v Swap | cut -f2 -d: | perl -ane 's/\ +/;/gio,print'`
    SWAP=`free | grep -v total | grep -v buffers | grep -v Mem | cut -f2 -d: | perl -ane 's/\ +/;/gio,print'`

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
        printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX} $ERROR ${ERRNO[1]} "${DESCR[1]}" "$REALUSEDMEMORY" "$MEMORYLIMIT"
    else
        printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX} $INFO ${ERRNO[2]} "${DESCR[2]}" "$REALUSEDMEMORY" "$MEMORYLIMIT"
    fi

    SCRIPTINDEX=$(addOneToIndex $SCRIPTINDEX)

    if [ $USEDSWAP -gt $SWAPLIMIT ] ; then
        printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX} $ERROR ${ERRNO[3]} "${DESCR[3]}" "$USEDSWAP" "$SWAPLIMIT"
    else
        printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX} $INFO ${ERRNO[4]} "${DESCR[4]}" "$USEDSWAP" "$SWAPLIMIT"

    fi
}

# max 80% of memory and 50% of swap
checkmem ${MEM_PERCENT} ${SWAP_PERCENT}
