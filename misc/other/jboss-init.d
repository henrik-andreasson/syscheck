#!/bin/sh
#
# JBoss Control Script
#
# To use this script
# run it as root - it will switch to the specified user
# It loses all console output - use the log.
#
# Here is a little (and extremely primitive)
# startup/shutdown script for SuSE systems. It assumes
# that JBoss lives in /usr/local/jboss, it's run by user
# 'jboss' and JDK binaries are in /usr/local/jdk/bin. All
# this can be changed in the script itself.
#
# Either amend this script for your requirements
# or just ensure that the following variables are set correctly
# before calling the script.
#
### BEGIN INIT INFO
# Provides: jboss
# Default-Start: 3 5
# Default-Stop: 0 1 2 6
# Description: Start the JBoss application server.
### END INIT INFO

#define where jboss is - this is the directory containing directories log, bin, conf etc
JBOSS_HOME=${JBOSS_HOME:-"/usr/local/jboss"}

#make java is on your path
JAVAPTH=${JAVAPTH:-"/usr/local/java/bin"}

#define the classpath for the shutdown class
JBOSSCP=${JBOSSCP:-"$JBOSS_HOME/bin/shutdown.jar:$JBOSS_HOME/client/jnet.jar"}

#define the script to use to start jboss
JBOSSSH=${JBOSSSH:-"$JBOSS_HOME/bin/run.sh -c default"} 

if [ -f /etc/ejbca/environment ] ; then
    source /etc/ejbca/environment
fi

# Shell functions sourced from /etc/rc.status:
#      rc_check         check and set local and overall rc status
#      rc_status        check and set local and overall rc status
#      rc_status -v     ditto but be verbose in local rc status
#      rc_status -v -r  ditto and clear the local rc status
#      rc_failed        set local and overall rc status to failed
#      rc_reset         clear local rc status (overall remains)
#      rc_exit          exit appropriate to overall rc status
. /etc/rc.status

# First reset status of this service
rc_reset

# Return values acc. to LSB for all commands but status:
# 0 - success
# 1 - misc error
# 2 - invalid or excess args
# 3 - unimplemented feature (e.g. reload)
# 4 - insufficient privilege
# 5 - program not installed
# 6 - program not configured
#
# Note that starting an already running service, stopping
# or restarting a not-running service as well as the restart
# with force-reload (in case signalling is not supported) are
# considered a success.

if [ -n "$JBOSS_CONSOLE" -a ! -d "$JBOSS_CONSOLE" ]; then
  # ensure the file exists
  touch $JBOSS_CONSOLE
fi

if [ -n "$JBOSS_CONSOLE" -a ! -f "$JBOSS_CONSOLE" ]; then
  echo "WARNING: location for saving console log invalid: $JBOSS_CONSOLE"
  echo "WARNING: ignoring it and using /dev/null"
  JBOSS_CONSOLE="/dev/null"
fi

#define what will be done with the console log
JBOSS_CONSOLE=${JBOSS_CONSOLE:-"/dev/null"}

#define the user under which jboss will run, or use RUNASIS to run as the current user
JBOSSUS=${JBOSSUS:-"jboss"}

#do not overwrite serverlog during startup
move_server_log () {
        if [ -f ${JBOSS_HOME}/server/default/log/server.log ] ; then
                DATE=`date +"%F"`
                FILENAME="${JBOSS_HOME}/server/default/log/server.log.${DATE}.restart"
                i=0
                while [ -f $FILENAME ] ; do
                        i=`expr $i + 1`
                        FILENAME="${JBOSS_HOME}/server/default/log/server.log.${DATE}.restart.${i}"
                done
                mv ${JBOSS_HOME}/server/default/log/server.log ${FILENAME}
        fi
}

#check if jboss is running
check_if_running () {
FOO=`ps -ef | grep /usr/local/jboss/bin/run.sh | grep -v grep` 
	if [ "x$FOO" != "x" ] ; then
		echo "Already running"	
		exit 1
	fi
}

CMD_START="cd $JBOSS_HOME/bin; $JBOSSSH"
CMD_STOP="java -classpath $JBOSSCP org.jboss.Shutdown --shutdown"

if [ "$JBOSSUS" = "RUNASIS" ]; then
  SUBIT=""
else
  SUBIT="su - $JBOSSUS -c "
fi

if [ -z "`echo $PATH | grep $JAVAPTH`" ]; then
  export PATH=$PATH:/sbin:/usr/sbin:/usr/local/sbin:$JAVAPTH
fi

if [ ! -d "$JBOSS_HOME" ]; then
  echo JBOSS_HOME does not exist as a valid directory : $JBOSS_HOME
  exit 1
fi

case "$1" in
start)
    check_if_running
    echo -n "Starting JBoss application server: "
# check for non-rotated server.log
    move_server_log
    cd $JBOSS_HOME/bin
    if [ -z "$SUBIT" ]; then
        eval $CMD_START >${JBOSS_CONSOLE} 2>&1 &
    else
        $SUBIT "$CMD_START >${JBOSS_CONSOLE} 2>&1 &"
    fi

	echo "Waiting for jboss server to start:"
	sleep 5
	while [ "`grep 'Server.*JBoss.*Started' $JBOSS_HOME/server/default/log/server.log 2>/dev/null`x" = "x" ] ; do
		echo -n "."
		sleep 2 
	done
	echo "Jboss server is up and running."


    # Remember status and be verbose
    rc_status -v
    ;;
stop)
    echo -n "Shutting down JBoss application server: "
    if [ -z "$SUBIT" ]; then
        $CMD_STOP
    else
        $SUBIT "$CMD_STOP"
    fi
	while [ "`grep 'Server.*Shutdown.*complete' $JBOSS_HOME/server/default/log/server.log 2>/dev/null`x" = "x" ] ; do
		echo -n "."
		sleep 2
	done
	echo "Jboss server is now stopped."

    # Remember status and be verbose
    rc_status -v
    ;;
restart)
    $0 stop
    $0 start

    # Remember status and be quiet
    rc_status
    ;;
*)
    echo "usage: $0 (start|stop|restart|help)"
esac
