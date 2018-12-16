#!/bin/bash

# 1. First check if SYSCHECK_HOME is set then use that
if [ "x${SYSCHECK_HOME}" = "x" ] ; then
# 2. Check if /etc/syscheck.conf exists then source that (put SYSCHECK_HOME=/path/to/syscheck in ther)
    if [ -e /etc/syscheck.conf ] ; then
	source /etc/syscheck.conf
    else
# 3. last resort use default path
	SYSCHECK_HOME="/opt/syscheck"
    fi
fi

if [ ! -f ${SYSCHECK_HOME}/syscheck.sh ] ; then echo "$0: Can't find syscheck.sh in SYSCHECK_HOME ($SYSCHECK_HOME)" ;exit ; fi

## Import common definitions ##
. $SYSCHECK_HOME/config/related-scripts.conf

# scriptname used to map and explain scripts in icinga and other
SCRIPTNAME=rsync_to_remote_machine

# uniq ID of script (please use in the name of this file also for convinice for finding next available number)
SCRIPTID=923

# Index is used to uniquely identify one test done by the script (a harddrive, crl or cert)
SCRIPTINDEX=00

getlangfiles $SCRIPTID
getconfig $SCRIPTID


ERRNO_1="${SCRIPTID}1"
ERRNO_2="${SCRIPTID}2"
ERRNO_3="${SCRIPTID}3"
ERRNO_4="${SCRIPTID}4"


PRINTTOSCREEN=
if [ "x$1" = "x-h" -o "x$1" = "x--help" ] ; then
	echo "$HELP"
	echo "$ERRNO_1/$DESCR_1 - $HELP_1"
	echo "$ERRNO_2/$DESCR_2 - $HELP_2"
	echo "$ERRNO_3/$DESCR_3 - $HELP_3"
	echo "$ERRNO_4/$DESCR_4 - $HELP_4"
	echo "${SCREEN_HELP}"
	exit
elif [ "x$1" = "x-s" -o  "x$1" = "x--screen" -o \
    "x$2" = "x-s" -o  "x$2" = "x--screen"   ] ; then
    shift
    PRINTTOSCREEN=1
fi




# arg1, if you use regexps, be sure to use "" , ex: "*.txt" on the command line
FILES=
if [ "x$1" = "x" ] ; then
    printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   $ERROR $ERRNO_2 "$DESCR_2"
    exit
else
    FILES="$1"
fi

# arg2, SSHHOST is MANDATORY, to which host to rsync the files
SSHHOST=
if [ "x$2" = "x"  ] ; then
	printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   $ERROR $ERRNO_3 "$DESCR_3"
	exit
else
    SSHHOST=$2
fi


# arg3, where to put the files on the remote host, if SSHDIR is undefined the files will end up in the users homedir on the remote machine
SSHDIR=
if [ "x$3" != "x"  ] ; then
    SSHDIR=$3
fi

# arg4, to log in with which user on the remote machine, if SSHTOUSER is undefined the local executing username will be used
SSHTOUSER=
if [ "x$4" != "x"  ] ; then
    SSHTOUSER="-l $4"
fi

# arg5, use this ssh-key to authenticate, if SSHFROMKEY is undefined the default will be used if it exist, else password will be used which most probably is not what you want
SSHFROMKEY=
if [ "x$5" != "x"  ] ; then
    SSHFROMKEY="-i $5"
fi



runresult=`rsync --recursive ${RSYNC_OPTIONS} -e "ssh ${SSHFROMKEY} ${SSHTOUSER}" ${FILES} ${SSHHOST}:${SSHDIR} 2>&1`
if [ $? -eq 0 ] ; then
	printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   $INFO $ERRNO_1 "$DESCR_1"
else
	printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   $ERROR $ERRNO_4 "$DESCR_4" "$runresult"
	exit -1
fi
