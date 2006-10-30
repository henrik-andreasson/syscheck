#!/bin/sh

# Set default home if not already set.
#if [ -n $SYSCHECK_HOME ]
#then
#  export SYSCHECK_HOME=/usr/local/syscheck
#fi

SYSCHECK_HOME=${SYSCHECK_HOME:-"/usr/local/syscheck"}


PRINTTOSCREEN="TRUE"
export PRINTTOSCREEN

. $SYSCHECK_HOME/resources.sh
$SYSCHECK_HOME/systemcheck.sh $*
