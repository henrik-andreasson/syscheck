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
. $SYSCHECK_HOME/config/related-scripts.conf

# uniq ID of script (please use in the name of this file also for convinice for finding next availavle number)
SCRIPTID=915
SCRIPTINDEX=00

getlangfiles $SCRIPTID 
getconfig $SCRIPTID

SSHCMD_ERRNO_1="${SCRIPTID}1"
SSHCMD_ERRNO_2="${SCRIPTID}2"
SSHCMD_ERRNO_3="${SCRIPTID}3"
SSHCMD_ERRNO_4="${SCRIPTID}4"

PRINTTOSCREEN=
if [ "x$1" = "x-h" -o "x$1" = "x--help" ] ; then
	echo "$SSHCMD_HELP"
	echo "$SSHCMD_ERRNO_1/$SSHCMD_DESCR_1 - $SSHCMD_HELP_1"
	echo "$SSHCMD_ERRNO_2/$SSHCMD_DESCR_2 - $SSHCMD_HELP_2"
	echo "$SSHCMD_ERRNO_3/$SSHCMD_DESCR_3 - $SSHCMD_HELP_3"
	echo "$SSHCMD_ERRNO_4/$SSHCMD_DESCR_4 - $SSHCMD_HELP_4"
	echo "${SCREEN_HELP}"
	exit
elif [ "x$1" = "x-s" -o  "x$1" = "x--screen" -o \
    "x$2" = "x-s" -o  "x$2" = "x--screen"   ] ; then
    shift
    PRINTTOSCREEN=1
fi 


# arg1
SSHHOST=
if [ "x$1" = "x"  ] ; then 
	printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   $ERROR $SSHCMD_ERRNO_2 "$SSHCMD_DESCR_2"  
	exit -1
else
    SSHHOST=$1
fi


# arg2 mandatory, eg.: "ls /tmp/file" (tip: ssh will return with the returncode of the command executed on the other side of the ssh tunnel)
SSHCMD=
if [ "x$2" = "x"  ] ; then 
        printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   $ERROR $SSHCMD_ERRNO_3 "$SSHCMD_DESCR_3"
        exit -1
else
	SSHCMD=$2
fi

# arg3 optional, if not specified the executing user will be used
SSHTOUSER=
if [ "x$3" != "x"  ] ; then 
    SSHTOUSER="$3@"
fi


# arg4 optional , if not specified the default key will be used
SSHFROMKEY=
if [ "x$4" != "x"  ] ; then 
    SSHFROMKEY="$4"
fi



if [ "x${SSHFROMKEY}" != "x" ] ; then
	printtoscreen "ssh ${SSHOPTIONS} -i ${SSHFROMKEY} ${SSHTOUSER}${SSHHOST} ${SSHCMD} 2>&1"
	ssh ${SSHOPTIONS} -i ${SSHFROMKEY} ${SSHTOUSER}${SSHHOST} ${SSHCMD} 2>&1
	retcode=$?
else
	printtoscreen "ssh ${SSHOPTIONS} ${SSHTOUSER}${SSHHOST} ${SSHCMD} 2>&1"
	ssh ${SSHOPTIONS} ${SSHTOUSER}${SSHHOST} ${SSHCMD} 2>&1
	retcode=$?
fi

if [ $retcode -eq 0 ] ; then
	printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   $INFO $SSHCMD_ERRNO_1 "$SSHCMD_DESCR_1" "${SSHTOUSER}${SSHHOST} ${SSHCMD}"
else
	printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   $ERROR $SSHCMD_ERRNO_4 "$SSHCMD_DESCR_4" "$retcode"
	exit $retcode
fi
