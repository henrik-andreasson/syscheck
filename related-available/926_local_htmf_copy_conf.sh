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
. $SYSCHECK_HOME/config/related-scripts.conf

# uniq ID of script (please use in the name of this file also for convinice for finding next availavle number)
SCRIPTID=926
SCRIPTINDEX=00

getlangfiles $SCRIPTID 
getconfig $SCRIPTID

ERRNO_1="${SCRIPTID}1"
ERRNO_2="${SCRIPTID}2"
ERRNO_3="${SCRIPTID}3"

### end config ###

TEMP=`/usr/bin/getopt --options "br" --long "help,screen,backup,restore" -- "$@"`
if [ $? != 0 ] ; then schelp ; fi
echo "TEMP: >$TEMP<"
eval set -- "$TEMP"

while true; do
  case "$1" in
    -s|--screen  ) PRINTTOSCREEN=1; shift;;
    -b|--backup)   BACKUP="backup"; shift;;
    -r|--restore)  BACKUP="restore" ; shift;;
    -h|--help )    schelp;shift;;
    --) break;;
  esac
done


schelp () {

	echo "$HELP"
	echo "$ERRNO_1/$DESCR_1 - $HELP_1"
	echo "$ERRNO_2/$DESCR_2 - $HELP_2"
	echo "${SCREEN_HELP}"
	exit
}

# Make sure you add quotation marks for the first argument when adding new files that should be copied, for exampel.


if [ !- d ${BACKUP_DIR} ] ; then
	mkdir -p ${BACKUP_DIR}
	if [ $? -ne 0 ] ; then
	    printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   $ERROR $ERRNO_3 "$DESCR_3" "${BACKUP_DIR}"
	    exit
	fi
fi


for (( j=0; j < ${#HTMF_FILE[@]} ; j++ )){
	printtoscreen "Copying file: ${HTMF_FILE[$j]} to:${BACKUP_DIR}"
	if [ "x${BACKUP}" = "xbackup" ] ; then
		cp -f "${HTMF_FILE[$j]}" ${BACKUP_DIR}
		if [ $? -ne 0 ] ; then
	    		printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   $ERROR $ERRNO_2 "$DESCR_2" ${HTMF_FILE[$j]}
	    		continue
		else
	    		printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   $INFO $ERRNO_1 "$DESCR_1" ${HTMF_FILE[$j]}
		fi
	else
		localfilename=$(basename ${HTMF_FILE[$j]})
		cp -f ${BACKUP_DIR}/${localfilename} "${HTMF_FILE[$j]}"
                if [ $? -ne 0 ] ; then
                        printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   $ERROR $ERRNO_2 "$DESCR_2" ${HTMF_FILE[$j]}
                        continue
                else
                        printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   $INFO $ERRNO_1 "$DESCR_1" ${HTMF_FILE[$j]}
                fi

	fi
	
}

