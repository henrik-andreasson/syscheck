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
SCRIPTNAME=server_alive

# uniq ID of script (please use in the name of this file also for convinice for finding next availavle number)
SCRIPTID=918

# how many info/warn/error messages
NO_OF_ERR=3
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

for (( i = 0 ;  i < ${#HOST[@]} ; i++ )) ; do

	LASTLOGTS=`grep -ni "1903.*${HOST[$i]}" ${LOGFILECURRENT} ${LOGFILELAST} | tail -1 |  awk '{print $7,$8}'`
	if [ "x$LASTLOGTS" != "x" ] ;then
		MINUTES_SINCE_LASTLOG=`${SYSCHECK_HOME}/lib/cmp_syslog_dates.pl "$LASTLOGTS" | awk '{print $1}'`

		if [ ${MINUTES_SINCE_LASTLOG} -gt ${TIME_BEFORE_ERROR} ] ; then
			printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX}  $ERROR ${ERRNO[2]} "$SCALIVE_SRV_DESCR[2]" ${HOST[$i]} ${MINUTES_SINCE_LASTLOG}
		elif [ ${MINUTES_SINCE_LASTLOG} -gt ${TIME_BEFORE_WARN} ] ; then
	    		printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX}  $WARN ${ERRNO[3]} "$SCALIVE_SRV_DESCR[3]" ${HOST[$i]} ${MINUTES_SINCE_LASTLOG}
		else
			printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX}  $INFO ${ERRNO[1]} "$SCALIVE_SRV_DESCR[1]" ${HOST[$i]} ${MINUTES_SINCE_LASTLOG}
		fi
	else
		printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX}  $ERROR ${ERRNO[2]} "$SCALIVE_SRV_DESCR[2]" ${HOST[$i]}
	fi


done
