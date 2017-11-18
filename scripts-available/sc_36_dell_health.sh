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

SCRIPTID=36

# Index is used to uniquely identify one test done by the script (a harddrive, crl or cert)
SCRIPTINDEX=00

getlangfiles $SCRIPTID 
getconfig $SCRIPTID


ERRNO_1=01
ERRNO_2=02
ERRNO_3=03
ERRNO_4=04
ERRNO_5=05
ERRNO_6=06

TEMP=`/usr/bin/getopt --options "hsv" --long "help,screen,verbose" -- "$@"`
if [ $? != 0 ] ; then schelp ; fi
#echo "TEMP: >$TEMP<"
eval set -- "$TEMP"

while true; do
  case "$1" in
    -s|--screen  ) PRINTTOSCREEN=1; shift;;
    -v|--verbose ) PRINTVERBOSESCREEN=1 ; shift;;
    -h|--help )   printhelp;shift;;
    --) break;;
  esac
done


printhelp () {
    echo "$0 $HELP"
    echo "$ERRNO_1/$DESCR_1 - $HELP_1"
    echo "$ERRNO_2/$DESCR_2 - $HELP_2"
    echo "$ERRNO_3/$DESCR_3 - $HELP_3"
    echo "$ERRNO_4/$DESCR_4 - $HELP_4"
    echo "$ERRNO_5/$DESCR_5 - $HELP_5"
    echo "$ERRNO_6/$DESCR_6 - $HELP_6"
}



fan_check () {
        fanid="$1"
	SCRIPTINDEX=$2

#omreport chassis fans index=0 -fmt ssv
#Index;Status;Probe Name;Reading;Minimum Warning Threshold;Maximum Warning Threshold;Minimum Failure Threshold;Maximum Failure Threshold
#0;Ok;System Board Fan2A;7200 RPM;840 RPM;[N/A];600 RPM;[N/A]

        COMMAND=$(omreport chassis fans index=${fanid} -fmt ssv| grep "^${fanid}" | head -1)

        fan_status=$(echo $COMMAND | cut -f2 -d\; )
        fan_name=$(echo $COMMAND | cut -f3 -d\; )
        fan_rpm=$(echo $COMMAND | cut -f4 -d\; )

	FAN_INFO="Fan id: $fanid status: $fan_status name: $fan_name rpm: $fan_rpm"
	printverbose "$FAN_INFO"

        if [ "x$fan_status" = "xOk" ] ; then
                printlogmess ${SCRIPTID} ${SCRIPTINDEX} $INFO $ERRNO_1 "$DESCR_1" "fanid: $fanid status: $fan_status"
        else
                printlogmess ${SCRIPTID} ${SCRIPTINDEX} $ERROR $ERRNO_2 "$DESCR_2" "fan NOTOK $FAN_INFO"
        fi
}



temp_check () {
        tempid="$1"
	SCRIPTINDEX=$2

# omreport chassis temps index=0 -fmt ssv
#Index;Status;Probe Name;Reading;Minimum Warning Threshold;Maximum Warning Threshold;Minimum Failure Threshold;Maximum Failure Threshold
#0;Ok;System Board Inlet Temp;27.0 C;3.0 C;40.0 C;-7.0 C;42.0 C

        COMMAND=$(omreport chassis temps index=${tempid} -fmt ssv| grep "^${tempid}" | head -1)

        temp_status=$(echo $COMMAND | cut -f2 -d\; )
        temp_name=$(echo $COMMAND | cut -f3 -d\; )
        temp_degrees=$(echo $COMMAND | cut -f4 -d\; )
        temp_max=$(echo $COMMAND | cut -f6 -d\; )

	TEMP_INFO="Temp id: $tempid status: $temp_status name: $temp_name degrees: $temp_degrees max: $temp_max"
	printverbose "$TEMP_INFO"

        if [ "x$temp_status" = "xOk" ] ; then
                printlogmess ${SCRIPTID} ${SCRIPTINDEX} $INFO $ERRNO_1 "$DESCR_1" "tempid: $tempid status: $temp_status degrees: $temp_degrees"
        else
                printlogmess ${SCRIPTID} ${SCRIPTINDEX} $ERROR $ERRNO_2 "$DESCR_2" "temp NOTOK $TEMP_INFO"
        fi
}

