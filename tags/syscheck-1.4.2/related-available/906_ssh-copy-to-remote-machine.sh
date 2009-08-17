#!/bin/sh
# 

# Set default home if not already set.
SYSCHECK_HOME=${SYSCHECK_HOME:-"/usr/local/syscheck"}


## Import common definitions ##
. $SYSCHECK_HOME/resources.sh

# uniq ID of script (please use in the name of this file also for convinice for finding next availavle number)
SCRIPTID=906

getlangfiles $SCRIPTID 
getconfig $SCRIPTID


ERRNO_1="${SCRIPTID}1"
ERRNO_2="${SCRIPTID}2"
ERRNO_3="${SCRIPTID}3"
ERRNO_4="${SCRIPTID}4"


PRINTTOSCREEN=
if [ "x$1" = "x-h" -o "x$1" = "x--help" ] ; then
	echo "$SSH_HELP"
	echo "$ERRNO_1/$SSH_DESCR_1 - $SSH_HELP_1"
	echo "$ERRNO_2/$SSH_DESCR_2 - $SSH_HELP_2"
	echo "$ERRNO_3/$SSH_DESCR_3 - $SSH_HELP_3"
	echo "$ERRNO_4/$SSH_DESCR_4 - $SSH_HELP_4"
	echo "${SCREEN_HELP}"
	exit
elif [ "x$1" = "x-s" -o  "x$1" = "x--screen" -o \
    "x$2" = "x-s" -o  "x$2" = "x--screen"   ] ; then
    shift
    PRINTTOSCREEN=1
fi 

# arg1, if you use regexps, be sure to use "" , ex: "*.txt" on the command line
SSHFILE=
if [ "x$1" = "x" ] ; then 
    printlogmess $ERROR $ERRNO_2 "$SSH_DESCR_2"  
    exit
else
    SSHFILE="$1"
fi


SSHHOST=
if [ "x$2" = "x"  ] ; then 
	printlogmess $ERROR $ERRNO_3 "$SSH_DESCR_3"  
	exit
else
    SSHHOST=$2
fi


SSHDIR=
if [ "x$3" != "x"  ] ; then 
    SSHDIR=$3
fi

SSHTOUSER=
if [ "x$4" != "x"  ] ; then 
    SSHTOUSER="$4@"
fi


SSHFROMKEY=
if [ "x$5" != "x"  ] ; then 
    SSHFROMKEY="-i $5"
fi



runresult=`scp -r ${SSHTIMEOUT} ${SSHFROMKEY} ${SSHFILE} ${SSHTOUSER}${SSHHOST}:${SSHDIR} 2>&1`
if [ $? -eq 0 ] ; then
	printlogmess $INFO $ERRNO_1 "$SSH_DESCR_1" 
else
	printlogmess $ERROR $ERRNO_4 "$SSH_DESCR_4" "$runresult"
	exit -1
fi
