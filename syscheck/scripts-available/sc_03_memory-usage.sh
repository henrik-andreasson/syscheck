#!/bin/bash

# Set default home if not already set.
SYSCHECK_HOME=${SYSCHECK_HOME:-"/usr/local/syscheck"}

# Import common resources
. $SYSCHECK_HOME/resources.sh

# uniq ID of script (please use in the name of this file also for convinice for finding next availavle number)
SCRIPTID=03

MEM_ERRNO_1=${SCRIPTID}01
MEM_ERRNO_2=${SCRIPTID}02
MEM_ERRNO_3=${SCRIPTID}03
MEM_ERRNO_4=${SCRIPTID}03




if [ "x$1" = "x--help" ] ; then
        echo "Script that checks that the disk have enougth free space on the hard drive."
        echo "The limit is configured in the script (limit: ${DU_PERCENT}%)"
        echo "to run with output directed to screen:"
        echo "$0 <-s|--screen>"
        exit
elif [ "x$1" = "x-s" -o  "x$1" = "x--screen"  ] ; then
    PRINTTOSCREEN=1
fi 


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

# Memorylimit is set to 80%
MEMORYLIMIT=`expr $TOTALMEMORY \* 8 \/ 10`

# Swaplimit is set to 50%
SWAPLIMIT=`expr $TOTALSWAP \* 5 \/ 10`

REALUSEDMEMORY=`expr $TOTALMEMORY - $MEMORYTOGETHER`

if [ $REALUSEDMEMORY -gt $MEMORYLIMIT ] ; then
        printlogmess $WARN $MEM_ERRNO_1 "$MEM_DESCR_1" "$REALUSEDMEMORY" "$MEMORYLIMIT"
else
        printlogmess $INFO $MEM_ERRNO_2 "$MEM_DESCR_2" "$REALUSEDMEMORY" "$MEMORYLIMIT"
fi

if [ $USEDSWAP -gt $SWAPLIMIT ] ; then
        printlogmess $WARN $MEM_ERRNO_3 "$MEM_DESCR_3" "$USEDSWAP" "$SWAPLIMIT"
else
        printlogmess $INFO $MEM_ERRNO_4 "$MEM_DESCR_4" "$USEDSWAP" "$SWAPLIMIT"

fi
