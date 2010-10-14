#!/bin/sh 

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

SCRIPTID=04

getlangfiles $SCRIPTID
getconfig $SCRIPTID


PCL_ERRNO_1=${SCRIPTID}01
PCL_ERRNO_2=${SCRIPTID}02
PCL_ERRNO_3=${SCRIPTID}03

# help
if [ "x$1" = "x--help" ] ; then
    echo "$0 $PCL_HELP"
    echo "$PCL_ERRNO_1/$PCL_DESCR_1 - $PCL_HELP_1"
    echo "$PCL_ERRNO_2/$PCL_DESCR_2 - $PCL_HELP_2"
    echo "$PCL_ERRNO_3/$PCL_DESCR_3 - $PCL_HELP_3"
    exit
elif [ "x$1" = "x-s" -o  "x$1" = "x--screen"  ] ; then
    PRINTTOSCREEN=1
fi

CMD=`$SYSCHECK_HOME/lib/list_reader.pl 2>&1`

ERRCHK=`echo $CMD| grep "locate Chipcard/PCSC.pm" ` 
if [ "x$ERRCHK" != "x" ] ; then
	printlogmess $WARN $PCL_ERRNO_3 "$PCL_DESCR_3" "$CMD"
	exit
fi

STATUS=`echo $CMD | perl -ane 'm/Number\ of\ attatched\ readers:\ (\d+)/gio, print $1'`


if [ "$PCSC_NUMBER_OF_READERS" = "$STATUS" ] ; then     
        printlogmess $INFO $PCL_ERRNO_1 "$PCL_DESCR_1" "$STATUS" 
	
else

        printlogmess $ERROR $PCL_ERRNO_2 "$PCL_DESCR_2" "$STATUS"
fi

