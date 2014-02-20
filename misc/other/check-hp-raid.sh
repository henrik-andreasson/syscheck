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
. $SYSCHECK_HOME/config/common.conf

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



