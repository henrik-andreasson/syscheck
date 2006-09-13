#!/bin/bash

# Set default home if not already set.
SYSCHECK_HOME=${SYSCHECK_HOME:-"/usr/local/syscheck"}

# Import common resources
. $SYSCHECK_HOME/resources.sh


diskusage () {
	FILESYSTEM=$1
	LIMIT=$2
	PERCENT=`df -h $FILESYSTEM | grep -v Filesystem | awk '{print $5}' | sed 's/%//'`

	if [ $PERCENT -ge $LIMIT ] ; then
                printlogmess $DU_LEVEL_1 $DU_ERRNO_1 "$DU_DESCR_1" "$FILESYSTEM" "$PERCENT" "$LIMIT" 
	else
                printlogmess $DU_LEVEL_2 $DU_ERRNO_2 "$DU_DESCR_2" "$FILESYSTEM" "$PERCENT" "$LIMIT" 
	fi
}

diskusage / 80
