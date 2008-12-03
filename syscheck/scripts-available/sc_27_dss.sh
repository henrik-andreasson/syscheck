#!/bin/sh 

# Set default home if not already set.
SYSCHECK_HOME=${SYSCHECK_HOME:-"/usr/local/syscheck"}

## Import common definitions ##
. $SYSCHECK_HOME/resources.sh

SCRIPTID=27

getlangfiles $SCRIPTID
getconfig $SCRIPTID

ERRNO_1=${SCRIPTID}01
ERRNO_2=${SCRIPTID}02
ERRNO_3=${SCRIPTID}03
ERRNO_4=${SCRIPTID}04

# help
if [ "x$1" = "x--help" ] ; then
    echo "$0 $HELP"
    echo "$ERRNO_1/$DSS_DESCR_1 - $DSS_HELP_1"
    echo "$ERRNO_2/$DSS_DESCR_2 - $DSS_HELP_2"
    echo "$ERRNO_3/$DSS_DESCR_3 - $DSS_HELP_3"
    echo "$ERRNO_4/$DSS_DESCR_4 - $DSS_HELP_4"
    exit
elif [ "x$1" = "x-s" -o  "x$1" = "x--screen"  ] ; then
    PRINTTOSCREEN=1
fi


if [ ! -f $SIGNSERVER_HOME/bin/signserver.sh ] ; then 
    printlogmess $ERROR $ERRNO_4 "$DSS_DESCR_4"
    exit
fi
cd $SIGNSERVER_HOME
OUTPUT=`$SIGNSERVER_HOME/bin/signserver.sh getstatus all 1 | grep "Status : Active" | wc -l` 


if [ "$OUTPUT" = "2" ] ; then
	printlogmess $INFO $ERRNO_1 "$DSS_DESCR_1"  
elif [ "$OUTPUT" = "1" ] ; then
	printlogmess $WARNING $ERRNO_2 "$DSS_DESCR_2"  
else
	printlogmess $ERROR $ERRNO_3 "$DSS_DESCR_3"
fi

