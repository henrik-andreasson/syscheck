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

SCRIPTID=31

getlangfiles $SCRIPTID 
getconfig $SCRIPTID

ERRNO_1=${SCRIPTID}01
ERRNO_2=${SCRIPTID}02
ERRNO_3=${SCRIPTID}03

# help
if [ "x$1" = "x--help" ] ; then
    echo "$0 $HELP"
    echo "$ERRNO_1/$DESCR_1 - $HELP_1"
    echo "$ERRNO_2/$DESCR_2 - $HELP_2"
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

        if [ "x$STATUSPSU1" != "x" -a "x$CONDPSU1" != "x" ] ; then
                printlogmess $INFO $ERRNO_1 "$DESCR_1" "PSU1"
        else
                printlogmess $ERROR $ERRNO_2 "$DESCR_2" "PSU1 $STATUSPSU1 $CONDPSU1"
        fi
        if [ "x$STATUSPSU2" != "x" -a "x$CONDPSU2" != "x" ] ; then
                printlogmess $INFO $ERRNO_1 "$DESCR_1" "PSU2"
        else
                printlogmess $ERROR $ERRNO_2 "$DESCR_2" "PSU2 $STATUSPSU2 $CONDPSU2"
        fi
}

hptemp () {
	for tempinput in $(/bin/echo -e "show temp\nexit" | /sbin/hpasmcli | grep ^# | perl  -ane 's/\s+/;/gio, print "$_\n"') ; do
##15;I/O_ZONE;33C/91F;70C/158F
	        TEMPNO=`echo $tempinput | cut -f1 -d\;`
	        TEMPNAME=`echo $tempinput | cut -f2 -d\;`
	        TEMPVAL=`echo $tempinput | cut -f3 -d\;   | perl -ane 'm/(.*)C\//gio,print "$1"'`
	        TEMPLIMIT=`echo $tempinput | cut -f4 -d\; | perl -ane 'm/(.*)C\//gio,print "$1"'`

		if [ "x${TEMPNO}" = "x#16" -o "x${TEMPNO}" = "x#17" -o "x${TEMPNO}" = "x#18" -o "x${TEMPNO}" = "x#27" -o "x${TEMPNO}" = "x#28" ] ; then
			printlogmess $INFO $ERRNO_1 "$DESCR_1" "TEMP ${TEMPNO} ${TEMPNAME} is known not to give any reading ($tempinput)"
			continue
		fi

		if [ "x${TEMPVAL}" = "x" ] ; then
			printlogmess $ERROR $ERRNO_2 "$DESCR_2" "TEMP Command did not return any value for CURRENT temp ($tempinput
)"
			continue
		fi
		if [ "x${TEMPLIMIT}" = "x" ] ; then
			printlogmess $ERROR $ERRNO_2 "$DESCR_2" "TEMP Command did not return any value for LIMIT temp ($tempinput)"
			continue
		fi

	        if [ ${TEMPVAL} -gt ${TEMPLIMIT} ] ; then
			printlogmess $ERROR $ERRNO_2 "$DESCR_2" "TEMP ${TEMPNO} ${TEMPNAME} Current: ${TEMPVAL} Limit: ${TEMPLIMIT} (celsius)"
	        else
			printlogmess $INFO $ERRNO_1 "$DESCR_1" "TEMP ${TEMPNO} ${TEMPNAME} Current: ${TEMPVAL} Limit: ${TEMPLIMIT} (celsius)"
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

	        if [ "x${FANSPEED}" !=  "xNORMAL" ] ; then
			printlogmess $ERROR $ERRNO_3 "$DESCR_3" "FAN(${FANNO}) NOT in normal operation (${FANSPEED}/${FANPERCENT})"
	        else
			printlogmess $INFO $ERRNO_1 "$DESCR_1" "FAN(${FANNO}) IS in normal operation (${FANSPEED}/${FANPERCENT})"
		fi
	done
}

if [ ! -x $HP_HEALTH_TOOL ] ; then
    printlogmess $ERROR $ERRNO_2 "$DESCR_2" $HP_HEALTH_TOOL
    exit
fi


hppsu
hptemp
hpfans

