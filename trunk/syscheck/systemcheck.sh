#!/bin/sh

# Set default home if not already set.
SYSCHECK_HOME=${SYSCHECK_HOME:-"/usr/local/syscheck"}

# Import common resources
. $SYSCHECK_HOME/resources.sh

PATH=$SYSCHECK_HOME:$PATH

export PATH 



if [ "x$1" = "xall" -o "x$1" = "x" ] ; then

	for file in ${SYSCHECK_HOME}/scripts-enabled/sc_* ; do
		$file
	done

else
	if [ -f ${SYSCHECK_HOME}/scripts-enabled/$1 ] ; then
		${SYSCHECK_HOME}/scripts-enabled/$1
	elif [ -f ${SYSCHECK_HOME}/$1 ] ; then
		# called with script-enable/sc_0x_foo.sh
                ${SYSCHECK_HOME}/$1
	else
		echo "cant find $1";
		echo "maybe it is in scripts-available, but not in scripts-enabled?"
		exit 1
	fi
fi
