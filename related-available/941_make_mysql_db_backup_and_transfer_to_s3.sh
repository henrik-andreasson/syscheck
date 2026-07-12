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
SCRIPTNAME=make_mysql_db_backup_and_transfer_to_s3

# uniq ID of script (please use in the name of this file also for convinice for finding next availavle number)
SCRIPTID=941

# how many info/warn/error messages
NO_OF_ERR=5
initscript $SCRIPTID $NO_OF_ERR

# needs curl >= 7.75 for --aws-sigv4 and curl >= 7.76 for --fail-with-body
# needs gpg >= 2.1.14 for --recipient-file (only used when encryption is enabled)


TEMP=`/usr/bin/getopt --options "hsxdwmyre" --long "help,screen,default,daily,weekly,monthly,yearly,remove-local,encrypt" -- "$@"`
if [ $? != 0 ] ; then schelp ; fi
#echo "TEMP: >$TEMP<"
eval set -- "$TEMP"

while true; do
  case "$1" in
    -s|--screen       ) PRINTTOSCREEN=1; shift;;
    -x|--default      ) BACKUPARG=${SUBDIR_DEFAULT}; shift;;
    -d|--daily        ) BACKUPARG=${SUBDIR_DAILY}  ; shift;;
    -w|--weekly       ) BACKUPARG=${SUBDIR_WEEKLY} ; shift;;
    -m|--monthly      ) BACKUPARG=${SUBDIR_MONTHLY}; shift;;
    -y|--yearly       ) BACKUPARG=${SUBDIR_YEARLY} ; shift;;
    -r|--remove-local ) REMOVE_LOCAL_BACKUP=1; shift;;
    -e|--encrypt      ) PGP_ENCRYPT_BACKUP=1; shift;;
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
    printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[2]} -d "${DESCR[2]}" -1 "${FULLFILENAME}"
    exit 1
fi

while IFS= read -r FILE; do
	[ "x${FILE}" = "x" ] && continue

	UPLOADFILE="${FILE}"
	ENCRYPTED=0

	if [ "x${PGP_ENCRYPT_BACKUP}" = "x1" ] ; then
		SCRIPTINDEX=$(addOneToIndex $SCRIPTINDEX)

		if [ "x${PGP_PUBKEY_FILE}" = "x" ] || [ ! -r "${PGP_PUBKEY_FILE}" ] ; then
			printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[5]} -d "${DESCR[5]}" -1 "${FILE}" -2 "PGP_PUBKEY_FILE (${PGP_PUBKEY_FILE}) not readable"
			continue
		fi

		ENCFILE="${FILE}.gpg"
		gpgresult=$(gpg --batch --yes --trust-model always --recipient-file "${PGP_PUBKEY_FILE}" --output "${ENCFILE}" --encrypt "${FILE}" 2>&1)
		if [ $? -ne 0 ] ; then
			printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[5]} -d "${DESCR[5]}" -1 "${FILE}" -2 "${gpgresult}"
			continue
		fi

		UPLOADFILE="${ENCFILE}"
		ENCRYPTED=1
	fi

	SCRIPTINDEX=$(addOneToIndex $SCRIPTINDEX)

	BASEFILE=$(basename "${UPLOADFILE}")
	REMOTE_UUID=$(cat /proc/sys/kernel/random/uuid 2>/dev/null || uuidgen)
	OBJECTKEY="${S3_PREFIX}/${EXTRADIR}/${REMOTE_UUID}-${BASEFILE}"

	HEADERFILE=$(mktemp)
	UPLOADRESULT=$(curl --silent --show-error --fail-with-body \
		--aws-sigv4 "aws:amz:${S3_REGION}:s3" \
		--user "${S3_ACCESS_KEY}:${S3_SECRET_KEY}" \
		--dump-header "${HEADERFILE}" \
		--upload-file "${UPLOADFILE}" \
		"${S3_ENDPOINT}/${S3_BUCKET}/${OBJECTKEY}" 2>&1)
	retcode=$?

	if [ $retcode -eq 0 ] ; then
		ETAG=$(grep -i '^etag:' "${HEADERFILE}" | tr -d '\r"' | awk '{print $2}')
		printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $INFO -e ${ERRNO[1]} -d "${DESCR[1]}" -1 "${OBJECTKEY}" -2 "${ETAG}"

		if [ "x${REMOVE_LOCAL_BACKUP}" = "x1" ] ; then
			SCRIPTINDEX=$(addOneToIndex $SCRIPTINDEX)
			rmresult=$(rm -f "${FILE}" 2>&1)
			if [ $? -ne 0 ] ; then
				printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $WARN -e ${ERRNO[4]} -d "${DESCR[4]}" -1 "${FILE}" -2 "${rmresult}"
			fi
		fi
	else
		printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[3]} -d "${DESCR[3]}" -1 "${UPLOADFILE}" -2 "${UPLOADRESULT}"
	fi

	rm -f "${HEADERFILE}"

	if [ "x${ENCRYPTED}" = "x1" ] ; then
		rm -f "${UPLOADFILE}"
	fi
done <<< "$FULLFILENAME"
