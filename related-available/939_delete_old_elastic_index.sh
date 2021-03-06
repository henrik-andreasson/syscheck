#!/bin/bash

SYSCHECK_HOME="${SYSCHECK_HOME:-/opt/syscheck}" # use default if  unset
if [ ! -f ${SYSCHECK_HOME}/syscheck.sh ] ; then
  echo "Can't find $SYSCHECK_HOME/syscheck.sh"
  exit
fi

if [ ! -f ${SYSCHECK_HOME}/syscheck.sh ] ; then echo "Can't find $SYSCHECK_HOME/syscheck.sh" ;exit ; fi

## Import common definitions ##
source $SYSCHECK_HOME/config/related-scripts.conf

# script name, used when integrating with nagios/icinga
SCRIPTNAME=delete_old_elastic_index

# uniq ID of script (please use in the name of this file also for convinice for finding next availavle number)
SCRIPTID=939

# how many info/warn/error messages
NO_OF_ERR=2
initscript $SCRIPTID $NO_OF_ERR

default_script_getopt $*

# main part of script

ERR=""
errors=0
# loop throug all index to be removed due to age
for (( i = 0 ;  i < ${#INDEX[@]} ; i++ )) ; do
    CLEAN_DATE=$(date --date="${KEEPDAYS[$i]} days ago" "+%Y.%m.%d")
    printtoscreen "truncate ${INDEX[$i]} ${CLEAN_DATE} ago... "

    SCRIPTINDEX=$(addOneToIndex $SCRIPTINDEX)

    outputfile=$(mktemp)
    truncate=$(curl -XDELETE http://${ELASTIC_HOST}:${ELASTIC_PORT}/${INDEX[$i]}-${CLEAN_DATE} 2>$outputfile)
    if [ $? != 0 -a ${truncate} = '{"acknowledged":true}' ];then
	       printtoscreen "deleted ${INDEX[$i]} ok"
    else
        let err++
        THIS_ERR=$(cat $outputfile)
        ERR="${ERR};${THIS_ERR}"
	      printtoscreen "deleted ${INDEX[$i]} failed to truncate ${INDEX[$i]}-${CLEAN_DATE} ${THIS_ERR}"
    fi

done

SCRIPTINDEX=$(addOneToIndex $SCRIPTINDEX)
if [ $errors -gt 0 ]  ; then
  printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $INFO -e ${ERRNO[1]} -d "${DESCR[1]}"
else
  printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[2]} -d "${DESCR[2]}"
fi
