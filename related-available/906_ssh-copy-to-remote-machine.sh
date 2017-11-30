#!/bin/bash
# 
# Set SYSCHECK_HOME if not already set.

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

# uniq ID of script (please use in the name of this file also for convinice for finding next availavle number)
SCRIPTID=906

# Index is used to uniquely identify one test done by the script (a harddrive, crl or cert)
SCRIPTINDEX=00

getlangfiles $SCRIPTID 
getconfig $SCRIPTID


ERRNO_1="01"
ERRNO_2="02"
ERRNO_3="03"
ERRNO_4="04"


PRINTTOSCREEN=
if [ "x$1" = "x-h" -o "x$1" = "x--help" ] ; then
	/bin/echo -e "$HELP"
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
SSHFILE=
if [ "x$1" = "x" ] ; then 
    printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX} $ERROR $ERRNO_2 "$DESCR_2"  
    exit
else
    SSHFILE="$1"
fi


SSHHOST=
if [ "x$2" = "x"  ] ; then 
	printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   $ERROR $ERRNO_3 "$DESCR_3"  
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


SCRIPTINDEX=$(addOneToIndex $SCRIPTINDEX)
runresult=`scp -r ${SSHTIMEOUT} ${SSHFROMKEY} ${SSHFILE} ${SSHTOUSER}${SSHHOST}:${SSHDIR} 2>&1`
if [ $? -eq 0 ] ; then
	printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   $INFO $ERRNO_1 "$DESCR_1" 
else
	printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   $ERROR $ERRNO_4 "$DESCR_4" "$runresult"
	exit -1
fi
