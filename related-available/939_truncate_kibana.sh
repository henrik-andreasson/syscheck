#!/bin/bash

# Set SYSCHECK_HOME if not already set.

# 1. First check if SYSCHECK_HOME is set then use that
if [ "x${SYSCHECK_HOME}" = "x" ] ; then
# 2. Check if /etc/syscheck.conf exists then source that (put SYSCHECK_HOME=/path/to/syscheck in ther)
    if [ -e /etc/syscheck.conf ] ; then 
	source /etc/syscheck.conf 
    else
# 3. last resort use default path
	SYSCHECK_HOME="/opt/syscheck"
    fi
fi

if [ ! -f ${SYSCHECK_HOME}/syscheck.sh ] ; then echo "$0: Can't find syscheck.sh in SYSCHECK_HOME ($SYSCHECK_HOME)" ;exit ; fi





## Import common definitions ##
. $SYSCHECK_HOME/config/related-scripts.conf

# uniq ID of script (please use in the name of this file also for convinice for finding next availavle number)
SCRIPTID=939
# how many info/warn/error messages
NO_OF_ERR=2
initscript $SCRIPTID $NO_OF_ERR


# Index is used to uniquely identify one test done by the script (a harddrive, crl or cert)
SCRIPTINDEX=00

getlangfiles $SCRIPTID 
getconfig $SCRIPTID


PRINTTOSCREEN=
if [ "x$1" = "x-h" -o "x$1" = "x--help" ] ; then
	echo "$CLEANBAK_HELP"
	echo "$ERRNO_1/$CLEANBAK_DESCR_1 - $CLEANBAK_HELP_1"
	echo "$ERRNO_2/$CLEANBAK_DESCR_2 - $CLEANBAK_HELP_2"
	echo "${SCREEN_HELP}"
	exit
elif [ "x$1" = "x-s" -o  "x$1" = "x--screen" -o \
    "x$2" = "x-s" -o  "x$2" = "x--screen"   ] ; then
    PRINTTOSCREEN=1
    shift
fi 

#curl -XDELETE http://localhost:9200/*$(date  --date="6 days ago" "+%Y.%m.%d")*

ERR=""
# loop throug all files to be removed due to age
for (( i = 0 ;  i < ${#INDEX[@]} ; i++ )) ; do
    CLEAN_DATE=$(date --date="${KEEPDAYS[$i]} days ago" "+%Y.%m")
    #CLEAN_DATE=$(date --date="${KEEPDAYS[$i]} days ago" "+%Y.%m.%d")
    printtoscreen "truncate ${INDEX[$i]} ${CLEAN_DATE} ago... "  

    SCRIPTINDEX=$(addOneToIndex $SCRIPTINDEX)

    #echo ${INDEX[$i]} ${CLEAN_DATE}
    truncate=$(curl -XDELETE http://$HOSTNAME:${PORT}/${INDEX[$i]}-$(date --date="${KEEPDAYS[$i]} days ago" "+%Y.%m.%d") 2>/tmp/error.txt)
    if [ $? != 0 ];then
    cat /tmp/error.txt
           printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   $WARN $ERRNO_2 "$CLEANBAK_DESCR_2" "$truncate"
echo $truncate
    else
    if [ ${truncate} = '{"acknowledged":true}' ];then
	    printtoscreen "deleted ${INDEX[$i]} ok"  
	else
	    printtoscreen "deleted ${INDEX[$i]} failed to truncate  ${INDEX[$i]}-${CLEAN_DATE}"  
	fi

#    else

#        printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   $INFO $ERRNO_3 "$CLEANBAK_DESCR_3" "${INDEX[$i]}"
#        printtoscreen "file ${INDEX[$i]} did not exist before deleting "  
	    
    fi
	
done

SCRIPTINDEX=$(addOneToIndex $SCRIPTINDEX)
if [ "x$ERR" = "x" ]  ; then
    printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   $INFO $ERRNO_1 "$CLEANBAK_DESCR_1"
else
    printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   $WARN $ERRNO_2 "$CLEANBAK_DESCR_2" "$ERR"
fi
