#!/bin/sh
#
# syscheck passive server alive init.d script
#
# Here is a little (and extremely primitive)
# startup/shutdown script (tested on SuSE systems). 
#
#### BEGIN INIT INFO
# Provides: syscheck-alive
# Default-Start: 3 5
# Default-Stop: 0 1 2 6
# Description: send server startup/shutdown messages to central monitoring server.
### END INIT INFO

SYSCHECK_HOME=${SYSCHECK_HOME:-"/usr/local/syscheck"}


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

## Import common definitions ##
. $SYSCHECK_HOME/resources.sh

# uniq ID of script (please use in the name of this file also for convinice for finding next availavle number)
SCRIPTID=

getlangfiles $SCRIPTID ;

ERRNO_1="${SCRIPTID}01"
ERRNO_2="${SCRIPTID}02"


case "$1" in
start)
    echo -n "Sending syscheck alive startup message: "
    printlogmess $INFO $ERRNO_1 "$DESCR_1"	
	echo "done"
    ;;
stop)
    echo -n "Sending syscheck alive shutdown message: "
    printlogmess $INFO $ERRNO_2 "$DESCR_2" 
    echo "done"
    ;;
*)
    echo "usage: $0 (start|stop)"
esac
