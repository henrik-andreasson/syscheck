#!/bin/bash

# Set SYSCHECK_HOME if not already set.

# 1. First check if SYSCHECK_HOME is set then use that
if [ "x${SYSCHECK_HOME}" = "x" ] ; then
# 2. Check if /etc/syscheck.conf exists then source that (put SYSCHECK_HOME=/path/to/syscheck in ther)
    if [ -e /etc/syscheck.conf ] ; then 
	source /etc/syscheck.conf 
    else
# 3. last resort use default path
	SYSCHECK_HOME="/opt/syscheck"
    fi
fi

if [ ! -f ${SYSCHECK_HOME}/syscheck.sh ] ; then echo "$0: Can't find syscheck.sh in SYSCHECK_HOME ($SYSCHECK_HOME)" ;exit ; fi

## Import common definitions ##
. $SYSCHECK_HOME/config/syscheck-scripts.conf

# uniq ID of script (please use in the name of this file also for convinice for finding next availavle number)
SCRIPTID=31

# Index is used to uniquely identify one test done by the script (a harddrive, crl or cert)
SCRIPTINDEX=00



getlangfiles $SCRIPTID 
getconfig $SCRIPTID

ERRNO_1=01
ERRNO_2=02
ERRNO_3=03
ERRNO_4=04

# help
if [ "x$1" = "x--help" ] ; then
    echo "$0 $HELP"
    echo "$ERRNO_1/$DESCR_1 - $HELP_1"
    echo "$ERRNO_2/$DESCR_2 - $HELP_2"
    echo "$ERRNO_3/$DESCR_3 - $HELP_3"
    echo "$ERRNO_4/$DESCR_4 - $HELP_4"
    exit
elif [ "x$1" = "x-s" -o  "x$1" = "x--screen"  ] ; then
    PRINTTOSCREEN=1
fi



hppsu () {
        COMMAND=`/bin/echo -e "show powersupply\nexit" | /sbin/hpasmcli | perl -ane 's/\n//,print'  | perl -ane 'm/Power supply #1.
*Present.*: (.*).*Condition:(.*).*Hotplug.*Power supply #2.*Present.*: (.*).*Condition:(.*).*Hotplug/,print "$1;$2;$3;$4\n"'`
        STATUSPSU1=`echo $COMMAND | cut -f1 -d\; |grep -i "yes"`
        CONDPSU1=`echo $COMMAND | cut -f2 -d\; |grep -i "ok"`
        STATUSPSU2=`echo $COMMAND | cut -f3 -d\; |grep -i "yes"`
        CONDPSU2=`echo $COMMAND | cut -f4 -d\; |grep -i "ok"`

	SCRIPTINDEX=$(addOneToIndex $SCRIPTINDEX)
        if [ "x$STATUSPSU1" != "x" -a "x$CONDPSU1" != "x" ] ; then
                printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   $INFO $ERRNO_1 "$DESCR_1" "PSU1"
        else
                printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   $ERROR $ERRNO_2 "$DESCR_2" "PSU1 $STATUSPSU1 $CONDPSU1"
        fi
	
	SCRIPTINDEX=$(addOneToIndex $SCRIPTINDEX)
        if [ "x$STATUSPSU2" != "x" -a "x$CONDPSU2" != "x" ] ; then
                printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   $INFO $ERRNO_1 "$DESCR_1" "PSU2"
        else
                printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   $ERROR $ERRNO_2 "$DESCR_2" "PSU2 $STATUSPSU2 $CONDPSU2"
        fi
}

hptemp () {
	for tempinput in $(/bin/echo -e "show temp\nexit" | /sbin/hpasmcli | grep ^# | perl  -ane 's/\s+/;/gio, print "$_\n"') ; do
##15;I/O_ZONE;33C/91F;70C/158F
	        TEMPNO=`echo $tempinput | cut -f1 -d\;`
	        TEMPNAME=`echo $tempinput | cut -f2 -d\;`
	        TEMPVAL=`echo $tempinput | cut -f3 -d\;   | perl -ane 'm/(.*)C\//gio,print "$1"'`
	        TEMPLIMIT=`echo $tempinput | cut -f4 -d\; | perl -ane 'm/(.*)C\//gio,print "$1"'`

		SCRIPTINDEX=$(addOneToIndex $SCRIPTINDEX)
		if [ "x${TEMPNO}" = "x#16" -o "x${TEMPNO}" = "x#17" -o "x${TEMPNO}" = "x#18" -o "x${TEMPNO}" = "x#27" -o "x${TEMPNO}" = "x#28" ] ; then
			printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   $INFO $ERRNO_1 "$DESCR_1" "TEMP ${TEMPNO} ${TEMPNAME} is known not to give any reading ($tempinput)"
			continue
		fi

		SCRIPTINDEX=$(addOneToIndex $SCRIPTINDEX)
		if [ "x${TEMPVAL}" = "x" ] ; then
			printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   $ERROR $ERRNO_2 "$DESCR_2" "TEMP Command did not return any value for CURRENT temp ($tempinput
)"
			continue
		fi

		SCRIPTINDEX=$(addOneToIndex $SCRIPTINDEX)
		if [ "x${TEMPLIMIT}" = "x" ] ; then
			printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   $ERROR $ERRNO_2 "$DESCR_2" "TEMP Command did not return any value for LIMIT temp ($tempinput)"
			continue
		fi

		SCRIPTINDEX=$(addOneToIndex $SCRIPTINDEX)
	        if [ ${TEMPVAL} -gt ${TEMPLIMIT} ] ; then
			printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   $ERROR $ERRNO_2 "$DESCR_2" "TEMP ${TEMPNO} ${TEMPNAME} Current: ${TEMPVAL} Limit: ${TEMPLIMIT} (celsius)"
	        else
			printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   $INFO $ERRNO_1 "$DESCR_1" "TEMP ${TEMPNO} ${TEMPNAME} Current: ${TEMPVAL} Limit: ${TEMPLIMIT} (celsius)"
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
	        FANPERCENT=`echo $fansinput | cut -f5 -d\; `

		SCRIPTINDEX=$(addOneToIndex $SCRIPTINDEX)
	        if [ "x${FANSPEED}" !=  "xNORMAL" ] ; then
			printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   $ERROR $ERRNO_3 "$DESCR_3" "FAN(${FANNO}) NOT in normal operation (${FANSPEED}/${FANPERCENT})"
	        else
			printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   $INFO $ERRNO_1 "$DESCR_1" "FAN(${FANNO}) IS in normal operation (${FANSPEED}/${FANPERCENT})"
		fi
	done
}

if [ ! -x $HP_HEALTH_TOOL ] ; then
    printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX} $ERROR $ERRNO_4 "$DESCR_4" $HP_HEALTH_TOOL
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
    printlogmess ${SCRIPTNAME} ${SCRIPTID $SCRIPTINDEX $WARN $ERRNO_5 "$DESCR_5" $lockFileIsChangedAtHuman
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

