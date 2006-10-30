#!/bin/sh 

# Set default home if not already set.
SYSCHECK_HOME=${SYSCHECK_HOME:-"/usr/local/syscheck"}

# Import common resources
. $SYSCHECK_HOME/resources.sh

SCRIPTID=04

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

STATUS=`echo $CMD | grep "Number of attatched readers:"`


if [ "Number of attatched readers: $PCSC_NUMBER_OF_READERS" = "$STATUS" ] ; then     
        printlogmess $INFO $PCL_ERRNO_1 "$PCL_DESCR_1" "$STATUS" 
	
else

        printlogmess $ERROR $PCL_ERRNO_2 "$PCL_DESCR_2" "$STATUS"
fi

