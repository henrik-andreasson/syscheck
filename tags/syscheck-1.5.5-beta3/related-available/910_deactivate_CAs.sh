#!/bin/sh

# Set default home if not already set.
SYSCHECK_HOME=${SYSCHECK_HOME:-"/usr/local/syscheck"}

## Import common definitions ##
. $SYSCHECK_HOME/resources.sh

# uniq ID of script (please use in the name of this file also for convinice for finding next availavle number)
SCRIPTID=910

getlangfiles $SCRIPTID
getconfig $SCRIPTID

ERRNO_1="${SCRIPTID}1"
ERRNO_2="${SCRIPTID}2"
ERRNO_3="${SCRIPTID}3"

PRINTTOSCREEN=
if [ "x$1" = "x-h" -o "x$1" = "x--help" ] ; then
    echo "$DEACT_HELP"
    echo "$ERRNO_1/$DEACT_DESCR_1 - $DEACT_HELP_1"
    echo "$ERRNO_2/$DEACT_DESCR_2 - $DEACT_HELP_2"
    echo "$ERRNO_3/$DEACT_DESCR_3 - $DEACT_HELP_3"
    echo "${SCREEN_HELP}"
    exit
elif [ "x$1" = "x-s" -o  "x$1" = "x--screen" -o \
    "x$2" = "x-s" -o  "x$2" = "x--screen"   ] ; then
    PRINTTOSCREEN=1
    shift
fi 


cd $EJBCA_HOME
for (( i = 0 ;  i < ${#CANAME[@]} ; i++ )) ; do

	printtoscreen "Deactivating CA :  ${CANAME[$i]} on node $HOSTNAME_NODE2"
	returncode=`bin/ejbca.sh ca deactivateca ${CANAME[$i]} `
	if [ $? -eq 0 ] ; then
	    printlogmess $INFO $ERRNO_1 "$DEACT_DESCR_1" "$NAME" 
	else
	    printlogmess $ERROR $ERRNO_2 "$DEACT_DESCR_2" "$NAME" 
	fi


done

