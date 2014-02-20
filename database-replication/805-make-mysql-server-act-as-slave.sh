#!/bin/sh

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
. $SYSCHECK_HOME/config/database-replication.conf

SCRIPTID=805
getlangfiles $SCRIPTID || exit 1;
getconfig $SCRIPTID || exit 1;

ERRNO_1="${SCRIPTID}1"
ERRNO_2="${SCRIPTID}2"

schelp () {
        echo "$HELP"
        echo "$ERRNO_1/$DESCR_1 - $HELP_1"
        echo "$ERRNO_2/$DESCR_2 - $HELP_2"
        echo "${SCREEN_HELP}"
        exit
}

PRINTTOSCREEN=1

if [ "x$1" = "x-h" -o "x$1" = "x--help" ] ; then
        schelp
elif [ "x$1" = "x-s" -o  "x$1" = "x--screen" -o \
    "x$2" = "x-s" -o  "x$2" = "x--screen"   ] ; then
        PRINTTOSCREEN=1
elif [ "x$1" = "x-q" -o  "x$1" = "x--quiet" -o \
    "x$2" = "x-q" -o  "x$2" = "x--quiet"   ] ; then
        PRINTTOSCREEN=0
fi 


echo "Are you sure you want to make this mysql server act as mysql slave?"
echo "did you just restore a mysql dump from the current master into this host?"
echo "enter 'im-really-sure' (without the '-') to continiue or ctrl-c to abort"
read a
if [ "x$a" != "xim really sure" ] ; then
        echo "ok probably wise choice, exiting"
        exit
fi

echo "now you need to run 810-show-mysql-master-status.sh on the master node"
echo "or obtain the File and Position somehow"

LOGFILE=
echo "Enter Log File default:[$LOGFILE]>"
read LOGFILE

LOGPOS=4
echo "Enter Log Pos default:[$LOGPOS]>"
read LOGPOS



OUTFILE="$SYSCHECK_HOME/var/tmp_make-mysql-server-act-as-slave.sql"

echo "STOP SLAVE;" > $OUTFILE
echo "RESET SLAVE;" >> $OUTFILE
if [ "x$THIS_NODE" = "xNODE1" ] ; then
	echo "CHANGE MASTER TO MASTER_HOST='${HOSTNAME_NODE2}', MASTER_USER='${DBREP_USER}', MASTER_PASSWORD='${DBREP_PASSWORD}', MASTER_LOG_FILE='${LOGFILE}', MASTER_LOG_POS=${LOGPOS};" >> $OUTFILE
elif [ "x$THIS_NODE" = "xNODE2" ] ; then
	echo "CHANGE MASTER TO MASTER_HOST='${HOSTNAME_NODE1}', MASTER_USER='${DBREP_USER}', MASTER_PASSWORD='${DBREP_PASSWORD}', MASTER_LOG_FILE='${LOGFILE}', MASTER_LOG_POS=${LOGPOS};" >> $OUTFILE
else
	echo "syscheck resources.sh 'THIS_NODE' is not NODE1 or NODE2 ($THIS_NODE)"
	exit
fi

echo "START SLAVE;" >> $OUTFILE

$MYSQL_BIN mysql -u root --password="$MYSQLROOT_PASSWORD" < $OUTFILE
if [ $? -eq 0 ] ; then
        printlogmess $LEVEL_1 $ERRNO_1 "$DESCR_1"
else
        printlogmess $LEVEL_2 $ERRNO_2 "$DESCR_2"
fi




rm $OUTFILE

