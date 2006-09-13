#!/bin/sh 

# Set default home if not already set.
SYSCHECK_HOME=${SYSCHECK_HOME:-"/usr/local/syscheck"}

# Import common resources
. $SYSCHECK_HOME/resources.sh

DEBUG="/dev/null 2>&1"


if [ "x$1" = "x--debug" ] ; then
	DEBUG="/dev/stdout"
fi

STATUS=`list_reader.pl 2>&1 | grep "Number of attatched readers:"`


if [ "Number of attatched readers: $PCSC_NUMBER_OF_READERS" = "$STATUS" ] ; then     
        printlogmess $PCL_LEVEL_1 $PCL_ERRNO_1 "$PCL_DESCR_1" "$STATUS" 
	
else

        printlogmess $PCL_LEVEL_2 $PCL_ERRNO_2 "$PCL_DESCR_2" "$STATUS"
fi

