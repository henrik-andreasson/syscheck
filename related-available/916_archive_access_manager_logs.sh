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
SCRIPTNAME=archive_access_manager_logs

## local definitions ##
SCRIPTID=916

# how many info/warn/error messages
NO_OF_ERR=2
initscript $SCRIPTID $NO_OF_ERR


# get command line arguments
INPUTARGS=`/usr/bin/getopt --options "hsv" --long "help,screen,verbose" -- "$@"`
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

for (( i=0; i < ${#FileName[@]} ; i++ )){

   files=$(ls ${FileName[$i]} 2>/dev/null)
   printtoscreen "Will loop over these files: ${files}"
   for fn in ${files} ; do
	KEEPORG=
	if [ "x${ToServer1[$i]}" != "x" ] ; then
		KEEPORG=--keep-org
	fi
	if [ "x${ToServer0[$i]}" != "x" ] ; then
		printtoscreen $SYSCHECK_HOME/related-available/917_archive_file.sh ${KEEPORG} "${fn}" ${ToServer0[$i]} ${ToServerDir[$i]} ${ToUser[$i]}
		$SYSCHECK_HOME/related-available/917_archive_file.sh ${KEEPORG} "${fn}" ${ToServer0[$i]} ${ToServerDir[$i]} ${ToUser[$i]}
		if [ $? != 0 ] ; then
			printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX}  $ERROR ${ERRNO[2]} "${DESCR[2]}" "${fn}" "${ToServerDir[$i]}"
		else
			printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX}  $INFO ${ERRNO[1]} "${DESCR[1]}" "${fn}" "${ToServerDir[$i]}"
		fi
	fi

	if [ "x${ToServer1[$i]}" != "x" ] ; then
		printtoscreen $SYSCHECK_HOME/related-available/917_archive_file.sh "${fn}" ${ToServer1[$i]} ${ToServerDir[$i]} ${ToUser[$i]}
		$SYSCHECK_HOME/related-available/917_archive_file.sh "${fn}" ${ToServer1[$i]} ${ToServerDir[$i]} ${ToUser[$i]}
		if [ $? != 0 ] ; then
			printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX}  $ERROR ${ERRNO[2]} "${DESCR[2]}" "${fn}" "${ToServerDir[$i]}"
		else
			printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX}  $INFO ${ERRNO[1]} "${DESCR[1]}" "${fn}" "${ToServerDir[$i]}"
		fi
	fi
 done
}
