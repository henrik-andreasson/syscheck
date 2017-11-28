#!/bin/bash

# Set SYSCHECK_HOME if not already set.

# 1. First check if SYSCHECK_HOME is set then use that
if [ "x${SYSCHECK_HOME}" = "x" ] ; then
# 2. Check if /etc/syscheck.conf exists then source that (put SYSCHECK_HOME=/path/to/syscheck in ther)
    if [ -e /etc/syscheck.conf ] ; then 
	source /etc/syscheck.conf 
    else
# 3. last resort use default path
	SYSCHECK_HOME="/usr/local/syscheck"
    fi
fi

if [ ! -f ${SYSCHECK_HOME}/syscheck.sh ] ; then echo "$0: Can't find syscheck.sh in SYSCHECK_HOME ($SYSCHECK_HOME)" ;exit ; fi





## Import common definitions ##
. $SYSCHECK_HOME/config/related-scripts.conf

# uniq ID of script (please use in the name of this file also for convinice for finding next availavle number)
SCRIPTID=908

# Index is used to uniquely identify one test done by the script (a harddrive, crl or cert)
SCRIPTINDEX=00

getlangfiles $SCRIPTID 
getconfig $SCRIPTID


ERRNO_1="${SCRIPTID}1"
ERRNO_2="${SCRIPTID}2"
ERRNO_3="${SCRIPTID}3"
ERRNO_4="${SCRIPTID}4"




PRINTTOSCREEN=
if [ "x$1" = "x-h" -o "x$1" = "x--help" ] ; then
	echo "$CLEANBAK_HELP"
	echo "$ERRNO_1/$CLEANBAK_DESCR_1 - $CLEANBAK_HELP_1"
	echo "$ERRNO_2/$CLEANBAK_DESCR_2 - $CLEANBAK_HELP_2"
	echo "$ERRNO_3/$CLEANBAK_DESCR_3 - $CLEANBAK_HELP_3"
	echo "$ERRNO_4/$CLEANBAK_DESCR_4 - $CLEANBAK_HELP_4"
	echo "${SCREEN_HELP}"
	exit
elif [ "x$1" = "x-s" -o  "x$1" = "x--screen" -o \
    "x$2" = "x-s" -o  "x$2" = "x--screen"   ] ; then
    PRINTTOSCREEN=1
    shift
fi 



ERR=""
# loop throug all files to be removed due to age
for (( i = 0 ;  i < ${#FILENAME[@]} ; i++ )) ; do
    printtoscreen "deleteing ${FILENAME[$i]} ... "  

    SCRIPTINDEX=$(addOneToIndex $SCRIPTINDEX)

    if [ "x${DATESTR[$i]}" = "x" ] ; then
    	printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   $ERROR $ERRNO_4 "$CLEANBAK_DESCR_4"
	exit
    fi

    realfiles=$(ls ${FILENAME[$i]} 2>/dev/null)
    if [ "x${realfiles}" != "x" ] ; then 

	returnstr=`rm ${FILENAME[$i]} 2>&1`
	if [ $? -ne 0 ] ; then 
	    ERR=" ${FILENAME[$i]} ; $ERR"
	    printtoscreen "deleted ${realfiles} failed ($returnstr)"  
	else
	    printtoscreen "deleted ${realfiles} ok"  
	fi

    else

        printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   $INFO $ERRNO_3 "$CLEANBAK_DESCR_3" "${FILENAME[$i]}"
        printtoscreen "file ${FILENAME[$i]} did not exist before deleting "  
	    
    fi
	
done

SCRIPTINDEX=$(addOneToIndex $SCRIPTINDEX)
if [ "x$ERR" = "x" ]  ; then
    printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   $INFO $ERRNO_1 "$CLEANBAK_DESCR_1"
else
    printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   $WARN $ERRNO_2 "$CLEANBAK_DESCR_2" "$ERR"
fi
