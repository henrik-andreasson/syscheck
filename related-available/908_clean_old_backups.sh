#!/bin/bash

SYSCHECK_HOME="${SYSCHECK_HOME:-/opt/syscheck}" # use default if  unset
if [ ! -f ${SYSCHECK_HOME}/syscheck.sh ] ; then
  echo "Can't find $SYSCHECK_HOME/syscheck.sh"
  exit
fi

if [ ! -f ${SYSCHECK_HOME}/syscheck.sh ] ; then echo "Can't find $SYSCHECK_HOME/syscheck.sh" ;exit ; fi

# Import common resources
source $SYSCHECK_HOME/config/related-scripts.conf

# script name, used when integrating with nagios/icinga
SCRIPTNAME=clean_old_db_backups

# uniq ID of script (please use in the name of this file also for convinice for finding next availavle number)
SCRIPTID=908

# how many info/warn/error messages
NO_OF_ERR=4
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

ERR=""
# loop throug all files to be removed due to age
for (( i = 0 ;  i < ${#FILENAME[@]} ; i++ )) ; do
    printtoscreen "deleteing ${FILENAME[$i]} ... "

    SCRIPTINDEX=$(addOneToIndex $SCRIPTINDEX)

    if [ "x${DATESTR[$i]}" = "x" ] ; then
    	printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX}  $ERROR ${ERRNO[4]} "$CLEANBAK_DESCR[4]"
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

        printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX}  $INFO ${ERRNO[3]} "$CLEANBAK_DESCR[3]" "${FILENAME[$i]}"
        printtoscreen "file ${FILENAME[$i]} did not exist before deleting "

    fi

done

SCRIPTINDEX=$(addOneToIndex $SCRIPTINDEX)
if [ "x$ERR" = "x" ]  ; then
    printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX}  $INFO ${ERRNO[1]} "$CLEANBAK_DESCR[1]"
else
    printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX}  $WARN ${ERRNO[2]} "$CLEANBAK_DESCR[2]" "$ERR"
fi
