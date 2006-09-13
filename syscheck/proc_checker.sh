#!/bin/sh

checkpid(){
	the_pid=$1

	ps h -o user,pid,args --pid $the_pid
}

if [ -f $1 ] ; then
	check_this_pid=`cat $1` 
elif [ $1 -gt 0 ] ; then
	check_this_pid=$1
else
	echo "$0 <PID|pid-file>"
	echo "example: $0 1233"
	echo "example: $0 /var/run/syslogd.pid"
	exit
fi

checkpid $check_this_pid

