#!/bin/bash

SYSCHECK_HOME="${SYSCHECK_HOME:-/opt/syscheck}" # use default if  unset
if [ ! -f ${SYSCHECK_HOME}/syscheck.sh ] ; then
  echo "Can't find $SYSCHECK_HOME/syscheck.sh"
  exit
fi

if [ ! -f ${SYSCHECK_HOME}/syscheck.sh ] ; then echo "Can't find $SYSCHECK_HOME/syscheck.sh" ;exit ; fi

## Import common definitions ##
source $SYSCHECK_HOME/config/syscheck-scripts.conf

SCRIPTID=36

# how many info/warn/error messages
NO_OF_ERR=3
initscript $SCRIPTID $NO_OF_ERR

# get command line arguments
INPUTARGS=`/usr/bin/getopt --options "hsvc" --long "help,screen,verbose" -- "$@"`
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

fan_check () {
        fanid="$1"
	SCRIPTINDEX=$2

#omreport chassis fans index=0 -fmt ssv
#Index;Status;Probe Name;Reading;Minimum Warning Threshold;Maximum Warning Threshold;Minimum Failure Threshold;Maximum Failure Threshold
#0;Ok;System Board Fan2A;7200 RPM;840 RPM;[N/A];600 RPM;[N/A]

        COMMAND=$(${DELLTOOL} chassis fans index=${fanid} -fmt ssv| grep "^${fanid}" | head -1)

        fan_status=$(echo $COMMAND | cut -f2 -d\; )
        fan_name=$(echo $COMMAND | cut -f3 -d\; )
        fan_rpm=$(echo $COMMAND | cut -f4 -d\; )

	FAN_INFO="Fan id: $fanid status: $fan_status name: $fan_name rpm: $fan_rpm"
	printverbose "$FAN_INFO"

        if [ "x$fan_status" = "xOk" ] ; then
                printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX} $INFO ${ERRNO[1]} "${DESCR[1]}" "fanid: $fanid status: $fan_status"
        else
                printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX} $ERROR ${ERRNO[2]} "${DESCR[2]}" "fan NOTOK $FAN_INFO"
        fi
}



temp_check () {
        tempid="$1"
	SCRIPTINDEX=$2

# omreport chassis temps index=0 -fmt ssv
#Index;Status;Probe Name;Reading;Minimum Warning Threshold;Maximum Warning Threshold;Minimum Failure Threshold;Maximum Failure Threshold
#0;Ok;System Board Inlet Temp;27.0 C;3.0 C;40.0 C;-7.0 C;42.0 C

        COMMAND=$(${DELLTOOL} chassis temps index=${tempid} -fmt ssv| grep "^${tempid}" | head -1)

        temp_status=$(echo $COMMAND | cut -f2 -d\; )
        temp_name=$(echo $COMMAND | cut -f3 -d\; )
        temp_degrees=$(echo $COMMAND | cut -f4 -d\; )
        temp_max=$(echo $COMMAND | cut -f6 -d\; )

	TEMP_INFO="Temp id: $tempid status: $temp_status name: $temp_name degrees: $temp_degrees max: $temp_max"
	printverbose "$TEMP_INFO"

        if [ "x$temp_status" = "xOk" ] ; then
                printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX} $INFO ${ERRNO[1]} "${DESCR[1]}" "tempid: $tempid status: $temp_status degrees: $temp_degrees"
        else
                printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX} $ERROR ${ERRNO[2]} "${DESCR[2]}" "temp NOTOK $TEMP_INFO"
        fi
}

psu_check () {
        id="$1"
        SCRIPTINDEX=$2


# omreport chassis pwrsupplies -fmt ssv
# 0;Ok;PS1 Status;AC;432 W;350 W;07.18.7F;Presence Detected;Yes


        COMMAND=$(${DELLTOOL} chassis pwrsupplies -fmt ssv | grep "^${id}" | head -1)

        psu_status=$(echo $COMMAND | cut -f2 -d\; )
        psu_name=$(echo $COMMAND | cut -f3 -d\; )
        psu_watts=$(echo $COMMAND | cut -f6 -d\; )

        PSU_INFO="PSU id: $id status: $psu_status name: $psu_name watt: $psu_watts "
        printverbose "$PSU_INFO"

        if [ "x$psu_status" = "xOk" ] ; then
                printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX} $INFO ${ERRNO[1]} "${DESCR[1]}" "PSU id: $id status: $psu_status watts: $psu_watts"
        else
                printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX} $ERROR ${ERRNO[2]} "${DESCR[2]}" "PSU id: $id NOTOK $PSU_INFO"
        fi
}


power_consumption_check () {
        id="$1"
	SCRIPTINDEX=$2

# omreport chassis pwrmonitoring  -fmt ssv
#Index;Status;Probe Name;Reading;Warning Threshold;Failure Threshold
#2;Ok;System Board Pwr Consumption;70 W;420 W;462 W


        COMMAND=$(${DELLTOOL} chassis pwrmonitoring  -fmt ssv | grep "^${id}" | head -1)

        power_status=$(echo $COMMAND | cut -f2 -d\; )
        power_name=$(echo $COMMAND | cut -f3 -d\; )
        power_watts=$(echo $COMMAND | cut -f4 -d\; )
        power_max=$(echo $COMMAND | cut -f6 -d\; )

	POWER_INFO="Power id: $id status: $power_status name: $power_name watt: $power_watts max: $power_max"
	printverbose "$POWER_INFO"

        if [ "x$power_status" = "xOk" ] ; then
                printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX} $INFO ${ERRNO[1]} "${DESCR[1]}" "powerid: $id status: $power_status watts: $power_watts"
        else
                printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX} $ERROR ${ERRNO[2]} "${DESCR[2]}" "power NOTOK $POWER_INFO"
        fi
}


if [ ! -x $DELLTOOL ] ; then
    printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   $ERROR ${ERRNO[3]} "${DESCR[6]}" $DELLTOOL
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
power_consumption_check "${PWRID}" $SCRIPTINDEX

for (( i = 0 ;  i < ${#PSU[@]} ; i++ )) ; do
	SCRIPTINDEX=$(addOneToIndex $SCRIPTINDEX)
	psu_check "${PSU[$i]}" $SCRIPTINDEX
done
