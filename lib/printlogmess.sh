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


#        sendlogmess "${SCRIPTID}-${SCRIPTINDEX}" "${HOST}"  "${DESCR_W_ARGS}"
sendlogmess(){
#    set -x
    SCRIPTNAME=$1
    SCRIPTID=$2
    SCRIPTINDEX=$3
    xHOSTNAME=$4
    MESSAGE=$5

    if [ "x$SCRIPTNAME" = "x" ] ;then
        echo "scriptname must be passed to sendlogmess"
        exit
    fi

    if [ "x${LEVEL}" = "xI" ] ;then
        status_code="0"

    elif [ "x${LEVEL}" = "xW" ] ;then
        status_code="1"

    elif [ "x${LEVEL}" = "xE" ] ;then
        status_code="2"

    else
        echo "wrong type of LEVEL (${LEVEL})"
        status_code="2"
    fi

    if [ "x$SCRIPTID" = "x" ] ;then
        echo "scriptid must be passed to sendlogmess"
        exit
    fi

    if [ "x$SCRIPTINDEX" = "x" ] ;then
        echo "scriptindex must be passed to sendlogmess"
        exit
    fi
    if [ "x$xHOSTNAME" = "x" ] ;then
        echo "HOSTNAME must be passed to sendlogmess"
        exit
    fi
    if [ "x$MESSAGE" = "x" ] ;then
        echo "MESSAGE must be passed to sendlogmess"
        exit
    fi



#     curl -u 'status_update:asd123' -H 'content-type: application/json' -d '{"host_name":"H-CA01","service_description":"test", "status_code":"2","plugin_output":"Example issue has occurred"}' 'https://monitorserver/api/command/PROCESS_SERVICE_CHECK_RESULT'

    if [ "x${SENDTO_OP5}" = "x1" ] ; then
#    curl -u 'status_update:mysecret' -H 'content-type: application/json' -d '{"host_name":"example_host_1","service_description":"Example service", "status_code":"2","plugin_output":"Example issue has occurred"}' 'https://monitorserver/api/command/PROCESS_SERVICE_CHECK_RESULT'
        check_source=$xHOSTNAME
        plugin_output=$MESSAGE
        op5_user="root"
        op5_pass="foo123x"
        op5_http_api_url="https://monitorserver/api/command/PROCESS_SERVICE_CHECK_RESULT"
        check_name="sc_$SCRIPTNAME_$SCRIPTID_$SCRIPTINDEX"

        sendresult=$(curl --silent --show-error -u "$op5_user:$op5_pass" --no-progress-bar -H 'content-type: application/json' -d "{\"host_name\":\"$xHOSTNAME\",\"service_description\":\"$check_name\", \"status_code\":\"$status_code\",\"plugin_output\":\"$MESSAGE\"}" "$op5_http_api_url/PROCESS_SERVICE_CHECK_RESULT" 2>&1)

        isresultok=$(echo "$sendresult" | grep "Successfully submitted" )

        if [ "x$isresultok" = "x" ] ; then
#        curl -k -s -u $icinga_user:$icinga_pass -H 'Accept: application/json' -X POST "$icinga_http_api_url/process-check-result?host=admin3.st.certificateservices.se' -d '{ "exit_status": 0, "plugin_output": "PING CRITICAL - Packet loss = 100%", "check_source": "admin3.st.certificateservices.se" }'
            echo "not ok ($sendresult)"
        else
            echo "ok ($sendresult)"

        fi

    fi

    if [ "x${SENDTO_ICINGA}" = "x1" ] ; then

#    curl ': curl -k -s -u root:foo123 -H 'Accept: application/json' -X POST 'https://192.168.21.151:5665/v1/actions/process-check-result?host=admin3.st.certificateservices.se!ping4' -d '{ "exit_status": 2, "plugin_output": "PING CRITICAL - Packet loss = 100%", "check_source": "admin3.st.certificateservices.se" }'


    #curl -k -s -u root:foo123 -H 'Accept: application/json' -X POST 'https://192.168.21.151:5665/v1/actions/process-check-result?host=admin3.st.certificateservices.se' -d '{ "exit_status": 0, "plugin_output": "PING CRITICAL - Packet loss = 100%", "check_source": "admin3.st.certificateservices.se" }'
        check_source=$xHOSTNAME
        plugin_output=$MESSAGE
        icinga_user="root"
        icinga_pass="foo123"
        icinga_http_api_url="https://192.168.21.151:5665/v1/actions/"
        check_name="sc_$SCRIPTID_$SCRIPTINDEX"
        curl -k -s -u $icinga_user:$icinga_pass -H 'Accept: application/json' -X POST "$icinga_http_api_url/process-check-result?host=admin3.st.certificateservices.se" -d '{ "exit_status": 0, "plugin_output": "PING CRITICAL - Packet loss = 100%", "check_source": "admin3.st.certificateservices.se" }'

    fi

}

