#!/bin/bash


# Set default home if not already set.
SYSCHECK_HOME=${SYSCHECK_HOME:-"/usr/local/syscheck"}

## Import common definitions ##
. $SYSCHECK_HOME/resources.sh

getconfig 06

echo "controllers:"
echo "controller all show" | $RAID_HPTOOL

echo "enter the slot to show:"
read xSLOT

echo "#####################################################"
echo "controller slot=${xSLOT} pd all show" | $RAID_HPTOOL
echo
echo "look for strings like: 'physicaldrive 2:0' and put that in the config"
echo
echo
echo
echo "#####################################################"
echo "controller slot=${xSLOT} ld all show" | $RAID_HPTOOL 
echo
echo "look for strings like 'logicaldrive 1' and put that in the config"



