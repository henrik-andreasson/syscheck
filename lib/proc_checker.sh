#!/bin/bash

isdigit(){
	case $1 in
    ''|*[!0-9]*) return 1 ;;
		*)           return 0 ;;
	esac

}


checkpid(){
	the_pid=$1

	ps h -o user,pid,args --pid $the_pid | grep -v grep | grep -v proc_checker.sh
}
checkPidByName(){
	the_name=$1
	ps -ef | egrep $the_name  | grep -v grep | grep -v proc_checker.sh
}

proc_checker_help() {
	echo "$0 <pid-file>|<pid> <procname>"
	echo "example: $0 /var/run/syslogd.pid syslogd"
	echo "example: $0 1234 syslogd"
	exit
}

if [ "x$1" == "x" ] ; then
	proc_checker_help

elif [ -f $1 ] ; then
	pid_from_file=$(cat $1)
	if [ $? -ne 0 ] ; then
		echo "FAILED" >&2
		exit -1
	else
		checkpid $pid_from_file
	fi


elif [ $(isdigit $1) ] ; then
	checkpid $1

elif [ "x$2" != "x" ] ; then
	procname=$2
	checkPidByName $procname

else
	proc_checker_help
fi
