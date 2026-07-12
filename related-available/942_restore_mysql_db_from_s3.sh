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
SCRIPTNAME=restore_mysql_db_from_s3

# uniq ID of script (please use in the name of this file also for convinice for finding next availavle number)
SCRIPTID=942

# how many info/warn/error messages
NO_OF_ERR=5
initscript $SCRIPTID $NO_OF_ERR

# reuse the S3 destinations configured for 941_make_mysql_db_backup_and_transfer_to_s3.sh
getconfig "941"

# needs curl >= 7.75 for --aws-sigv4 and curl >= 7.76 for --fail-with-body
# needs gpg (only used to decrypt backups uploaded with -e|--encrypt, the
# matching private key must already be present in the local gpg keyring)


TEMP=`/usr/bin/getopt --options "hso:i:" --long "help,screen,object:,index:" -- "$@"`
if [ $? != 0 ] ; then schelp ; fi
eval set -- "$TEMP"

S3_INDEX=0

while true; do
  case "$1" in
    -s|--screen ) PRINTTOSCREEN=1; shift;;
    -o|--object ) OBJECTKEY=$2 ; shift 2;;
    -i|--index  ) S3_INDEX=$2 ; shift 2;;
    -h|--help )   schelp;exit;shift;;
    --) break;;
  esac
done


# main part of script

if [ "x${OBJECTKEY}" = "x" ] ; then
	printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[2]} -d "${DESCR[2]}"
	exit 1
fi

if [ "x${S3_ENDPOINT[$S3_INDEX]}" = "x" ] ; then
	printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[3]} -d "${DESCR[3]}" -1 "${S3_INDEX}"
	exit 1
fi

DOWNLOADFILE=$(mktemp)

DOWNLOADRESULT=$(curl --silent --show-error --fail-with-body \
	--aws-sigv4 "aws:amz:${S3_REGION[$S3_INDEX]}:s3" \
	--user "${S3_ACCESS_KEY[$S3_INDEX]}:${S3_SECRET_KEY[$S3_INDEX]}" \
	--output "${DOWNLOADFILE}" \
	"${S3_ENDPOINT[$S3_INDEX]}/${S3_BUCKET[$S3_INDEX]}/${OBJECTKEY}" 2>&1)

if [ $? -ne 0 ] ; then
	printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[4]} -d "${DESCR[4]}" -1 "${S3_ENDPOINT[$S3_INDEX]}/${S3_BUCKET[$S3_INDEX]}/${OBJECTKEY}" -2 "${DOWNLOADRESULT}"
	rm -f "${DOWNLOADFILE}"
	exit 1
fi

RESTOREFILE="${DOWNLOADFILE}"

if [ "x${OBJECTKEY%.gpg}" != "x${OBJECTKEY}" ] ; then
	SCRIPTINDEX=$(addOneToIndex $SCRIPTINDEX)

	DECRYPTFILE=$(mktemp)
	PASSPHRASEARGS=()
	if [ "x${PGP_PASSPHRASE_FILE}" != "x" ] ; then
		PASSPHRASEARGS=(--pinentry-mode loopback --passphrase-file "${PGP_PASSPHRASE_FILE}")
	fi

	gpgresult=$(gpg --batch --yes "${PASSPHRASEARGS[@]}" --output "${DECRYPTFILE}" --decrypt "${DOWNLOADFILE}" 2>&1)
	if [ $? -ne 0 ] ; then
		printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[5]} -d "${DESCR[5]}" -1 "${OBJECTKEY}" -2 "${gpgresult}"
		rm -f "${DOWNLOADFILE}" "${DECRYPTFILE}"
		exit 1
	fi

	rm -f "${DOWNLOADFILE}"
	RESTOREFILE="${DECRYPTFILE}"
fi

SCRIPTINDEX=$(addOneToIndex $SCRIPTINDEX)
printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $INFO -e ${ERRNO[1]} -d "${DESCR[1]}" -1 "${OBJECTKEY}"

if [ "x${PRINTTOSCREEN}" = "x1" ] ; then
	$SYSCHECK_HOME/related-available/920_restore_mysql_db_from_backup.sh --screen --backupfile "${RESTOREFILE}"
else
	$SYSCHECK_HOME/related-available/920_restore_mysql_db_from_backup.sh --backupfile "${RESTOREFILE}"
fi
RESTORERET=$?

rm -f "${RESTOREFILE}"

exit $RESTORERET