# ex: printlogmess $LEVEL $SLOG_ERRNO_1 "$SLOG_DESCR_1"
printlogmess(){
        SCRIPTNAME=$1
        SCRIPTID=$2
        SCRIPTINDEX=$3
        LEVEL=$4
        ERRNO=$5
        DESCR=$6
        shift 6
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

        if [ "x$SCRIPTNAME" = "x" ] ;then
          echo "scriptname must be passed to printlogmess"
          exit
        fi

        if [ "x$SCRIPTID" = "x" ] ;then
          echo "scriptid must be passed to printlogmess"
          exit
        fi

        if [ "x$SCRIPTINDEX" = "x" ] ;then
          echo "scriptindex must be passed to printlogmess"
          exit
        fi
        if [ "x$DESCR" = "x" ] ;then
          echo "DESCR must be passed to printlogmess"
          exit
        fi



        DATE=`date +"%Y%m%d %H:%M:%S"`
        HOST=`hostname `
        SEC1970NANO=$(date +"%s.%N")
        HOST=$(hostname )
        DESCR_W_ARGS=$(${SYSCHECK_HOME}/lib/printf.pl "$LONGLEVEL - $SCRIPTNAME $DESCR"  "$ARG1" "$ARG2" "$ARG3" "$ARG4" "$ARG5" "$ARG6" "$ARG7" "$ARG8" "$ARG9")
        MESSAGE0="${HOST}: ${DESCR_W_ARGS}"
      	MESSAGE=${MESSAGE0:0:${MESSAGELENGTH}}
      	NEWFMTSTRING="${SCRIPTID}-${SCRIPTINDEX}-${LEVEL}-${ERRNO}-${SYSTEMNAME} ${DATE} ${MESSAGE}"
        OLDFMTSTRING="${LEVEL}-${SCRIPTID}${ERRNO}-${SYSTEMNAME} ${DATE} ${MESSAGE}"
        JSONSTRING="{ \"FROM\": \"SYSCHECK\", \"SYSCHECK_VERSION\": \"${SYSCHECK_VERSION}\", \"LOGFMT\": \"JSON-1.1\", \"SCRIPTNAME\": \"${SCRIPTNAME}\", \"SCRIPTID\": \"${SCRIPTID}\", \"SCRIPTINDEX\": \"${SCRIPTINDEX}\", \"LEVEL\": \"${LEVEL}\", \"ERRNO\": \"${ERRNO}\", \"SYSTEMNAME\": \"${SYSTEMNAME}\", \"DATE\": \"${DATE}\", \"HOSTNAME\": \"${HOST}\", \"SEC1970NANO\": \"${SEC1970NANO}\", \"LONGLEVEL\":  \"$LONGLEVEL\", \"DESCRIPTION\": \"$DESCR\", \"EXTRAARG1\":   \"$ARG1\", \"EXTRAARG2\":   \"$ARG2\", \"EXTRAARG3\":   \"$ARG3\", \"EXTRAARG4\":   \"$ARG4\", \"EXTRAARG5\":   \"$ARG5\", \"EXTRAARG6\":   \"$ARG6\", \"EXTRAARG7\":   \"$ARG7\", \"EXTRAARG8\":   \"$ARG8\", \"EXTRAARG9\":   \"$ARG9\", \"LEGACYFMT\":   \"${NEWFMTSTRING}\" }"

        if [ "x${SENDTO_OP5}" = "x1" -o "x${SENDTO_ICINGA}" = "x1" ] ; then
            sendlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX} "${HOST}"  "${DESCR_W_ARGS}"
        fi

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

        if [ "x${PRINTTOFILE}" = "x1" ] ; then
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

        if [ "x${SENDTOSYSLOG}" = "x1" ] ; then
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


# ex: logbookmess $LEVEL $ERRNO_1 "$DESCR_1"
logbookmess(){
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

		if [ "x${LOGBOOKTOFILE}" != "x1" ] ; then
	        return
		fi

        DATE=`date +"%Y%m%d %H:%M:%S"`
        HOST=`hostname `
        SEC1970NANO=$(date +"%s.%N")
        HOST=$(hostname )
	    DESCR_W_ARGS=`${SYSCHECK_HOME}/lib/printf.pl "$LONGLEVEL - $DESCR" "$ARG1" "$ARG2" "$ARG3" "$ARG4" "$ARG5" "$ARG6" "$ARG7" "$ARG8" "$ARG9"  `
        MESSAGE0="${HOST}: ${DESCR_W_ARGS}"
      	MESSAGE=${MESSAGE0:0:${MESSAGELENGTH}}
      	NEWFMTSTRING="${SCRIPTID}-${SCRIPTINDEX}-${LEVEL}-${ERRNO}-${SYSTEMNAME} ${DATE} ${MESSAGE}"
		OLDFMTSTRING="${LEVEL}-${SCRIPTID}${ERRNO}-${SYSTEMNAME} ${DATE} ${MESSAGE}"

		if [ "x${LOGBOOK_OUTPUTTYPE}" = "xJSON" ] ; then
           LOGBOOK_JSONSTRING="{ \"FROM\": \"SYSCHECK\", \"SYSCHECK_VERSION\": \"${SYSCHECK_VERSION}\", \"LOGFMT\": \"LOGBOOK-1.0\", \"SCRIPTID\": \"${SCRIPTID}\", \"SCRIPTINDEX\": \"${SCRIPTINDEX}\", \"LEVEL\": \"${LEVEL}\", \"ERRNO\": \"${ERRNO}\", \"SYSTEMNAME\": \"${SYSTEMNAME}\", \"DATE\": \"${DATE}\", \"HOSTNAME\": \"${HOST}\", \"SEC1970NANO\": \"${SEC1970NANO}\", \"LONGLEVEL\":  \"$LONGLEVEL\", \"DESCRIPTION\": \"$DESCR\", \"USERNAME\":   \"$ARG1\", \"LOGENTRY\":   \"$ARG2\", \"LEGACYFMT\":   \"${NEWFMTSTRING}\" }"
       		printf "${LOGBOOK_JSONSTRING}\n" >> ${LOGBOOK_FILENAME}

		elif [ "x${LOGBOOK_OUTPUTTYPE}" = "xNEWFMT" ] ; then
      		printf "${NEWFMTSTRING}\n" >> ${LOGBOOK_FILENAME}
		else
			printf "unknown format LOGBOOK_OUTPUTTYPE: ${LOGBOOK_OUTPUTTYPE}"
			exit -1
		fi

}
