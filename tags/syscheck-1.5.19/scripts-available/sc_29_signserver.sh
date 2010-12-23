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
. $SYSCHECK_HOME/config/syscheck-scripts.conf

# uniq ID of script (please use in the name of this file also for convinice for finding next availavle number)
SCRIPTID=29

getlangfiles $SCRIPTID
getconfig $SCRIPTID

ERRNO_1=${SCRIPTID}01
ERRNO_2=${SCRIPTID}02
ERRNO_3=${SCRIPTID}03

if [ "x$1" = "x-h" -o "x$1" = "x--help" ] ; then
	echo "$SIGNSRV_HELP"
	echo "$ERRNO_1/$SIGNSRV_DESCR_1 - $SIGNSRV_HELP_1"
	echo "$ERRNO_2/$SIGNSRV_DESCR_2 - $SIGNSRV_HELP_2"
	echo "$ERRNO_3/$SIGNSRV_DESCR_3 - $SIGNSRV_HELP_3"
	echo "${SCREEN_HELP}"
	exit
elif [ "x$1" = "x-s" -o  "x$1" = "x--screen"  ] ; then
    PRINTTOSCREEN=1
fi 

OUTPUT='/tmp/signserverhealth.log'
SIGNSERVERHEALTHLOG='/tmp/signserverhealth'
cd /tmp
wget http://$SIGNSERVER_HOSTNAME:8080/signserver/healthcheck/signserverhealth -T 10 -t 1 -o $OUTPUT 2>/dev/null

ERRORCATOUTPUT=`cat $OUTPUT | grep ERROR`
ERRORECHOOUTPUT=`echo $ERRORCATOUTPUT`

if [ -f $SIGNSERVERHEALTHLOG ]; then
        OKCATOUTPUT=`cat $SIGNSERVERHEALTHLOG | grep ALLOK`
        OKECHOOUTPUT=`echo $OKCATOUTPUT`
fi

if [ "$OKECHOOUTPUT" = ALLOK ]; then
       printlogmess $INFO $ERRNO_1 "$SIGNSRV_DESCR_1" "$OKECHOOUTPUT"
else
   if [ "$ERRORECHOOUTPUT" = "" ]; then 
       printlogmess $ERROR $ERRNO_3 "$SIGNSRV_DESCR_3" 
     else
       printlogmess $ERROR $ERRNO_2 "$SIGNSRV_DESCR_2"  "$ERRORECHOOUTPUT"
   fi 
fi

if [ -f $SIGNSERVERHEALTHLOG ]; then
        rm $SIGNSERVERHEALTHLOG
fi

rm $OUTPUT

