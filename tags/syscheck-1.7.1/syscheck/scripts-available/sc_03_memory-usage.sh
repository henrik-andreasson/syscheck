#!/bin/bash

# Set SYSCHECK_HOME if not already set.

# 1. First check if SYSCHECK_HOME is set then use that
if [ "x${SYSCHECK_HOME}" = "x" ] ; then
# 2. Check if /etc/syscheck.conf exists then source that (put SYSCHECK_HOME=/path/to/syscheck in ther)
    if [ -e /etc/syscheck.conf ] ; then 
	source /etc/syscheck.conf 
    else
# 3. last resort use default path
	SYSCHECK_HOME="/usr/local/syscheck"
    fi
fi

if [ ! -f ${SYSCHECK_HOME}/syscheck.sh ] ; then echo "$0: Can't find syscheck.sh in SYSCHECK_HOME ($SYSCHECK_HOME)" ;exit ; fi

## Import common definitions ##
. $SYSCHECK_HOME/config/syscheck-scripts.conf

# uniq ID of script (please use in the name of this file also for convinice for finding next availavle number)
SCRIPTID=03

# Index is used to uniquely identify one test done by the script (a harddrive, crl or cert)
SCRIPTINDEX=00

getlangfiles $SCRIPTID
getconfig $SCRIPTID

ERRNO_1=01
ERRNO_2=02
ERRNO_3=03
ERRNO_4=03


if [ "x$1" = "x--help" ] ; then
    echo "$HELP mem: ${MEM_PERCENT}% / swap ${SWAP_PERCENT} %"
    echo "${ERRNO_1}/${DESCR_1}"
    echo "${ERRNO_2}/${DESCR_2}"
    echo "${ERRNO_3}/${DESCR_3}"
    echo "${ERRNO_4}/${DESCR_4}"
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
    

    SCRIPTINDEX=$(addOneToIndex $SCRIPTINDEX)
    if [ $REALUSEDMEMORY -gt $MEMORYLIMIT ] ; then
        printlogmess ${SCRIPTID} ${SCRIPTINDEX} $ERROR $ERRNO_1 "$DESCR_1" "$REALUSEDMEMORY" "$MEMORYLIMIT"
    else
        printlogmess ${SCRIPTID} ${SCRIPTINDEX} $INFO $ERRNO_2 "$DESCR_2" "$REALUSEDMEMORY" "$MEMORYLIMIT"
    fi
    
    SCRIPTINDEX=$(addOneToIndex $SCRIPTINDEX)

    if [ $USEDSWAP -gt $SWAPLIMIT ] ; then
        printlogmess ${SCRIPTID} ${SCRIPTINDEX} $ERROR $ERRNO_3 "$DESCR_3" "$USEDSWAP" "$SWAPLIMIT"
    else
        printlogmess ${SCRIPTID} ${SCRIPTINDEX} $INFO $ERRNO_4 "$DESCR_4" "$USEDSWAP" "$SWAPLIMIT"
	
    fi
}

# max 80% of memory and 50% of swap 
checkmem ${MEM_PERCENT} ${SWAP_PERCENT}

