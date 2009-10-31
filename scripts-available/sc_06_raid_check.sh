#!/bin/bash

# Set default home if not already set.
SYSCHECK_HOME=${SYSCHECK_HOME:-"/usr/local/syscheck"}

## Import common definitions ##
. $SYSCHECK_HOME/resources.sh

SCRIPTID=06


getlangfiles $SCRIPTID 
getconfig $SCRIPTID


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
        DISCID="$1"
	xSLOT="$2"
        COMMAND=`echo "controller slot=${xSLOT} pd all show" | $RAID_HPTOOL | grep "$DISCID"`
        STATUS=`echo $COMMAND | grep "OK"`
        if [ "x$STATUS" != "x" ] ; then
                printlogmess $INFO $RAID_ERRNO_1 "$RAID_DESCR_1" "$COMMAND"
        else
                printlogmess $ERROR $RAID_ERRNO_2 "$RAID_DESCR_2" "$COMMAND disc: $DISCID slot: $xSLOT"
        fi
}


raidlogiccheck () {
	LDID="$1"
	xSLOT="$2"

        COMMAND=`echo "controller slot=${xSLOT} ld all show" | $RAID_HPTOOL | grep "$LDID"` 
	STATUS=`echo $COMMAND | grep "OK"`

	if [ "x$STATUS" != "x" ] ; then
                printlogmess $INFO $RAID_ERRNO_3 "$RAID_DESCR_3" "$COMMAND"

        elif [ "xRebuilding" = "x$COMMAND" ] ; then
                printlogmess $ERROR $RAID_ERRNO_4 "$RAID_DESCR_4" "$COMMAND"
	else 
                printlogmess $ERROR $RAID_ERRNO_5 "$RAID_DESCR_5" "$COMMAND LD:$LDID slot: $xSLOT"
	fi
}


if [ ! -x $RAID_HPTOOL ] ; then
    printlogmess $ERROR $RAID_ERRNO_6 "$RAID_DESCR_6" $RAID_HPTOOL
    exit
fi


for (( i = 0 ;  i < ${#PHYSICALDRIVE[@]} ; i++ )) ; do
	#raiddiskcheck "physicaldrive 2:0"
	raiddiskcheck "${PHYSICALDRIVE[$i]}" $SLOT
done

for (( i = 0 ;  i < ${#LOGICALDRIVE[@]} ; i++ )) ; do
	raidlogiccheck "${LOGICALDRIVE[$i]}" $SLOT
#	raidlogiccheck "logicaldrive 1"
done



