#!/bin/bash

# Set default home if not already set.
SYSCHECK_HOME=${SYSCHECK_HOME:-"/usr/local/syscheck"}

## Import common definitions ##
. $SYSCHECK_HOME/resources.sh

# uniq ID of script (please use in the name of this file also for convinice for finding next availavle number)
SCRIPTID=03

getlangfiles $SCRIPTID
getconfig $SCRIPTID

ERRNO_1=${SCRIPTID}01
ERRNO_2=${SCRIPTID}02
ERRNO_3=${SCRIPTID}03
ERRNO_4=${SCRIPTID}03


if [ "x$1" = "x--help" ] ; then
    echo "$MEM_HELP mem: ${MEM_PERCENT}% / swap ${SWAP_PERCENT} %"
    echo "${ERRNO_1}/${MEM_DESCR_1}"
    echo "${ERRNO_2}/${MEM_DESCR_2}"
    echo "${ERRNO_3}/${MEM_DESCR_3}"
    echo "${ERRNO_4}/${MEM_DESCR_4}"
    echo "${SCREEN_HELP}"
    exit
elif [ "x$1" = "x-s" -o  "x$1" = "x--screen"  ] ; then
    PRINTTOSCREEN=1
fi 


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
    
    if [ $REALUSEDMEMORY -gt $MEMORYLIMIT ] ; then
        printlogmess $WARN $ERRNO_1 "$MEM_DESCR_1" "$REALUSEDMEMORY" "$MEMORYLIMIT"
    else
        printlogmess $INFO $ERRNO_2 "$MEM_DESCR_2" "$REALUSEDMEMORY" "$MEMORYLIMIT"
    fi
    
    if [ $USEDSWAP -gt $SWAPLIMIT ] ; then
        printlogmess $WARN $ERRNO_3 "$MEM_DESCR_3" "$USEDSWAP" "$SWAPLIMIT"
    else
        printlogmess $INFO $ERRNO_4 "$MEM_DESCR_4" "$USEDSWAP" "$SWAPLIMIT"
	
    fi
}

# max 80% of memory and 50% of swap 
checkmem ${MEM_PERCENT} ${SWAP_PERCENT}
