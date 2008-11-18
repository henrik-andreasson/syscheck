#!/bin/sh
# 

# Set default home if not already set.
SYSCHECK_HOME=${SYSCHECK_HOME:-"/usr/local/syscheck"}


## Import common definitions ##
. $SYSCHECK_HOME/resources.sh

# uniq ID of script (please use in the name of this file also for convinice for finding next availavle number)
SCRIPTID=915

# local definitions #

# Good defaults for ssh options is a timeout (value is seconds)
SSHOPTIONS="-o ConnectTimeout=10"

# end defs #

getlangfiles $SCRIPTID ;

ERRNO_1="${SCRIPTID}1"
ERRNO_2="${SCRIPTID}2"
ERRNO_3="${SCRIPTID}3"
ERRNO_4="${SCRIPTID}4"


PRINTTOSCREEN=
if [ "x$1" = "x-h" -o "x$1" = "x--help" ] ; then
	echo "$SSHCMD_HELP"
	echo "$ERRNO_1/$SSHCMD_DESCR_1 - $SSH_HELP_1"
	echo "$ERRNO_2/$SSHCMD_DESCR_2 - $SSH_HELP_2"
	echo "$ERRNO_3/$SSHCMD_DESCR_3 - $SSH_HELP_3"
	echo "$ERRNO_4/$SSHCMD_DESCR_4 - $SSH_HELP_4"
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
	printlogmess $ERROR $ERRNO_3 "$SSHCMD_DESCR_3"  
	exit -1
else
    SSHHOST=$1
fi


# arg2 mandatory, eg.: "ls /tmp/file" (tip: ssh will return with the returncode of the command executed on the other side of the ssh tunnel)
SSHCMD=
if [ "x$2" = "x"  ] ; then 
        printlogmess $ERROR $ERRNO_3 "$SSHCMD_DESCR_3"
        exit -1
else
	SSHCMD=$2
fi

# arg3 optional, if not specified the executing user will be used
SSHTOUSER=
if [ "x$3" != "x"  ] ; then 
    SSHTOUSER=" -l $3"
fi


# arg4 optional , if not specified the default key will be used
SSHFROMKEY=
if [ "x$4" != "x"  ] ; then 
    SSHFROMKEY="-i $4"
fi



printtoscreen "ssh ${SSHOPTIONS} ${SSHFROMKEY} ${SSHUSER} ${SSHHOST} ${SSHCMD} 2>&1"
ssh ${SSHOPTIONS} ${SSHFROMKEY} ${SSHUSER} ${SSHHOST} ${SSHCMD} 2>&1
retcode=$?

if [ $retcode -eq 0 ] ; then
	printlogmess $INFO $ERRNO_1 "$SSHCMD_DESCR_1" 
else
	printlogmess $ERROR $ERRNO_4 "$SSHCMD_DESCR_4" "$retcode"
	exit $retcode
fi
