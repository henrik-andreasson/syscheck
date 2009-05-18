#!/bin/sh

# Set default home if not already set.
SYSCHECK_HOME=${SYSCHECK_HOME:-"/usr/local/syscheck"}

## Import common definitions ##
. $SYSCHECK_HOME/resources.sh

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

