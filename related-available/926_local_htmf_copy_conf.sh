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
SCRIPTNAME=local_htmf_copy_conf

# uniq ID of script (please use in the name of this file also for convinice for finding next availavle number)
SCRIPTID=926

# how many info/warn/error messages
NO_OF_ERR=3
initscript $SCRIPTID $NO_OF_ERR

# get command line arguments
INPUTARGS=`/usr/bin/getopt --options "hsv" --long "help,screen,verbose,backup,restore" -- "$@"`
if [ $? != 0 ] ; then schelp ; fi
#echo "TEMP: >$TEMP<"
eval set -- "$INPUTARGS"

while true; do
  case "$1" in
    -b|--backup)   BACKUP="backup"; shift;;
    -r|--restore)  BACKUP="restore" ; shift;;
    -s|--screen  ) PRINTTOSCREEN=1; shift;;
    -v|--verbose ) PRINTVERBOSESCREEN=1 ; shift;;
    -h|--help )   schelp;exit;shift;;
    --) break;;
  esac
done


# main part of script

if [ !- d ${BACKUP_DIR} ] ; then
	mkdir -p ${BACKUP_DIR}
	if [ $? -ne 0 ] ; then
	    printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   $ERROR ${ERRNO[3]} "${DESCR[3]}" "${BACKUP_DIR}"
	    exit
	fi
fi


for (( j=0; j < ${#HTMF_FILE[@]} ; j++ )){
	printtoscreen "Copying file: ${HTMF_FILE[$j]} to:${BACKUP_DIR}"
	if [ "x${BACKUP}" = "xbackup" ] ; then
		cp -f "${HTMF_FILE[$j]}" ${BACKUP_DIR}
		if [ $? -ne 0 ] ; then
	    		printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   $ERROR ${ERRNO[2]} "${DESCR[2]}" ${HTMF_FILE[$j]}
	    		continue
		else
	    		printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   $INFO ${ERRNO[1]} "${DESCR[1]}" ${HTMF_FILE[$j]}
		fi
	else
		localfilename=$(basename ${HTMF_FILE[$j]})
		cp -f ${BACKUP_DIR}/${localfilename} "${HTMF_FILE[$j]}"
                if [ $? -ne 0 ] ; then
                        printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   $ERROR ${ERRNO[2]} "${DESCR[2]}" ${HTMF_FILE[$j]}
                        continue
                else
                        printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   $INFO ${ERRNO[1]} "${DESCR[1]}" ${HTMF_FILE[$j]}
                fi

	fi

}
