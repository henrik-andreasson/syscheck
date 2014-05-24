#!/bin/bash 
procname=/usr/local/mysql/libexec/ndbd
status=0




# Import common resources
. $SYSCHECK_HOME/config/common.conf

pid=`ps -ef | grep $procname | grep -v grep | awk '{print $2}'` 

if [ "x$pid" = "x" ] ; then
	printlogmess $NDBD_LEVEL_2 $NDBD_ERRNO_2 "$NDBD_DESCR_2"  
else
	printlogmess $NDBD_LEVEL_1 $NDBD_ERRNO_1 "$NDBD_DESCR_1"
fi

