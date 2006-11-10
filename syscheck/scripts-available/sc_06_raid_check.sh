#!/bin/bash

# Set default home if not already set.
SYSCHECK_HOME=${SYSCHECK_HOME:-"/usr/local/syscheck"}

# Import common resources
. $SYSCHECK_HOME/resources.sh

SCRIPTID=06

RAID_HPTOOL=/usr/sbin/hpacucli


RAID_ERRNO_1=${SCRIPTID}01
RAID_ERRNO_2=${SCRIPTID}02
RAID_ERRNO_3=${SCRIPTID}03
RAID_ERRNO_4=${SCRIPTID}04
RAID_ERRNO_5=${SCRIPTID}05
RAID_ERRNO_6=${SCRIPTID}06

# help
if [ "x$1" = "x--help" ] ; then
    echo "$0 $RAID_HELP"
    echo "$RAID_ERRNO_1/$RAID_DESCR_1 - $RAID_HELP_1"
    echo "$RAID_ERRNO_2/$RAID_DESCR_2 - $RAID_HELP_2"
    echo "$RAID_ERRNO_3/$RAID_DESCR_3 - $RAID_HELP_3"
    echo "$RAID_ERRNO_4/$RAID_DESCR_4 - $RAID_HELP_4"
    echo "$RAID_ERRNO_5/$RAID_DESCR_5 - $RAID_HELP_5"
    echo "$RAID_ERRNO_6/$RAID_DESCR_6 - $RAID_HELP_6"
    exit
elif [ "x$1" = "x-s" -o  "x$1" = "x--screen"  ] ; then
    PRINTTOSCREEN=1
fi



raiddiskcheck () {
        DISCID=$1
        COMMAND=`echo "controller slot=0 pd all show" | $RAID_HPTOOL | grep "$DISCID"`
        STATUS=`echo $COMMAND | awk '{print $11}' | sed 's/)//g'`
        if [ "xOK" = "x$STATUS" ] ; then
                printlogmess $INFO $RAID_ERRNO_1 "$RAID_DESCR_1" "$COMMAND"
        else
                printlogmess $ERROR $RAID_ERRNO_2 "$RAID_DESCR_2" "$COMMAND"

        fi
}


raidlogiccheck () {
	LDID=$1 

        COMMAND=`echo "controller slot=0 ld all show" | $RAID_HPTOOL | grep "$LDID" | cut -d\, -f3 | sed 's/)//g' | sed 's/\ //'` 
#	echo $COMMAND 

        if [ "xOK" = "x$COMMAND" ] ; then
                printlogmess $INFO $RAID_ERRNO_3 "$RAID_DESCR_3" "$COMMAND"

        elif [ "xRebuilding" = "x$COMMAND" ] ; then
                printlogmess $ERROR $RAID_ERRNO_4 "$RAID_DESCR_4" "$COMMAND"
	else 
                printlogmess $ERROR $RAID_ERRNO_5 "$RAID_DESCR_5" "$COMMAND"
	fi
}


if [ ! -x $RAID_HPTOOL ] ; then
    printlogmess $ERROR $RAID_ERRNO_6 "$RAID_DESCR_6" $RAID_HPTOOL
    exit
fi


raiddiskcheck "physicaldrive 2:0"
raiddiskcheck "physicaldrive 2:1"

raidlogiccheck "logicaldrive 1"


