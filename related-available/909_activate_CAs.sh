#!/bin/bash

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

# scriptname used to map and explain scripts in icinga and other
SCRIPTNAME=activate_ca

# uniq ID of script (please use in the name of this file also for convinice for finding next availavle number)
SCRIPTID=909

# Index is used to uniquely identify one test done by the script (a harddrive, crl or cert)
SCRIPTINDEX=00


getlangfiles $SCRIPTID
getconfig $SCRIPTID

ERRNO_1="01"
ERRNO_2="02"
ERRNO_3="03"


PRINTTOSCREEN=
if [ "x$1" = "x-h" -o "x$1" = "x--help" ] ; then
    echo "$HELP"
    echo "$ERRNO_1/$DESCR_1 - $HELP_1"
    echo "$ERRNO_2/$DESCR_2 - $HELP_2"
    echo "$ERRNO_3/$DESCR_3 - $HELP_3"
    echo "${SCREEN_HELP}"
    exit
elif [ "x$1" = "x-s" -o  "x$1" = "x--screen" -o \
    "x$2" = "x-s" -o  "x$2" = "x--screen"   ] ; then
    PRINTTOSCREEN=1
    shift
fi


cd $EJBCA_HOME
for (( i = 0 ;  i < ${#CANAME[@]} ; i++ )) ; do
        NAME=${CANAME[$i]}
        PIN=${CAPIN[$i]}

        if [ "x${PIN}" = "x" ] ; then
                printtoscreen "Activating CA: $NAME, no PIN in config will prompt for it"
        else
                printtoscreen "Activating CA: $NAME (./bin/ejbca.sh ca activateca $NAME )"
        fi

        SCRIPTINDEX=$(addOneToIndex $SCRIPTINDEX)
        ./bin/ejbca.sh ca activateca $NAME $PIN | tee ${SYSCHECK_HOME}/var/$0.output
        error=$(grep -v "Enter authorization code:" ${SYSCHECK_HOME}/var/$0.output)
        if [ "x$error" = "x"  ] ; then
            printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX} $INFO $ERRNO_1 "$DESCR_1" "$NAME"
        else
            printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX} $ERROR $ERRNO_2 "$DESCR_2" "$NAME" "$error"

        fi
        echo " --- "

done
