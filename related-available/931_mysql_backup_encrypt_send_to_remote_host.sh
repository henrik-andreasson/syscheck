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
SCRIPTNAME=mysql_db_encrypt_send_to_remote_machine

# uniq ID of script (please use in the name of this file also for convinice for finding next availavle number)
SCRIPTID=931

# how many info/warn/error messages
NO_OF_ERR=3
initscript $SCRIPTID $NO_OF_ERR

# get command line arguments
INPUTARGS=`/usr/bin/getopt --options "hsxdwmy" --long "help,screen,verbose,default,daily,weekly,monthly,yearly" -- "$@"`
if [ $? != 0 ] ; then schelp ; fi
eval set -- "$INPUTARGS"
while true; do
  case "$1" in
    -s|--screen  ) PRINTTOSCREEN=1; shift;;
    -v|--verbose ) PRINTVERBOSESCREEN=1 ; shift;;
    -x|--default ) BACKUPARG=${SUBDIR_DEFAULT}; shift;;
    -d|--daily   ) BACKUPARG=${SUBDIR_DAILY}  ; shift;;
    -w|--weekly  ) BACKUPARG=${SUBDIR_WEEKLY} ; shift;;
    -m|--monthly ) BACKUPARG=${SUBDIR_MONTHLY}; shift;;
    -y|--yearly  ) BACKUPARG=${SUBDIR_YEARLY} ; shift;;
    -h|--help )   schelp;exit;shift;;
    --) break;;
  esac
done


# main part of script

EXTRADIR=
if [ "x${BACKUPARG}" = "x" ] ; then
	EXTRADIR=${SUBDIR_DEFAULT}
else
	EXTRADIR=${BACKUPARG}
fi

FULLFILENAME=`$SYSCHECK_HOME/related-available/904_make_mysql_db_backup.sh --batch ${BACKUPARG}`

if [ $? -ne 0 ] ; then
    printlogmess-n  ${SCRIPTNAME} -i ${SCRIPTID} -x $SCRIPTINDEX -l $ERROR -e $ERRNO[2] -d "$DESCR[2]"
fi

# lock file check/wait
if [ -f ${TOARCHIVE_DIR}/encback.lock ] ; then

    lockFileIsChangedAt=$(stat --format="%Z" ${TOARCHIVE_DIR}/encback.lock)
    nowSec=$(date +"%s")
    let diff="$nowSec-$lockFileIsChangedAt"
    while [ $diff -lt ${LOCKFILE_MAX_WAIT_SEC} ] ; do
        printtoscreen "Lockfile (${TOARCHIVE_DIR}/encback.lock) exist, waiting for maximum ${LOCKFILE_MAX_WAIT_SEC} sec, now at $diff "
        sleep 1
        nowSec=$(date +"%s")
        let diff="$nowSec-$lockFileIsChangedAt"
    done

    lockFileIsChangedAtHuman=$(stat --format="%z" ${TOARCHIVE_DIR}/encback.lock)
    printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x $SCRIPTINDEX -l $WARN -e ${ERRNO[5]} -d "${DESCR[5]}" -1 "$lockFileIsChangedAtHuman"
    rm ${TOARCHIVE_DIR}/encback.lock
fi
for FILE in ${FULLFILENAME};do
	touch ${TOARCHIVE_DIR}/encback.lock
	res=$(${OPENENC_TOOL} encrypt ${FILE} ${TOARCHIVE_DIR})
	if [ $? -ne 0 ] ;   then
    		printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x $SCRIPTINDEX -l $ERROR -e ${ERRNO[3]} -d "${DESCR[3]}" -1 "$res"
	fi
	rm ${TOARCHIVE_DIR}/encback.lock
done

FILETRANS=1
for TRANSFERFILENAME in $(find ${TOARCHIVE_DIR}/ -type f ) ; do
    if [ "x${TRANSFERFILENAME}" = "xencback.log" ] ; then
        continue;
    fi
	for (( i = 0 ;  i < "${#BACKUP_HOST[@]}" ; i++ )) ; do
		SCRIPTINDEX=$(addOneToIndex $SCRIPTINDEX)
		$SYSCHECK_HOME/related-enabled/906_ssh-copy-to-remote-machine.sh "${TRANSFERFILENAME}"" ${BACKUP_HOST[$i]}" "${BACKUP_DIR[$i]}/${EXTRADIR}/" "${BACKUP_USER[$i]}" "${BACKUP_SSHFROMKEY[$i]}"
		if [ $? -eq 0 ] ; then
			printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x $SCRIPTINDEX -l $INFO -e ${ERRNO[1]} -d "${DESCR[1]}" -1 "${TRANSFERFILENAME}"
		else
			printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x $SCRIPTINDEX -l $ERROR -e ${ERRNO[4]} -d "${DESCR[4]}" -1 "${TRANSFERFILENAME}"
			FILETRANS=0
		fi
	done

	# no server failed
	if [ "x${FILETRANS}" = "x1" ] ; then
		rm "${TRANSFERFILENAME}"
	fi
done