psu_check () {
        id="$1"
        SCRIPTINDEX=$2


# omreport chassis pwrsupplies -fmt ssv
# 0;Ok;PS1 Status;AC;432 W;350 W;07.18.7F;Presence Detected;Yes


        COMMAND=$(omreport chassis pwrsupplies -fmt ssv | grep "^${id}" | head -1)

        psu_status=$(echo $COMMAND | cut -f2 -d\; )
        psu_name=$(echo $COMMAND | cut -f3 -d\; )
        psu_watts=$(echo $COMMAND | cut -f6 -d\; )

        PSU_INFO="PSU id: $id status: $psu_status name: $psu_name watt: $psu_watts "
        printverbose "$PSU_INFO"

        if [ "x$psu_status" = "xOk" ] ; then
                printlogmess ${SCRIPTID} ${SCRIPTINDEX} $INFO $ERRNO_1 "$DESCR_1" "PSU id: $id status: $psu_status watts: $psu_watts"
        else
                printlogmess ${SCRIPTID} ${SCRIPTINDEX} $ERROR $ERRNO_2 "$DESCR_2" "PSU id: $id NOTOK $PSU_INFO"
        fi
}


power_consumption_check () {
        id="$1"
	SCRIPTINDEX=$2

# omreport chassis pwrmonitoring  -fmt ssv 
#Index;Status;Probe Name;Reading;Warning Threshold;Failure Threshold
#2;Ok;System Board Pwr Consumption;70 W;420 W;462 W


        COMMAND=$(omreport chassis pwrmonitoring  -fmt ssv | grep "^${id}" | head -1)

        power_status=$(echo $COMMAND | cut -f2 -d\; )
        power_name=$(echo $COMMAND | cut -f3 -d\; )
        power_watts=$(echo $COMMAND | cut -f4 -d\; )
        power_max=$(echo $COMMAND | cut -f6 -d\; )

	POWER_INFO="Power id: $id status: $power_status name: $power_name watt: $power_watts max: $power_max"
	printverbose "$POWER_INFO"

        if [ "x$power_status" = "xOk" ] ; then
                printlogmess ${SCRIPTID} ${SCRIPTINDEX} $INFO $ERRNO_1 "$DESCR_1" "powerid: $id status: $power_status watts: $power_watts"
        else
                printlogmess ${SCRIPTID} ${SCRIPTINDEX} $ERROR $ERRNO_2 "$DESCR_2" "power NOTOK $POWER_INFO"
        fi
}


if [ ! -x $DELLTOOL ] ; then
    printlogmess ${SCRIPTID} ${SCRIPTINDEX}   $ERROR $ERRNO_6 "$DESCR_6" $DELLTOOL
    exit
fi


for (( i = 0 ;  i < ${#FANS[@]} ; i++ )) ; do
	SCRIPTINDEX=$(addOneToIndex $SCRIPTINDEX)
	fan_check "${FANS[$i]}" $SCRIPTINDEX
done

for (( i = 0 ;  i < ${#TEMPS[@]} ; i++ )) ; do
	SCRIPTINDEX=$(addOneToIndex $SCRIPTINDEX)
	temp_check "${TEMPS[$i]}" $SCRIPTINDEX
done


SCRIPTINDEX=$(addOneToIndex $SCRIPTINDEX)
power_consumption_check 2 $SCRIPTINDEX

for (( i = 0 ;  i < ${#PSU[@]} ; i++ )) ; do
	SCRIPTINDEX=$(addOneToIndex $SCRIPTINDEX)
	psu_check "${PSU[$i]}" $SCRIPTINDEX
done

