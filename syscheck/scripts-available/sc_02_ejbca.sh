#!/bin/bash

# Set default home if not already set.
SYSCHECK_HOME=${SYSCHECK_HOME:-"/usr/local/syscheck"}

## Import common definitions ##
. $SYSCHECK_HOME/resources.sh

## Local definitions ##
#Hostname to check, default (localhost)
EJBCA_HOSTNAME=localhost



# uniq ID of script (please use in the name of this file also for convinice for finding next availavle number)
SCRIPTID=02

ECA_ERRNO_1=${SCRIPTID}01
ECA_ERRNO_2=${SCRIPTID}02
ECA_ERRNO_3=${SCRIPTID}04

PRINTTOSCREEN=0
if [ "x$1" = "x-h" -o "x$1" = "x--help" ] ; then
	echo "Script that connects to the ejbca health check servlet to check"
	echo "the status of the ejbca application. The health check servlet"
	echo "checks JVM memory, database connection and HSM connection."
	echo 
	echo "Possible status codes:"
	echo "$ECA_ERRNO_1/$ECA_DESCR_1 - connected to ejbca heathcheck and status is OK"
	echo 
	echo "$ECA_ERRNO_2/$ECA_DESCR_2 - connected to ejbca heathcheck and status is FAILED with description at '%s' "
	echo 
	echo "$ECA_ERRNO_3/$ECA_DESCR_3 - cant connect to the ejbca server at all"
	echo " Suggested action: check j2ee-server (eg. jboss) log, and process"
	echo 
	echo "to run with output directed to screen:"
	echo "$0 <-s|--screen>"
	exit
elif [ "x$1" = "x-s" -o  "x$1" = "x--screen"  ] ; then
    PRINTTOSCREEN=1
fi 

printtoscreen() {

  IFS=$'\n'

  if [ $PRINTTOSCREEN -eq 1 ] ; then 
	echo "Screenonly output:"
	echo $*
  fi
}

OUTPUT='/tmp/ejbcahealth.log'
EJBCAHEALTHLOG='/tmp/ejbcahealth'
cd /tmp
wget http://$EJBCA_HOSTNAME:8080/ejbca/publicweb/healthcheck/ejbcahealth -T 10 -t 1 -o $OUTPUT
printtoscreen `cat $OUTPUT `

ERRORCATOUTPUT=`cat $OUTPUT | grep ERROR`
ERRORECHOOUTPUT=`echo $ERRORCATOUTPUT`

if [ -f $EJBCAHEALTHLOG ]; then
        OKCATOUTPUT=`cat $EJBCAHEALTHLOG | grep ALLOK`
        OKECHOOUTPUT=`echo $OKCATOUTPUT`
fi

if [ "$OKECHOOUTPUT" = ALLOK ]; then
       printlogmess $INFO $ECA_ERRNO_1 "$ECA_DESCR_1" "$OKECHOOUTPUT"
else
   if [ "$ERRORECHOOUTPUT" = "" ]; then 
       printlogmess $ERROR $ECA_ERRNO_3 "$ECA_DESCR_3" 
     else
       printlogmess $ERROR $ECA_ERRNO_2 "$ECA_DESCR_2"  "$ERRORECHOOUTPUT"
   fi 
fi

if [ -f $EJBCAHEALTHLOG ]; then
        rm $EJBCAHEALTHLOG
fi

rm $OUTPUT

