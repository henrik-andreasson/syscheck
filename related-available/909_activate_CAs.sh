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
SCRIPTNAME=activate_ca

# uniq ID of script (please use in the name of this file also for convinice for finding next availavle number)
SCRIPTID=909

# how many info/warn/error messages
NO_OF_ERR=2
initscript $SCRIPTID $NO_OF_ERR


# get command line arguments
INPUTARGS=`/usr/bin/getopt --options "hsv" --long "help,screen,verbose" -- "$@"`
if [ $? != 0 ] ; then schelp ; fi
#echo "TEMP: >$TEMP<"
eval set -- "$INPUTARGS"

while true; do
  case "$1" in
    -s|--screen  ) PRINTTOSCREEN=1; shift;;
    -v|--verbose ) PRINTVERBOSESCREEN=1 ; shift;;
    -h|--help )   schelp;exit;shift;;
    --) break;;
  esac
done


# main part of script


cd $EJBCA_HOME
for (( i = 0 ;  i < ${#CANAME[@]} ; i++ )) ; do
        NAME=${CANAME[$i]}
        PIN=${CAPIN[$i]}

        if [ "x${PIN}" = "x" ] ; then
                printtoscreen "Activating CA: $NAME, no PIN in config will prompt for it"
        else
                printtoscreen "Activating CA: $NAME (./bin/ejbca.sh ca activateca $NAME )"
        fi

        SCRIPTINDEX=$(addOneToIndex $SCRIPTINDEX)
        ./bin/ejbca.sh ca activateca $NAME $PIN | tee ${SYSCHECK_HOME}/var/$0.output
        error=$(grep -v "Enter authorization code:" ${SYSCHECK_HOME}/var/$0.output)
        if [ "x$error" = "x"  ] ; then
            printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX} $INFO ${ERRNO[1]} "${DESCR[1]}" "$NAME"
        else
            printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[2]} -d "${DESCR[2]}" -1 "$NAME" "$error"

        fi
        echo " --- "

done
