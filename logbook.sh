#!/bin/bash

#Scripts that creates replication privilegdes for the slave db to the master.

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
source $SYSCHECK_HOME/config/common.conf

# uniq ID of script (please use in the name of this file also for convinice for finding next availavle number)
SCRIPTID=701

# Index is used to uniquely identify one test done by the script (a harddrive, crl or cert)
SCRIPTINDEX=00

getlangfiles $SCRIPTID || exit 1;
getconfig $SCRIPTID || exit 1;

ERRNO_1="${SCRIPTID}1"
ERRNO_2="${SCRIPTID}2"
ERRNO_3="${SCRIPTID}3"
ERRNO_4="${SCRIPTID}4"

printf "$0: Tool to log messages to syscheck\n\n"

ExecutingUserName=$(whoami)
ExecutingUserId=$(id -u)

if [ "x${ExecutingUserName}" = "xroot" ] ; then
    printf "Do not run as root\n"
    exit
fi

schelp () {
	/bin/echo -e "$HELP"
	/bin/echo -e "$ERRNO_1/$DESCR_1 - $HELP_1"
	/bin/echo -e "$0 [-r|--read] | [-p|--post] (read is default)"
	exit
}


TEMP=`/usr/bin/getopt --options "hrp" --long "help,read,post" -- "$@"`
if [ $? != 0 ] ; then help ; fi
eval set -- "$TEMP"

while true; do
  case "$1" in
    -r|--read ) READ=1; shift;;
    -p|--post  ) POST=1; shift;;
    -h|--help )   schelp;shift;;
    --) break ;;
  esac
done

if [ "x$READ" != "x1" -a "x$POST" != "x1"  ] ; then
    READ=1 # defaults to read

fi

if [ "x$POST" = "x1" ] ; then
    printf "Enter any type of info that needs to be logged into the logbook (max ${MESSAGELENGTH} chars)\n"
    read -e -n ${MESSAGELENGTH} -r -p "> " LOGENTRY

    if [ "x$LOGENTRY" = "x" ] ; then
        printf "no message to post\n"
    else
        sudo ${SYSCHECK_HOME}/lib/logbook-cli.sh ${SCRIPTID} ${SCRIPTINDEX} $INFO $ERRNO_1 "$DESCR_1" "${ExecutingUserName}" "$LOGENTRY"
    fi
fi

daysago=0
if [ "x$READ" = "x1" ] ; then
    while [ true ] ; do
        datestr=$(date +"%Y%m%d" -d "now - $daysago day")
        printf "Logentries for: $datestr\n"
        if [ ${LOGBOOK_OUTPUTTYPE} = "JSON" ] ; then
            LOGENTRIES=$(sudo grep "${SYSTEMNAME} ${datestr}" ${LOGBOOK_FILENAME}) 
            IFS=$'\n'
            for row in $LOGENTRIES ; do
                echo $row |  python -c 'import json,sys;obj=json.load(sys.stdin);print obj["LEGACYFMT"]';
            done
        else
            sudo grep "${SYSTEMNAME} ${datestr}" ${LOGBOOK_FILENAME}
        fi    
        let daysago="daysago + 1"
        printf "end-of-entries, press enter to see next day"
        read a
    done
fi


