#!/bin/sh

# func to output debug when using -s or --screen
printtoscreen() {

  IFS=$'\n'

  if [ "x$PRINTTOSCREEN" = "x1" ] ; then 
	echo "Screenonly output:"
	echo $*
  fi
}


# ex: printlogmess $LEVEL $SLOG_ERRNO_1 "$SLOG_DESCR_1"
printlogmess(){
        LEVEL=$1
        ERRNO=$2
        DESCR=$3
        shift 3
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

        DESCR_W_ARGS=`${SYSCHECK_HOME}/lib/printf.pl "$LONGLEVEL - $DESCR" "$ARG1" "$ARG2" "$ARG3" "$ARG4" "$ARG5" "$ARG6" "$ARG7" "$ARG8" "$ARG9"  `

        DATE=`date +"%Y%m%d %H:%M:%S"`
        HOST=`hostname `

        MESSAGE0="${HOST}: ${DESCR_W_ARGS}"
        MESSAGE=${MESSAGE0:0:${MESSAGELENGTH}}

        if [ "x${PRINTTOSCREEN}" = "x1" ] ; then
            echo "${LEVEL}-${ERRNO}-${SYSTEMNAME} ${DATE} ${MESSAGE0}"
	else
	    logger -p local3.${SYSLOGLEVEL} "${LEVEL}-${ERRNO}-${SYSTEMNAME} ${DATE} ${MESSAGE}"
        fi

	if [ "x${SAVELASTSTATUS}" = "x1" ] ; then
	    echo "${LEVEL}-${ERRNO}-${SYSTEMNAME} ${DATE} ${MESSAGE0}" >> ${SYSCHECK_HOME}/var/last_status
	fi



}
