#!/bin/sh


# Set default home if not already set.
SYSCHECK_HOME=${SYSCHECK_HOME:-"/usr/local/syscheck"}


## Import common definitions ##
. $SYSCHECK_HOME/resources.sh

# uniq ID of script (please use in the name of this file also for convinice for finding next availavle number)
SCRIPTID=908

getlangfiles $SCRIPTID 
getconfig $SCRIPTID


ERRNO_1="${SCRIPTID}1"
ERRNO_2="${SCRIPTID}2"
ERRNO_3="${SCRIPTID}3"




PRINTTOSCREEN=
if [ "x$1" = "x-h" -o "x$1" = "x--help" ] ; then
	echo "$ECRT_HELP"
	echo "$ERRNO_1/$ECRT_DESCR_1 - $ECRT_HELP_1"
	echo "$ERRNO_2/$ECRT_DESCR_2 - $ECRT_HELP_2"
	echo "$ERRNO_3/$ECRT_DESCR_3 - $ECRT_HELP_3"
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

    if [ -f  ${FILENAME[$i]} ] ; then 

	returnstr=`rm ${FILENAME[$i]} 2>&1`
	if [ $? -ne 0 ] ; then 
	    ERR=" ${FILENAME[$i]} ; $ERR"
	    printtoscreen "deleted ${FILENAME[$i]} failed ($returnstr)"  
	else
	    printtoscreen "deleted ${FILENAME[$i]} ok"  
	fi

    else

	printlogmess $WARN $ERRNO_3 "$CLEANBAK_DESCR_3" ${FILENAME[$i]}
	printtoscreen "file ${FILENAME[$i]} did not exist before deleting "  
	    
    fi
	
done

if [ "x$ERR" = "x" ]  ; then
    printlogmess $INFO $ERRNO_1 "$CLEANBAK_DESCR_1"
else
    printlogmess $WARN $ERRNO_2 "$CLEANBAK_DESCR_2" "$ERR"
fi