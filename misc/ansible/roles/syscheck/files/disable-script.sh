#!/bin/bash

script=$1

. /etc/syscheck.conf

cd $SYSCHECK_HOME/scripts-enabled 

if [ -f ../scripts-avilabe/$script ] ; then
	rm -f ../scripts-avilabe/$script 
else
	echo "not enabled ($script)" >&2
	exit 0
fi


