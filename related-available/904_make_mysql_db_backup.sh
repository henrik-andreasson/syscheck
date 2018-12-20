#!/bin/bash

set -o errexit   # no commands must ever return != 0
set -o pipefail  # all commands in a pipe must not fail
set -o noclobber # dont overwrite files
#set -o xtrace   # debug

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




# Import common resources
source $SYSCHECK_HOME/config/related-scripts.conf

# uniq ID of script (please use in the name of this file also for convinice for finding next availavle number)
SCRIPTID=904

# Index is used to uniquely identify one test done by the script (a harddrive, crl or cert)
SCRIPTINDEX=00

initscript $SCRIPTID 


ERRNO_1="01"
ERRNO_2="02"
ERRNO_3="03"

PRINTTOSCREEN=0

schelp () {
	/bin/echo -e "$HELP"
	/bin/echo -e "$ERRNO_1/$DESCR_1 - $HELP_1"
	/bin/echo -e "$ERRNO_2/$DESCR_2 - $HELP_2"
	/bin/echo -e "$ERRNO_3/$DESCR_3 - $HELP_3"
	/bin/echo -e "${SCREEN_HELP}"
	exit
}


TEMP=`/usr/bin/getopt --options "hsymwdxb" --long "help,screen,default,daily,weekly,monthly,yearly,batch" -- "$@"`
if [ $? != 0 ] ; then help ; fi
eval set -- "$TEMP"

while true; do
  case "$1" in
    -x|--default ) TYPE=${SUBDIR_DEFAULT}; shift;;
    -d|--daily   ) TYPE=${SUBDIR_DAILY}; shift;;
    -w|--weekly  ) TYPE=${SUBDIR_WEEKLY}; shift;;
    -m|--monthly ) TYPE=${SUBDIR_MONTHLY}; shift;;
    -y|--yearly  ) TYPE=${SUBDIR_YEARLY}; shift;;
    -s|--screen ) PRINTTOSCREEN=1; shift;;
    -b|--batch )  BATCH=1; shift;;
    -h|--help )   schelp;shift;;
    --) break ;;
  esac
done

EXTRADIR=
if [ "x${TYPE}" = "x" ] ; then
	EXTRADIR=${SUBDIR_DEFAULT}	
else
	EXTRADIR=${TYPE}
fi


if [ ! -d "${MYSQLBACKUPDIR}/${EXTRADIR}" ] ; then
    printlogmess ${SCRIPTNAME}  ${SCRIPTID} ${SCRIPTINDEX}   $ERROR $ERRNO_3 "$DESCR_3" "${MYSQLBACKUPDIR}/${EXTRADIR}"
    exit 1
fi


for (( i = 0 ;  i < ${#DBNAME[@]} ; i++ )) ; do
    SCRIPTINDEX=$(addOneToIndex $SCRIPTINDEX)
    
    DATESTR=$(date +${DATESTING})
    MYSQLBACKUPFULLFILENAME="${MYSQLBACKUPDIR}/${EXTRADIR}/${DBNAME[$i]}-${DATESTR}.gz"
    DATESTART=$(date +"%s")
    dumpret=$($MYSQLDUMP_BIN -u root --password="${MYSQLROOT_PASSWORD}" ${MYSQLDUMP_OPTIONS} "${DB_NAME}" ${MYSQLDUMP_TABLES} |& gzip > ${MYSQLBACKUPFULLFILENAME} 2>&1)
    retcode=$?
    DATEDONE=$(date +"%s")
    let TIMETOCOMPLEATE="$DATEDONE - $DATESTART" || true # not to stop script
    filesize=$(stat -c "%s" "$MYSQLBACKUPFULLFILENAME")
 
    if [ $retcode -eq 0 ] ; then
        printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX} $INFO  $ERRNO_1 "$DESCR_1" "$MYSQLBACKUPFULLFILENAME" $TIMETOCOMPLEATE $filesize
    else
        printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX} $ERROR $ERRNO_2 "$DESCR_2" "$MYSQLBACKUPFULLFILENAME" $TIMETOCOMPLEATE $filesize "$dumpret"
    fi

    if [ "x$BATCH" = "x1" ] ; then
        echo "$MYSQLBACKUPFULLFILENAME"
    fi

done

