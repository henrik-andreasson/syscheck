#!/bin/bash

SYSCHECK_HOME=${SYSCHECK_HOME:-"/usr/local/syscheck"}

# Import common resources
. $SYSCHECK_HOME/resources.sh

## local definitions ##
SCRIPTID=916

getlangfiles $SCRIPTID

FileName[0]="/home/logtest/log/message.*"
ToServer0[0]="sles10-1"
ToServer1[0]="sles10-2"
ToUser[0]='logtest'
ToServerDir[0]="/home/logtest/log-backup/${ToServer[0]}/"


### end config ###


ERRNO_1=${SCRIPTID}1
ERRNO_2=${SCRIPTID}2
ERRNO_3=${SCRIPTID}3




if [ "x$1" = "x--help" ] ; then
        echo "$0 <-s|--screen>"
        exit
elif [ "x$1" = "x-s" -o  "x$1" = "x--screen"  ] ; then
    PRINTTOSCREEN=1
fi 


for (( i=0; i < ${#FileName[@]} ; i++ )){

	$SYSCHECK_HOME/related-available/914_archive_file.sh --keep-org "${FileName[$i]}" ${ToServer0[$i]} ${ToServerDir[$i]} ${ToUser[$i]}
	if [ $? != 0 ] ; then
		printlogmess $ERROR $ERRNO_2 "$AMLB_DESCR_2" ${FileName[$i]} "${ToServer0[$i]} ${ToServerDir[$i]}" 
	else
		printlogmess $INFO $ERRNO_1 "$AMLB_DESCR_1" ${FileName[$i]} "${ToServer0[$i]} ${ToServerDir[$i]}"
	fi

	$SYSCHECK_HOME/related-available/914_archive_file.sh "${FileName[$i]}" ${ToServer1[$i]} ${ToServerDir[$i]} ${ToUser[$i]}
	if [ $? != 0 ] ; then
		printlogmess $ERROR $ERRNO_2 "$AMLB_DESCR_2" ${FileName[$i]} "${ToServer1[$i]} ${ToServerDir[$i]}" 
	else
		printlogmess $INFO $ERRNO_1 "$AMLB_DESCR_1" ${FileName[$i]} "${ToServer1[$i]} ${ToServerDir[$i]}"
	fi

}

