#!/bin/bash

script=$1

. /etc/syscheck.conf

cd $SYSCHECK_HOME/scripts-enabled 

if [ -f ../scripts-available/$script ] ; then
	ln -sf ../scripts-available/$script .
else
	echo "no such script" >&2
	exit 1
fi


