#!/bin/bash

# Set default home if not already set.
SYSCHECK_HOME=${SYSCHECK_HOME:-"/usr/local/syscheck"}

# Import common resources
. $SYSCHECK_HOME/resources.sh

raidcheck () {
        DISCID=$1
        COMMAND=`echo "controller slot=0 pd all show" | /usr/sbin/hpacucli | grep "$DISCID"`
        STATUS=`echo $COMMAND | awk '{print $11}' | sed 's/)//g'`
        if [ "xOK" = "x$STATUS" ] ; then
                printlogmess $RAID_LEVEL_1 $RAID_ERRNO_1 "$RAID_DESCR_1" "$COMMAND"
        else
                printlogmess $RAID_LEVEL_2 $RAID_ERRNO_2 "$RAID_DESCR_2" "$COMMAND"

        fi
}
raidcheck "physicaldrive 2:0"
raidcheck "physicaldrive 2:1"


