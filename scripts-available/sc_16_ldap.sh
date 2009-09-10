#!/bin/bash
# Script that checks if the OpenLDAP ldap server is running.


# Set default home if not already set.
SYSCHECK_HOME=${SYSCHECK_HOME:-"/usr/local/syscheck"}

# uniq ID of script (please use in the name of this file also for convinice for finding next availavle number)
SCRIPTID=16

## Import common definitions ##
. $SYSCHECK_HOME/resources.sh

getlangfiles $SCRIPTID
getconfig $SCRIPTID

LDAP_ERRNO_1=${SCRIPTID}01
LDAP_ERRNO_2=${SCRIPTID}02


# help
if [ "x$1" = "x--help" ] ; then
    echo "$0 $LDAP_HELP"
    echo "$LDAP_ERRNO_1/$LDAP_DESCR_1 - $LDAP_HELP_1"
    echo "$LDAP_ERRNO_2/$LDAP_DESCR_2 - $LDAP_HELP_2"
    exit
elif [ "x$1" = "x-s" -o  "x$1" = "x--screen" ] ; then
    PRINTTOSCREEN=1
fi

proc=`$SYSCHECK_HOME/lib/proc_checker.sh $pidfile $procname` 
if [ "x$proc" = "x" ] ; then
	printlogmess "$ERROR" "$LDAP_ERRNO_2" "$LDAP_DESCR_2"
else
	printlogmess "$INFO" "$LDAP_ERRNO_1" "$LDAP_DESCR_1"
fi

