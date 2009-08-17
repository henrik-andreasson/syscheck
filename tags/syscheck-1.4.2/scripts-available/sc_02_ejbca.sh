#!/bin/bash

# Set default home if not already set.
SYSCHECK_HOME=${SYSCHECK_HOME:-"/usr/local/syscheck"}

## Import common definitions ##
. $SYSCHECK_HOME/resources.sh

# uniq ID of script (please use in the name of this file also for convinice for finding next availavle number)
SCRIPTID=02

getlangfiles $SCRIPTID
getconfig $SCRIPTID

ERRNO_1=${SCRIPTID}01
ERRNO_2=${SCRIPTID}02
ERRNO_3=${SCRIPTID}03

if [ "x$1" = "x-h" -o "x$1" = "x--help" ] ; then
	echo "$ECA_HELP"
	echo "$ERRNO_1/$ECA_DESCR_1 - $ECA_HELP_1"
	echo "$ERRNO_2/$ECA_DESCR_2 - $ECA_HELP_2"
	echo "$ERRNO_3/$ECA_DESCR_3 - $ECA_HELP_3"
	echo "${SCREEN_HELP}"
	exit
elif [ "x$1" = "x-s" -o  "x$1" = "x--screen"  ] ; then
    PRINTTOSCREEN=1
fi 

OUTPUT='/tmp/ejbcahealth.log'
EJBCAHEALTHLOG='/tmp/ejbcahealth'
cd /tmp
wget http://$EJBCA_HOSTNAME:8080/ejbca/publicweb/healthcheck/ejbcahealth -T 10 -t 1 -o $OUTPUT 2>/dev/null

ERRORCATOUTPUT=`cat $OUTPUT | grep ERROR`
ERRORECHOOUTPUT=`echo $ERRORCATOUTPUT`

if [ -f $EJBCAHEALTHLOG ]; then
        OKCATOUTPUT=`cat $EJBCAHEALTHLOG | grep ALLOK`
        OKECHOOUTPUT=`echo $OKCATOUTPUT`
fi

if [ "$OKECHOOUTPUT" = ALLOK ]; then
       printlogmess $INFO $ERRNO_1 "$ECA_DESCR_1" "$OKECHOOUTPUT"
else
   if [ "$ERRORECHOOUTPUT" = "" ]; then 
       printlogmess $ERROR $ERRNO_3 "$ECA_DESCR_3" 
     else
       printlogmess $ERROR $ERRNO_2 "$ECA_DESCR_2"  "$ERRORECHOOUTPUT"
   fi 
fi

if [ -f $EJBCAHEALTHLOG ]; then
        rm $EJBCAHEALTHLOG
fi

rm $OUTPUT

