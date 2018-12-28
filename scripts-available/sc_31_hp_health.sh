#!/bin/bash

SYSCHECK_HOME="${SYSCHECK_HOME:-/opt/syscheck}" # use default if  unset
if [ ! -f ${SYSCHECK_HOME}/syscheck.sh ] ; then
  echo "Can't find $SYSCHECK_HOME/syscheck.sh"
  exit
fi

if [ ! -f ${SYSCHECK_HOME}/syscheck.sh ] ; then echo "Can't find $SYSCHECK_HOME/syscheck.sh" ;exit ; fi

## Import common definitions ##
source $SYSCHECK_HOME/config/syscheck-scripts.conf

# script name, used when integrating with nagios/icinga
SCRIPTNAME=hp_health

# uniq ID of script (please use in the name of this file also for convinice for finding next availavle number)
SCRIPTID=31

# how many info/warn/error messages
NO_OF_ERR=4
initscript $SCRIPTID $NO_OF_ERR

# get command line arguments
INPUTARGS=`/usr/bin/getopt --options "hsvc" --long "help,screen,verbose,cert" -- "$@"`
if [ $? != 0 ] ; then schelp ; fi
#echo "TEMP: >$TEMP<"
eval set -- "$INPUTARGS"

while true; do
  case "$1" in
    -s|--screen  ) PRINTTOSCREEN=1; shift;;
    -v|--verbose ) PRINTVERBOSESCREEN=1 ; shift;;
    -c|--cert )   CERTFILE=$2; shift 2;;
    -h|--help )   schelp;exit;shift;;
    --) break;;
  esac
done

# main part of script


hppsu () {
        COMMAND=`/bin/echo -e "show powersupply\nexit" | /sbin/hpasmcli | perl -ane 's/\n//,print'  | perl -ane 'm/Power supply #1.
*Present.*: (.*).*Condition:(.*).*Hotplug.*Power supply #2.*Present.*: (.*).*Condition:(.*).*Hotplug/,print "$1;$2;$3;$4\n"'`
        STATUSPSU1=`echo $COMMAND | cut -f1 -d\; |grep -i "yes"`
        CONDPSU1=`echo $COMMAND | cut -f2 -d\; |grep -i "ok"`
        STATUSPSU2=`echo $COMMAND | cut -f3 -d\; |grep -i "yes"`
        CONDPSU2=`echo $COMMAND | cut -f4 -d\; |grep -i "ok"`

	SCRIPTINDEX=$(addOneToIndex $SCRIPTINDEX)
        if [ "x$STATUSPSU1" != "x" -a "x$CONDPSU1" != "x" ] ; then
                printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   $INFO ${ERRNO[1]} "${DESCR[1]}" "PSU1"
        else
                printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   $ERROR ${ERRNO[2]} "${DESCR[2]}" "PSU1 $STATUSPSU1 $CONDPSU1"
        fi

	SCRIPTINDEX=$(addOneToIndex $SCRIPTINDEX)
        if [ "x$STATUSPSU2" != "x" -a "x$CONDPSU2" != "x" ] ; then
                printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   $INFO ${ERRNO[1]} "${DESCR[1]}" "PSU2"
        else
                printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   $ERROR ${ERRNO[2]} "${DESCR[2]}" "PSU2 $STATUSPSU2 $CONDPSU2"
        fi
}

