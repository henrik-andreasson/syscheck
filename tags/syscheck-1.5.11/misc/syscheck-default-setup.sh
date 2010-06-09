#!/bin/sh



echo "Welcome to $0, a tool to setup syscheck with a default config for Smartcard 2.0"

runningid=`id -u`
if [ "x${runningid}" != "x0" ] ; then
    echo "must run as root eg: sudo $0"
    exit
fi

if [ -r /usr/local/environment ] ; then
        . /usr/local/environment
else
        echo "/usr/local/environment missing"
        exit
fi



/bin/echo -n "activating a set of default checks (to enable more look in $SYSCHECK_HOME/scripts-available/):..."
cd $SYSCHECK_HOME/scripts-enabled 

ln -sf ../scripts-available/sc_02_ejbca.sh .
ln -sf ../scripts-available/sc_03_memory-usage.sh .
ln -sf ../scripts-available/sc_07_syslog.sh .
ln -sf ../scripts-available/sc_12_mysql.sh .
ln -sf ../scripts-available/sc_19_alive.sh .
ln -sf ../scripts-available/sc_20_errors_ejbcalog.sh .

cat <<__EOF__>$SYSCHECK_HOME/config/07.conf
#config for sc_07_syslog.sh

# file at localhost messages goes to
localsyslogfile=/var/log/messages

#rsyslogd
pidfile=/var/run/rsyslogd.pid
procname=rsyslogd

__EOF__
echo "done"

/bin/echo -n "activating syscheck message routing to /var/log/syscheck-info.log, /var/log/syscheck-warn.log and /var/log/syscheck-error.log:..."
cat <<__EOF__>/etc/rsyslog.d/syscheck.conf
local3.info     /var/log/syscheck-info.log
local3.warn     /var/log/syscheck-warn.log
local3.error    /var/log/syscheck-error.log
__EOF__
echo "done"



/bin/echo -n "activating backups of mysql-db to /backup/mysql/default once a day (maybe that should be more often on a production machine):..."
cd $SYSCHECK_HOME/related-enabled
ln -sf ../related-available/904_make_mysql_db_backup.sh .
mkdir -p /backup/mysql/default
echo "done"

/bin/echo -n "activating automated background jobs(cron):..."
cat <<__EOF__>/etc/cron.d/syscheck
*/10 * * * * /usr/local/syscheck/syscheck.sh
0 4 * * * * /usr/local/syscheck/related-enabled/904_make_mysql_db_backup.sh
__EOF__
echo "done"
echo "syscheck default setup done"
