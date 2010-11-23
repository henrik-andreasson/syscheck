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
SCRIPTID=903

getlangfiles $SCRIPTID
getconfig $SCRIPTID

ERRNO_1="${SCRIPTID}1"
ERRNO_2="${SCRIPTID}2"
ERRNO_3="${SCRIPTID}3"


PRINTTOSCREEN=
if [ "x$1" = "x-h" -o "x$1" = "x--help" ] ; then
	echo "$HSM_HELP"
	echo "$ERRNO_1/$DESCR_1 "
	echo "$ERRNO_2/$DESCR_2 "
	echo "${SCREEN_HELP}"
	exit
elif [ "x$1" == "x-s" -o  "x$1" == "x--screen" -o \
    "x$2" == "x-s" -o  "x$2" == "x--screen"   ] ; then
    PRINTTOSCREEN=1
fi 


DATE=`date +%Y%m%d-%H.%M`

tar -c --directory $HSMDIR -f $FULLFILENAME local

if [ $? = 0 ] ; then
    gzip $FULLFILENAME
    if [ $? = 0 ] ; then
	printlogmess $INFO $ERRNO_1 "$DESCR_1" 
    else
	printlogmess $ERROR $ERRNO_2 "$DESCR_2"
    fi  
else
    printlogmess $ERROR $ERRNO_2 "$DESCR_2"
fi 



