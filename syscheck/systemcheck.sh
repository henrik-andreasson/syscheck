#!/bin/sh

# Set default home if not already set.
SYSCHECK_HOME=${SYSCHECK_HOME:-"/usr/local/syscheck"}

# Import common resources
. $SYSCHECK_HOME/resources.sh

PATH=$SYSCHECK_HOME:$PATH

export PATH

if [ "x$1" = "xall" ] ; then

	for file in ${SYSCHECK_HOME}/sc_* ; do
		$file
	done

else
	if [ -f $1 ] ; then
		$*
	elif [ -f ${scpath}/$1 ] ; then
		${scpath}/$1
	elif [ -f sc_${1} ] ; then
		sc_${1}
	elif [ -f ${scpath}/ov_$1 ] ; then
		${scpath}/ov_$1
	else
		echo "cant find $1";
		exit 1
	fi
fi
