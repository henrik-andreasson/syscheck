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

SCRIPTID=35

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



raiddiskcheck () {
        pdisk="$1"
	controller="$2"
	SCRIPTINDEX=$3

#sample
#omreport storage pdisk controller=0 pdisk=0:1:0 -fmt ssv | grep ^0 | head -1
#ID;Status;Name;State;Power Status;Bus Protocol;Media;Part of Cache Pool;Remaining Rated Write Endurance;Failure Predicted;Revision;Driver Version;Model Number;T10 PI Capable;Certified;Encryption Capable;Encrypted;Progress;Mirror Set ID;Capacity;Used RAID Disk Space;Available RAID Disk Space;Hot Spare;Vendor ID;Product ID;Serial No.;Part Number;Negotiated Speed;Capable Speed;PCIe Negotiated Link Width;PCIe Maximum Link Width;Sector Size;Device Write Cache;Manufacture Day;Manufacture Week;Manufacture Year;SAS Address;Non-RAID HDD Disk Cache Policy;Disk Cache Policy;Form Factor ;Sub Vendor;ISE Capable
# 0:1:0;Ok;Physical Disk 0:1:0;Online;Spun Up;SATA;HDD;Not Applicable;Not Applicable;No;GA6E;Not Applicable;Not Applicable;No;Yes;No;Not Applicable;Not Applicable;0;931.00 GB (999653638144 bytes);931.00 GB (999653638144 bytes);0.00 GB (0 bytes);No;DELL(tm);ST1000NM0033-9ZM173;Z1W5YDAE;TH0W69TH2123369M00VJA0;6.00 Gbps;6.00 Gbps;Not Applicable;Not Applicable;512B;Not Applicable;Not Available;Not Available;Not Available;4433221106000000;Not Applicable;Not Applicable;Not Available;Not Available;No

        COMMAND=$(${DELLTOOL} storage pdisk controller=${controller} pdisk=${pdisk} -fmt ssv| grep "^${pdisk}" | head -1)

        STATUS=$(echo $COMMAND | cut -f2 -d\; )
        disk_name=$(echo $COMMAND | cut -f3 -d\; )
        disk_state=$(echo $COMMAND | cut -f4 -d\; )
        disk_powered=$(echo $COMMAND | cut -f5 -d\; )
        disk_capacity=$(echo $COMMAND | cut -f20 -d\; )
        disk_vendor=$(echo $COMMAND | cut -f24 -d\; )
        disk_prodid=$(echo $COMMAND | cut -f25 -d\; )
        disk_serial=$(echo $COMMAND | cut -f26 -d\; )
        disk_partno=$(echo $COMMAND | cut -f27 -d\; )

	DISK_INFO="Name: $disk_name state: $disk_state powered: $disk_powered capacity: $disk_capacity vendor: $disk_vendor prodid: $disk_prodid serial: $disk_serial partno: $disk_partno"
	printverbose "pdisk: $pdisk controller: $controller $DISK_INFO"

        if [ "x$STATUS" != "x" ] ; then
                printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX} $INFO $ERRNO_1 "$DESCR_1" "disk: ${pdisk} contoller: ${controller} OK"
        else
                printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX} $ERROR $ERRNO_2 "$DESCR_2" "disk: ${pdisk} contoller: ${controller} NOTOK $DISK_INFO"
        fi
}


raidlogiccheck () {
	vdisk="$1"
	controller="$2"
	SCRIPTINDEX=$3

#sample
#omreport storage vdisk controller=0 vdisk=0 -fmt ssv | grep ^0 | head -1
#0;Ok;vd1;Ready;Not Assigned;No;RAID-10;1,862.00 GB (1999307276288 bytes);No;Not Applicable;/dev/sda;SATA;HDD;Read Ahead;Write Back;Not Applicable;64 KB;Unchanged

        COMMAND=$(${DELLTOOL} storage vdisk controller=${controller} vdisk=${vdisk} -fmt ssv| grep "^${vdisk}" | head -1)
        vdisk_status=$(echo $COMMAND | cut -f2 -d\; )
        vdisk_state=$(echo $COMMAND | cut -f4 -d\; )
        vdisk_layout=$(echo $COMMAND | cut -f7 -d\; )
        vdisk_size=$(echo $COMMAND | cut -f8 -d\; )
        vdisk_device=$(echo $COMMAND | cut -f11 -d\; )

	VDISK_INFO="vdisk: $vdisk status: $vdisk_status state: $vdisk_state layout: $vdisk_layout size: $vdisk_size device: $vdisk_device"

	printverbose "vdisk: $vdisk controller: $controller $VDISK_INFO"

	if [ "x$vdisk_status" = "xOk" ] ; then
                printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX} $INFO $ERRNO_3 "$DESCR_3" "controller: $controller vdisk: $vdisk OK"
	else
                printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX} $ERROR $ERRNO_4 "$DESCR_4" "controller: $controller vdisk: $vdisk NOT OK $VDISK_INFO"
	fi
}


if [ ! -x $DELLTOOL ] ; then
    printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   $ERROR $ERRNO_6 "$DESCR_6" $DELLTOOL
    exit
fi


for (( i = 0 ;  i < ${#PHYSICALDRIVE[@]} ; i++ )) ; do
	SCRIPTINDEX=$(addOneToIndex $SCRIPTINDEX)
	raiddiskcheck "${PHYSICALDRIVE[$i]}" $CONTROLLER $SCRIPTINDEX
done

for (( i = 0 ;  i < ${#LOGICALDRIVE[@]} ; i++ )) ; do
	SCRIPTINDEX=$(addOneToIndex $SCRIPTINDEX)
	raidlogiccheck "${LOGICALDRIVE[$i]}" $CONTROLLER $SCRIPTINDEX
done
