#!/bin/bash

SYSCHECK_HOME=${SYSCHECK_HOME:-"/usr/local/syscheck"}

# Import common resources
. $SYSCHECK_HOME/resources.sh

## local definitions ##
SCRIPTID=916

getlangfiles $SCRIPTID
getconfig $SCRIPTID

ERRNO_1=${SCRIPTID}1
ERRNO_2=${SCRIPTID}2
ERRNO_3=${SCRIPTID}3

if [ "x$1" = "x--help" ] ; then
        echo "$0 <-s|--screen>"
	echo "$AMLB_HELP"
        echo "$ERRNO_1/$AMLB_DESCR_1 - $AMLB_HELP_1"
        echo "$ERRNO_2/$AMLB_DESCR_2 - $AMLB_HELP_2"

        exit
elif [ "x$1" = "x-s" -o  "x$1" = "x--screen"  ] ; then
    PRINTTOSCREEN=1
fi 


for (( i=0; i < ${#FileName[@]} ; i++ )){
#for file in ${#FileName[@]} ; do
   files=$(ls ${FileName[$i]} 2>/dev/null)
   printtoscreen "Will loop over these files: ${files}"
   for fn in ${files} ; do
	KEEPORG=	
	if [ "x${ToServer1[$i]}" != "x" ] ; then
		KEEPORG=--keep-org
	fi
	if [ "x${ToServer0[$i]}" != "x" ] ; then
		printtoscreen $SYSCHECK_HOME/related-available/917_archive_file.sh ${KEEPORG} "${fn}" ${ToServer0[$i]} ${ToServerDir[$i]} ${ToUser[$i]}
		$SYSCHECK_HOME/related-available/917_archive_file.sh ${KEEPORG} "${fn}" ${ToServer0[$i]} ${ToServerDir[$i]} ${ToUser[$i]}
		if [ $? != 0 ] ; then
			printlogmess $ERROR $ERRNO_2 "$AMLB_DESCR_2" "${fn}" "${ToServerDir[$i]}" 
		else
			printlogmess $INFO $ERRNO_1 "$AMLB_DESCR_1" "${fn}" "${ToServerDir[$i]}"
		fi
	fi

	if [ "x${ToServer1[$i]}" != "x" ] ; then
		printtoscreen $SYSCHECK_HOME/related-available/917_archive_file.sh "${fn}" ${ToServer1[$i]} ${ToServerDir[$i]} ${ToUser[$i]}
		$SYSCHECK_HOME/related-available/917_archive_file.sh "${fn}" ${ToServer1[$i]} ${ToServerDir[$i]} ${ToUser[$i]}
		if [ $? != 0 ] ; then
			printlogmess $ERROR $ERRNO_2 "$AMLB_DESCR_2" "${fn}" "${ToServerDir[$i]}" 
		else
			printlogmess $INFO $ERRNO_1 "$AMLB_DESCR_1" "${fn}" "${ToServerDir[$i]}"
		fi
	fi
 done
}

