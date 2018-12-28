#!/bin/bash

SYSCHECK_HOME="${SYSCHECK_HOME:-/opt/syscheck}" # use default if  unset
if [ ! -f ${SYSCHECK_HOME}/syscheck.sh ] ; then
  echo "Can't find $SYSCHECK_HOME/syscheck.sh"
  exit
fi

if [ ! -f ${SYSCHECK_HOME}/syscheck.sh ] ; then echo "Can't find $SYSCHECK_HOME/syscheck.sh" ;exit ; fi

## Import common definitions ##
source $SYSCHECK_HOME/config/related-scripts.conf

# script name, used when integrating with nagios/icinga
SCRIPTNAME=compare_slave_db

# uniq ID of script (please use in the name of this file also for convinice for finding next availavle number)
SCRIPTID=914


# how many info/warn/error messages
NO_OF_ERR=2
initscript $SCRIPTID $NO_OF_ERR
getconfig "mariadb"


# get command line arguments
INPUTARGS=`/usr/bin/getopt --options "hsv" --long "help,screen,verbose" -- "$@"`
if [ $? != 0 ] ; then schelp ; fi
#echo "TEMP: >$TEMP<"
eval set -- "$INPUTARGS"

while true; do
  case "$1" in
    -s|--screen  ) PRINTTOSCREEN=1; shift;;
    -v|--verbose ) PRINTVERBOSESCREEN=1 ; shift;;
    -h|--help )   schelp;exit;shift;;
    --) break;;
  esac
done


# main part of script

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
