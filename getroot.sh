#!/bin/bash

#Scripts that creates replication privilegdes for the slave db to the master.

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




## Import common definitions ##
source $SYSCHECK_HOME/config/common.conf

# uniq ID of script (please use in the name of this file also for convinice for finding next availavle number)
SCRIPTID=700

# Index is used to uniquely identify one test done by the script (a harddrive, crl or cert)
SCRIPTINDEX=00

getlangfiles $SCRIPTID || exit 1;
getconfig $SCRIPTID || exit 1;

ERRNO_1="${SCRIPTID}1"
ERRNO_2="${SCRIPTID}2"
ERRNO_3="${SCRIPTID}3"
ERRNO_4="${SCRIPTID}4"

printf "$0: Tool to log changes and to pause syscheck\n\n"

ExecutingUserName=$(whoami)
ExecutingUserId=$(id -u)

if [ "x${ExecutingUserName}" = "xroot" ] ; then
    printf "Do not run as root\n"
    exit
fi

if [ -f  ${SYSCHECK_HOME}/var/syscheck-on-hold ] ; then
	read -e -i "y" -r -p "Syscheck is on hold, are you done Y/n?" SYSCHECKONHOLDDONE
	if [ "x${SYSCHECKONHOLDDONE}" = "xy" -o "x$SYSCHECKONHOLDDONE" = "xY" ] ; then
		REASON=$(cat ${SYSCHECK_HOME}/var/syscheck-on-hold)
		sudo rm ${SYSCHECK_HOME}/var/syscheck-on-hold
		sudo ${SYSCHECK_HOME}/lib/printlogmess-cli.sh ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX} $INFO $ERRNO_4 "$DESC_4" "${ExecutingUserName} (${ExecutingUserId})" "$REASON"
		printf "${SCRIPTID} ${SCRIPTINDEX} $INFO $ERRNO_4 ${ExecutingUserName} (${ExecutingUserId}) $DESC_4 $REASON\n" 
		sudo ${SYSCHECK_HOME}/lib/logbook-cli.sh ${SCRIPTID} ${SCRIPTINDEX} $INFO $ERRNO_4 "$DESC_4" "${ExecutingUserName}" "$REASON"
		exit
	fi
fi

printf "Please state a short but clear reason why you need root\n"
read -e -i "Change # - " -r -p "> " REASON

if [ "x$REASON" = "xChange #123 - Update ntp server ip" ] ; then
        REASON="NOREASON"
elif [ "x$REASON" = "x" ] ; then
	REASON="NOREASON"
fi

read -e -i "y" -r -p "stop any new syscheck scripts Y/n?" SYSCHECKONHOLD

if [ "x$SYSCHECKONHOLD" = "xy" -o "x$SYSCHECKONHOLD" = "xY" ] ; then
    sudo ${SYSCHECK_HOME}/lib/printlogmess-cli.sh ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX} $INFO $ERRNO_3 "$DESC_3" "${ExecutingUserName} (${ExecutingUserId})" "$REASON"
    sudo ${SYSCHECK_HOME}/lib/logbook-cli.sh      ${SCRIPTID} ${SCRIPTINDEX} $INFO $ERRNO_3 "$DESC_3" "${ExecutingUserName}" "$REASON"
	printf "$(date):${REASON}:${ExecutingUserName}" | sudo tee ${SYSCHECK_HOME}/var/syscheck-on-hold > /dev/null
else
    sudo ${SYSCHECK_HOME}/lib/printlogmess-cli.sh ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   $INFO $ERRNO_1 "$DESC_1" "${ExecutingUserName} (${ExecutingUserId})" "$REASON"
    sudo ${SYSCHECK_HOME}/lib/logbook-cli.sh ${SCRIPTID} ${SCRIPTINDEX} $INFO $ERRNO_1 "$DESC_1" "${ExecutingUserName}" "$REASON"
fi

sudo su -

if [ -f  ${SYSCHECK_HOME}/var/syscheck-on-hold ] ; then
	read -e -i "y" -r -p "Syscheck is on hold, are you done Y/n?" SYSCHECKONHOLDDONE
	if [ "x${SYSCHECKONHOLDDONE}" = "xy" -o "x$SYSCHECKONHOLDDONE" = "xY" ] ; then
		REASON=$(cat ${SYSCHECK_HOME}/var/syscheck-on-hold)
		sudo rm ${SYSCHECK_HOME}/var/syscheck-on-hold
		sudo ${SYSCHECK_HOME}/lib/printlogmess-cli.sh ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX} $INFO $ERRNO_4 "$DESC_4" "${ExecutingUserName} (${ExecutingUserId})" "$REASON"
		sudo ${SYSCHECK_HOME}/lib/logbook-cli.sh ${SCRIPTID} ${SCRIPTINDEX} $INFO $ERRNO_4 "$DESC_4" "${ExecutingUserName}" "$REASON"
		printf "${SCRIPTID} ${SCRIPTINDEX} $INFO $ERRNO_4 $DESC_4 ${ExecutingUserName} (${ExecutingUserId}) $REASON\n" 
		exit
	fi
fi

