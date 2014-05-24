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

PATH=$SYSCHECK_HOME:$PATH

export PATH 

SCRIPTID=00

getlangfiles $SCRIPTID
getconfig $SCRIPTID

PRINTTOSCREEN=

help () {
        echo "$HELP"
        echo "$0 -c|--cert <certfile-in-der-format> [-s|--screen] [-h|--help]"
        echo "$ERRNO_1/$REMCMD_DESCR_1 - $REMCMD_HELP_1"
        echo "$ERRNO_2/$REMCMD_DESCR_2 - $REMCMD_HELP_2"
        echo "$ERRNO_3/$REMCMD_DESCR_3 - $REMCMD_HELP_3"
        echo "${SCREEN_HELP}"
        exit
}

TEMP=`/usr/bin/getopt --options ":h:s" --long "help,screen" -- "$@"`
if [ $? != 0 ] ; then help ; fi
eval set -- "$TEMP"

while true; do
  case "$1" in
    -s|--screen ) PRINTTOSCREEN=1; shift;;
    -h|--help )   help;shift;;
    --) break ;;
  esac
done

export PRINTTOSCREEN
export SAVELASTSTATUS

date > ${SYSCHECK_HOME}/var/last_status
for file in ${SYSCHECK_HOME}/scripts-enabled/sc_* ; do
	$file
done


