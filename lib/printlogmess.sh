#!/bin/bash
#set -x

# func to output debug when using -s or --screen
printtoscreen() {

  IFS=$'\n'

  if [ "x$PRINTTOSCREEN" = "x1" ] ; then 
	echo "Screenonly output: $*"
  fi
}

addOneToIndex() {
	SCRIPTINDEX=$1
	countup=$(expr $SCRIPTINDEX + 1)
        printf "%02d" $countup
}

# ex: printlogmess $LEVEL $SLOG_ERRNO_1 "$SLOG_DESCR_1"
printlogmess(){
        SCRIPTID=$1
        SCRIPTINDEX=$2
        LEVEL=$3
        ERRNO=$4
        DESCR=$5
        shift 5
        ARG1=$1
        ARG2=$2
        ARG3=$3
        ARG4=$4
        ARG5=$5
        ARG6=$6
        ARG7=$7
        ARG8=$8
        ARG9=$9


        if [ "x${LEVEL}" = "xI" ] ;then
                SYSLOGLEVEL="info"
		LONGLEVEL="INFO"
        elif [ "x${LEVEL}" = "xW" ] ;then
                SYSLOGLEVEL="warning"
		LONGLEVEL="WARNING"
        elif [ "x${LEVEL}" = "xE" ] ;then
                SYSLOGLEVEL="err"
		LONGLEVEL="ERROR"
        else
                echo "wrong type of LEVEL (${LEVEL})"
                exit;
        fi


        DATE=`date +"%Y%m%d %H:%M:%S"`
        HOST=`hostname `
        SEC1970NANO=$(date +"%s.%N")
        HOST=$(hostname )
	    DESCR_W_ARGS=`${SYSCHECK_HOME}/lib/printf.pl "$LONGLEVEL - $DESCR" "$ARG1" "$ARG2" "$ARG3" "$ARG4" "$ARG5" "$ARG6" "$ARG7" "$ARG8" "$ARG9"  `
        MESSAGE0="${HOST}: ${DESCR_W_ARGS}"
      	MESSAGE=${MESSAGE0:0:${MESSAGELENGTH}}
		JSONSTRING="{ \"FROM\": \"SYSCHECK\", \"SYSCHECK_VERSION\": \"${SYSCHECK_VERSION}\", \"LOGFMT\": \"JSON-1.0\", \"SCRIPTID\": \"${SCRIPTID}\", \"SCRIPTINDEX\": \"${SCRIPTINDEX}\", \"LEVEL\": \"${LEVEL}\", \"ERRNO\": \"${ERRNO}\", \"SYSTEMNAME\": \"${SYSTEMNAME}\", \"DATE\": \"${DATE}\", \"HOSTNAME\": \"${HOST}\", \"SEC1970NANO\": \"${SEC1970NANO}\", \"LONGLEVEL\":  \"$LONGLEVEL\", \"DESCRIPTION\": \"$DESCR\", \"EXTRAARG1\":   \"$ARG1\", \"EXTRAARG2\":   \"$ARG2\", \"EXTRAARG3\":   \"$ARG3\", \"EXTRAARG4\":   \"$ARG4\", \"EXTRAARG5\":   \"$ARG5\", \"EXTRAARG6\":   \"$ARG6\", \"EXTRAARG7\":   \"$ARG7\", \"EXTRAARG8\":   \"$ARG8\", \"EXTRAARG9\":   \"$ARG9\", \"LEGACYFMT\":   \"${SCRIPTID}-${SCRIPTINDEX}-${LEVEL}-${ERRNO}-${SYSTEMNAME} ${DATE} ${MESSAGE}\" }"

		NEWFMTSTRING="${SCRIPTID}-${SCRIPTINDEX}-${LEVEL}-${ERRNO}-${SYSTEMNAME} ${DATE} ${MESSAGE}"
		OLDFMTSTRING="${LEVEL}-${SCRIPTID}${ERRNO}-${SYSTEMNAME} ${DATE} ${MESSAGE}"

	    if [ "x${PRINTTOSCREEN}" = "x1" ] ; then
			if [ "x${PRINTTOSCREEN_OUTPUTTYPE}" = "xJSON" ] ; then
				printf "${JSONSTRING}\n"
			elif [ "x${PRINTTOSCREEN_OUTPUTTYPE}" = "xNEWFMT" ] ; then
				printf "${NEWFMTSTRING}\n"
			elif [ "x${PRINTTOSCREEN_OUTPUTTYPE}" = "xOLDFMT" ] ; then
				printf "${OLDFMTSTRING}\n"
			else
				printf "unknown format PRINTTOSCREEN_OUTPUTTYPE: ${PRINTTOSCREEN_OUTPUTTYPE}"
				exit -1
			fi	
	    fi

	    if [ "x${PRINTTOFILE}" != "x" ] ; then
			if [ "x${PRINTTOFILE_OUTPUTTYPE}" = "xJSON" ] ; then
				printf "${JSONSTRING}\n" >> ${PRINTTOFILE_FILENAME}
			elif [ "x${PRINTTOFILE_OUTPUTTYPE}" = "xNEWFMT" ] ; then
				printf "${NEWFMTSTRING}\n"  >> ${PRINTTOFILE_FILENAME}
			elif [ "x${PRINTTOFILE_OUTPUTTYPE}" = "xOLDFMT" ] ; then
				printf "${OLDFMTSTRING}\n"  >> ${PRINTTOFILE_FILENAME}
			else
				printf "unknown format PRINTTOFILE_OUTPUTTYPE: ${PRINTTOFILE_OUTPUTTYPE}"
				exit -1
			fi	
		fi

		if [ "x${SENDTOSYSLOG}" != "x" ] ; then
			if [ "x${SENDTOSYSLOG_OUTPUTTYPE}" = "xJSON" ] ; then
				printf "${JSONSTRING}\n"   | logger -p ${SYSLOGFACILLITY}.${SYSLOGLEVEL} 
			elif [ "x${SENDTOSYSLOG_OUTPUTTYPE}" = "xNEWFMT" ] ; then
				printf "${NEWFMTSTRING}\n" | logger -p ${SYSLOGFACILLITY}.${SYSLOGLEVEL} 
			elif [ "x${SENDTOSYSLOG_OUTPUTTYPE}" = "xOLDFMT" ] ; then
				printf "${OLDFMTSTRING}\n" | logger -p ${SYSLOGFACILLITY}.${SYSLOGLEVEL} 
			else
				printf "unknown format SENDTOSYSLOG_OUTPUTTYPE: ${SENDTOSYSLOG_OUTPUTTYPE}"
				exit -1
			fi	
		fi
		
		if [ "x${SAVELASTSTATUS}" = "x1" ] ; then
			if [ "x${SAVELASTSTATUS_OUTPUTTYPE}" = "xJSON" ] ; then
				printf "${JSONSTRING}\n"   >> ${SYSCHECK_HOME}/var/last_status
			elif [ "x${SAVELASTSTATUS_OUTPUTTYPE}" = "xNEWFMT" ] ; then
				printf "${NEWFMTSTRING}\n" >> ${SYSCHECK_HOME}/var/last_status
			elif [ "x${SAVELASTSTATUS_OUTPUTTYPE}" = "xOLDFMT" ] ; then
				printf "${OLDFMTSTRING}\n" >> ${SYSCHECK_HOME}/var/last_status
			else
				printf "unknown format SAVELASTSTATUS_OUTPUTTYPE: ${SAVELASTSTATUS_OUTPUTTYPE}"
				exit -1
			fi	
		fi
		

}

