#!/bin/sh 

# Set default home if not already set.
SYSCHECK_HOME=${SYSCHECK_HOME:-"/usr/local/syscheck"}

# Import common resources
. $SYSCHECK_HOME/resources.sh

cd $SIGNSERVER_HOME
OUTPUT=`$SIGNSERVER_HOME/bin/signserver.sh getstatus all 1 | grep "Status : Active"` 



if [ "$OUTPUT" = "" ] ; then
	printlogmess $DSS_LEVEL_2 $DSS_ERRNO_2 "$DSS_DESCR_2"  
else
	printlogmess $DSS_LEVEL_1 $DSS_ERRNO_1 "$DSS_DESCR_1"
fi

