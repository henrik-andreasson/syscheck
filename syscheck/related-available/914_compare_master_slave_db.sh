#!/bin/sh

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
. $SYSCHECK_HOME/config/related-scripts.conf

# uniq ID of script (please use in the name of this file also for convinice for finding next availavle number)
SCRIPTID=914

getlangfiles $SCRIPTID
getconfig $SCRIPTID

ERRNO_1="${SCRIPTID}1"
ERRNO_2="${SCRIPTID}2"
ERRNO_3="${SCRIPTID}3"


### end config ###

PRINTTOSCREEN=
if [ "x$1" = "x-h" -o "x$1" = "x--help" ] ; then
        echo "$ECRT_HELP"
        echo "$ERRNO_1/$CMSD_DESCR_1 - $CMSD_HELP_1"
        echo "$ERRNO_2/$CMSD_DESCR_2 - $CMSD_HELP_2"
        echo "${SCREEN_HELP}"
        exit
elif [ "x$1" = "x-s" -o  "x$1" = "x--screen" -o \
    "x$2" = "x-s" -o  "x$2" = "x--screen"   ] ; then
    PRINTTOSCREEN=1
fi

COMMAND1=`echo "show tables" | mysql -u $DB_USER -h $HOSTNAME_NODE1 --password=$DB_PASSWORD $DB_NAME | grep -v Tables_in_ejbca`
for table in $COMMAND1; do 
	echo "$table" >> ${HOSTNAME_NODE1}.txt
	echo "select count(*) from $table" | mysql -u $DB_USER -h $HOSTNAME_NODE1 --password=$DB_PASSWORD $DB_NAME | grep -v 'count(\*)' >> ${HOSTNAME_NODE1}.txt
done

COMMAND2=`echo "show tables" | mysql -u $DB_USER -h $HOSTNAME_NODE2 --password=$DB_PASSWORD $DB_NAME | grep -v Tables_in_ejbca`
for table in $COMMAND2; do 
	echo "$table" >> ${HOSTNAME_NODE2}.txt
	echo "select count(*) from $table" | mysql -u $DB_USER -h $HOSTNAME_NODE2 --password=$DB_PASSWORD $DB_NAME | grep -v 'count(\*)' >> ${HOSTNAME_NODE2}.txt
done

diff --side-by-side --width=75 ${HOSTNAME_NODE1}.txt ${HOSTNAME_NODE2}.txt
rm ${HOSTNAME_NODE1}.txt ${HOSTNAME_NODE2}.txt
