#!/bin/sh
# 

# Set default home if not already set.
SYSCHECK_HOME=${SYSCHECK_HOME:-"/usr/local/syscheck"}


## Import common definitions ##
. $SYSCHECK_HOME/resources.sh

# uniq ID of script (please use in the name of this file also for convinice for finding next available number)
SCRIPTID=923

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
    printlogmess $ERROR $ERRNO_2 "$DESCR_2"  
    exit
else
    FILES="$1"
fi

# arg2, SSHHOST is MANDATORY, to which host to rsync the files
SSHHOST=
if [ "x$2" = "x"  ] ; then 
	printlogmess $ERROR $ERRNO_3 "$DESCR_3"  
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
	printlogmess $INFO $ERRNO_1 "$DESCR_1" 
else
	printlogmess $ERROR $ERRNO_4 "$DESCR_4" "$runresult"
	exit -1
fi
