#!/bin/sh

#Scripts that creates replication privilegdes for the slave db to the master.

# Set default home if not already set.
SYSCHECK_HOME=${SYSCHECK_HOME:-"/usr/local/syscheck"}

## Import common definitions ##
. $SYSCHECK_HOME/resources.sh

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
echo "enter 'im-really-sure' (without the '-') to continiue or ctrl-c to abort"
read a
if [ "x$a" != "xim really sure" ] ; then
        echo "ok probably wise choice, exiting"
        exit
fi

echo "now you need to run 810-show-mysql-master-status.sh on the master node"
echo "For a first time setup (master has never had a slave) default file='' and pos=4 is the values to use"
echo "then enter File and Position"

LOGFILE=
echo "Enter Log File default:[$LOGFILE]>"
read LOGFILE

LOGPOS=4
echo "Enter Log Pos default:[$LOGPOS]>"
read LOGPOS



OUTFILE="$CLUSTERSCRIPT_HOME/tmp_make-mysql-server-act-as-slave.sql"

echo "STOP SLAVE;" > $OUTFILE
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

