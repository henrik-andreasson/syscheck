#!/bin/sh

# install:
# cp activate-vip-init.d /etc/init.d/activate-vip
# sles10:
# ln -s /etc/init.d/rc2.d/S99sctivate-vip ../init.d/activate-vip
# debian:
# ln -s /etc/rc2.d/S99sctivate-vip ../init.d/activate-vip

# this script will activate vip if there is a file indicating this host had the VIP before reboot

# adjust to your path to environment-file
if [ -f /usr/local/environment ] ; then
	. /usr/local/environment
fi

if [ "x${SYSCHECK_HOME}" = "x" ] ; then
	if [ -f /usr/local/syscheck/syscheck.sh ] ; then
		SYSCHECK_HOME=/usr/local/syscheck/
		export SYSCHECK_HOME
	else
		echo "no SYSCHECK_HOME set"
		exit 1	
	fi
fi

case "$1" in
  start)
	
	if [ -f ${SYSCHECK_HOME}/var/this_node_has_the_vip ] ; then
		${SYSCHECK_HOME}/related-enabled/911_activate_VIP.sh -s 
	else
		echo "$0: this node had not the VIP (ie the file ${SYSCHECK_HOME}/var/this_node_has_the_vip did not exist"
	fi 
  ;;

  *) 
	echo "$0: nop"

  ;;
esac

exit 0