hptemp () {
	for tempinput in $(/bin/echo -e "show temp\nexit" | /sbin/hpasmcli | grep ^# | perl  -ane 's/\s+/;/gio, print "$_\n"') ; do
##15;I/O_ZONE;33C/91F;70C/158F
	        TEMPNO=`echo $tempinput | cut -f1 -d\;`
	        TEMPNAME=`echo $tempinput | cut -f2 -d\;`
	        TEMPVAL=`echo $tempinput | cut -f3 -d\;   | perl -ane 'm/(.*)C\//gio,print "$1"'`
	        TEMPLIMIT=`echo $tempinput | cut -f4 -d\; | perl -ane 'm/(.*)C\//gio,print "$1"'`
                echo ${HPTEMP}|egrep -q "${TEMPNO} "
                 if [ $? != 0 ];then
			printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   $INFO ${ERRNO[1]} "${DESCR[1]}" "TEMP ${TEMPNO} ${TEMPNAME} is known not to give any reading ($tempinput)"
			#continue
		else


		if [ "x${TEMPVAL}" = "x" ] ; then
			printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   $ERROR ${ERRNO[2]} "${DESCR[2]}" "TEMP  ${TEMPNO} ${TEMPNAME} did not return any value for CURRENT temp ($tempinput)"
			continue
		fi

		if [ "x${TEMPLIMIT}" = "x" ] ; then
			printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   $ERROR ${ERRNO[2]} "${DESCR[2]}" "TEMP  ${TEMPNO} ${TEMPNAME} did not return any value for LIMIT temp ($tempinput)"
			continue
		fi

	        if [ ${TEMPVAL} -gt ${TEMPLIMIT} ] ; then
			printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   $ERROR ${ERRNO[2]} "${DESCR[2]}" "TEMP ${TEMPNO} ${TEMPNAME} Current: ${TEMPVAL} Limit: ${TEMPLIMIT} (celsius)"
	        else
			printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   $INFO ${ERRNO[1]} "${DESCR[1]}" "TEMP ${TEMPNO} ${TEMPNAME} Current: ${TEMPVAL} Limit: ${TEMPLIMIT} (celsius)"
		fi
                fi
	done
}

hpfans () {
	for fansinput in $(/bin/echo -e "show fans\nexit" | /sbin/hpasmcli | grep ^# | perl  -ane 's/\s+/;/gio, print "$_\n"') ; do
#Fan  Location        Present Speed  of max  Redundant  Partner  Hot-pluggable
##1;SYSTEM;Yes;NORMAL;29%;Yes;0;Yes;
	        FANNO=`echo $fansinput | cut -f1 -d\;`
	        FANLOC=`echo $fansinput | cut -f2 -d\;`
	        FANPRESENT=`echo $fansinput | cut -f3 -d\;`
	        FANSPEED=`echo $fansinput | cut -f4 -d\; `
	        FANPERCENT=`echo $fansinput | cut -f5 -d\;|sed 's/%//' `
		SCRIPTINDEX=$(addOneToIndex $SCRIPTINDEX)
                if [ $FANPRESENT = "No" ];then
			printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   $INFO ${ERRNO[1]} "${DESCR[1]}" "FAN ${FANNO} ${FANLOC} is not installed "
                else
	       		 if [ "x${FANSPEED}" !=  "xNORMAL" ] ; then
				printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   $ERROR ${ERRNO[3]} "${DESCR[3]}" "FAN(${FANNO}) NOT in normal operation (${FANSPEED}/${FANPERCENT}%%)"
	        	else
				printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   $INFO ${ERRNO[1]} "${DESCR[1]}" "FAN(${FANNO}) IS in normal operation (${FANSPEED}/${FANPERCENT}%%)"
			fi
		fi
	done
}

if [ ! -x $HP_HEALTH_TOOL ] ; then
    printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX} $ERROR ${ERRNO[4]} "${DESCR[4]}" $HP_HEALTH_TOOL
    exit
fi
lockfilewait () {
        LOCKFILE=$1

# lock file check/wait
    if [ -f ${LOCKFILE} ] ; then

    lockFileIsChangedAt=$(stat --format="%Z" ${LOCKFILE})
    nowSec=$(date +"%s")
    let diff="$nowSec-$lockFileIsChangedAt"
    while [ $diff -lt ${LOCKFILE_MAX_WAIT_SEC} ] ; do
        printtoscreen "Lockfile (${LOCKFILE}) exist, waiting for maximum ${LOCKFILE_MAX_WAIT_SEC} sec, now at $diff "
        sleep 1
        nowSec=$(date +"%s")
        let diff="$nowSec-$lockFileIsChangedAt"
    done

    lockFileIsChangedAtHuman=$(stat --format="%z" ${LOCKFILE})
    printlogmess ${SCRIPTNAME} ${SCRIPTID} $SCRIPTINDEX $WARN ${ERRNO[5]} "${DESCR[5]}" $lockFileIsChangedAtHuman
    rm ${LOCKFILE}
fi


}

LOCKFILE="${SYSCHECK_HOME}/var/${SCRIPTID}.lock"
lockfilewait ${LOCKFILE}

touch ${LOCKFILE}
hppsu
hptemp
hpfans
rm ${LOCKFILE}
