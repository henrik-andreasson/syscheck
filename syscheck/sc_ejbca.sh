#!/bin/bash

# Set default home if not already set.
SYSCHECK_HOME=${SYSCHECK_HOME:-"/usr/local/syscheck"}

# Import common resources
. $SYSCHECK_HOME/resources.sh

OUTPUT='/tmp/ejbcahealth.log'
EJBCAHEALTHLOG='/tmp/ejbcahealth'
cd /tmp
wget http://$EJBCA_HOSTNAME:8080/ejbca/publicweb/healthcheck/ejbcahealth -T 10 -t 1 -o $OUTPUT

ERRORCATOUTPUT=`cat $OUTPUT | grep ERROR`
ERRORECHOOUTPUT=`echo $ERRORCATOUTPUT`

if [ -f $EJBCAHEALTHLOG ]; then
        OKCATOUTPUT=`cat $EJBCAHEALTHLOG | grep ALLOK`
        OKECHOOUTPUT=`echo $OKCATOUTPUT`
fi

if [ "$OKECHOOUTPUT" = ALLOK ]; then
       printlogmess $ECA_LEVEL_1 $ECA_ERRNO_1 "$ECA_DESCR_1" "$OKECHOOUTPUT"
else
   if [ "$ERRORECHOOUTPUT" = "" ]; then 
       printlogmess $ECA_LEVEL_3 $ECA_ERRNO_3 "$ECA_DESCR_3" 
     else
       printlogmess $ECA_LEVEL_2 $ECA_ERRNO_2 "$ECA_DESCR_2"  "$ERRORECHOOUTPUT"
   fi 
fi

if [ -f $EJBCAHEALTHLOG ]; then
        rm $EJBCAHEALTHLOG
fi

rm $OUTPUT

