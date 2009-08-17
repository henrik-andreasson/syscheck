#!/bin/sh

checkpid(){
	the_pid=$1

	ps h -o user,pid,args --pid $the_pid | grep -v grep | grep -v proc_checker.sh
}
checkPidByName(){
	the_name=$1
	ps -ef | egrep $the_name  | grep -v grep | grep -v proc_checker.sh
}

if [ -f $1 ] ; then
	pid_from_file=`cat $1` 
	if [ $? -ne 0 ] ; then
		echo "FAILED" >&2
		exit -1
	else
		checkpid $pid_from_file
	fi

elif [ `${SYSCHECK_HOME}/lib/isdigit.pl $1 ` ] ; then
	checkpid $1

elif [ "x$2" != "x" ] ; then
	procname=$2
	checkPidByName $procname

else
	echo "$0 <pid-file>|<pid> <procname>"
	echo "example: $0 /var/run/syslogd.pid syslogd"
	echo "example: $0 1234 syslogd"
	exit
fi


