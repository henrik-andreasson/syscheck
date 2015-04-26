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




# Import common resources
. $SYSCHECK_HOME/config/related-scripts.conf

SCRIPTID=931

SCRIPTINDEX=00

ERRNO_1="01"
ERRNO_2="02"
ERRNO_3="03"
ERRNO_4="04"

getlangfiles $SCRIPTID 
getconfig $SCRIPTID

PRINTTOSCREEN=

schelp () {
	echo "$BAK_HELP"
	echo "$BAK_ERRNO_1/$BAK_DESCR_1 - $BAK_HELP_1"
	echo "$BAK_ERRNO_2/$BAK_DESCR_2 - $BAK_HELP_2"
	echo "$BAK_ERRNO_3/$BAK_DESCR_3 - $BAK_HELP_3"
	echo "$BAK_ERRNO_4/$BAK_DESCR_4 - $BAK_HELP_4"
	echo "${SCREEN_HELP}"
	exit
}



TEMP=`/usr/bin/getopt --options "hsxdwmy" --long "help,screen,default,daily,weekly,monthly,yearly" -- "$@"`
if [ $? != 0 ] ; then schelp ; fi
echo "TEMP: >$TEMP<"
eval set -- "$TEMP"

while true; do
  case "$1" in
    -s|--screen  ) PRINTTOSCREEN=1; shift;;
    -x|--default ) BACKUPARG=${SUBDIR_DEFAULT}; shift;;
    -d|--daily   ) BACKUPARG=${SUBDIR_DAILY}  ; shift;;
    -w|--weekly  ) BACKUPARG=${SUBDIR_WEEKLY} ; shift;;
    -m|--monthly ) BACKUPARG=${SUBDIR_MONTHLY}; shift;;
    -y|--yearly  ) BACKUPARG=${SUBDIR_YEARLY} ; shift;;
    -h|--help )   schelp;shift;;
    --) break;;
  esac
done


EXTRADIR=
if [ "x${BACKUPARG}" = "x" ] ; then
	EXTRADIR=${SUBDIR_DEFAULT}	
else
	EXTRADIR=${BACKUPARG}
fi

FULLFILENAME=`$SYSCHECK_HOME/related-available/904_make_mysql_db_backup.sh --batch ${BACKUPARG}`

if [ $? -ne 0 ] ; then
    printlogmess $SCRIPTID $SCRIPTINDEX $ERROR $BAK_ERRNO_2 "$BAK_DESCR_2"
fi 

touch /backup/to-archive/encback.lock
res=$(/opt/certificate-services/bin/openenc.sh encrypt ${FULLFILENAME} /backup/to-archive/)
if [ $? -ne 0 ] ;   then
    printlogmess $SCRIPTID $SCRIPTINDEX $ERROR $ERRNO_3 "$DESCR_3" $res
fi  
rm /backup/to-archive/encback.lock


FILETRANS=1
for TRANSFERFILENAME in $(find /backup/to-archive/ -type f ) ; do
	for (( i = 0 ;  i < "${#BACKUP_HOST[@]}" ; i++ )) ; do
		SCRIPTINDEX=$(addOneToIndex $SCRIPTINDEX)
		$SYSCHECK_HOME/related-enabled/906_ssh-copy-to-remote-machine.sh ${TRANSFERFILENAME} ${BACKUP_HOST[$i]} "${BACKUP_DIR[$i]}/${EXTRADIR}/" ${BACKUP_USER[$i]} ${BACKUP_SSHFROMKEY[$i]}
		if [ $? -eq 0 ] ; then 
			printlogmess $SCRIPTID $SCRIPTINDEX $INFO $ERRNO_1 "$DESCR_1" "${TRANSFERFILENAME}"
		else
			printlogmess $SCRIPTID $SCRIPTINDEX $ERROR $ERRNO_4 "$DESCR_4" "${TRANSFERFILENAME}"
			FILETRANS=0
		fi
	done

	# no server failed
	if [ "x${FILETRANS}" = "x1" ] ; then
		rm "${TRANSFERFILENAME}"
	fi
done
