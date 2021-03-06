#!/bin/bash

SYSCHECK_HOME="${SYSCHECK_HOME:-/opt/syscheck}" # use default if  unset
if [ ! -f ${SYSCHECK_HOME}/syscheck.sh ] ; then
  echo "Can't find $SYSCHECK_HOME/syscheck.sh"
  exit
fi

if [ ! -f ${SYSCHECK_HOME}/syscheck.sh ] ; then echo "Can't find $SYSCHECK_HOME/syscheck.sh" ;exit ; fi

## Import common definitions ##
source $SYSCHECK_HOME/config/related-scripts.conf

SCRIPTNAME=copy_ejbca_conf

# uniq ID of script (please use in the name of this file also for convinice for finding next availavle number)
SCRIPTID=913


# how many info/warn/error messages
NO_OF_ERR=2
initscript $SCRIPTID $NO_OF_ERR

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

# Make sure you add quotation marks for the first argument when adding new files that should be copied, for exampel.
# $SYSCHECK_HOME/related-available/906_ssh-copy-to-remote-machine.sh "$EJBCA_HOME/conf/*.properties" $HOSTNAME_NODE2 $EJBCA_HOME/conf/

echo ""
read -p "Do you want to send EJBCA conf to $HOSTNAME_NODE2 (y/N):" question

if [ "x$question" = "xy" ] ; then
        ${SYSCHECK_HOME}/related-enabled/915_remote_command_via_ssh.sh ${HOSTNAME_NODE2} "mkdir -p /tmp/backup_ejbca/conf/" ${SSH_USER}
	$SYSCHECK_HOME/related-enabled/906_ssh-copy-to-remote-machine.sh -s "$EJBCA_HOME/conf/*" $HOSTNAME_NODE2 /tmp/backup_ejbca/conf/ $SSH_USER

	echo "#######################################################"
	echo "#                                                     #"
	echo "# The conf/ directory is placed in /tmp/backup_ejbca/ #"
	echo "# You have to manually move it to \$EJBCA_HOME/        #"
	echo "# You also have to change the user and group rights   #"
	echo "#                                                     #"
	echo "#######################################################"

	if [ $? -ne 0 ] ; then
		echo "Failed to contact other host"
	fi
else
	echo "Configuration not copied."
fi

echo ""
read -p "Do you want to send EJBCA keys to $HOSTNAME_NODE2 (y/N):" question

if [ "x$question" = "xy" ] ; then
        ${SYSCHECK_HOME}/related-enabled/915_remote_command_via_ssh.sh ${HOSTNAME_NODE2} "mkdir -p /tmp/backup_ejbca/p12/" ${SSH_USER}
	$SYSCHECK_HOME/related-enabled/906_ssh-copy-to-remote-machine.sh -s "$EJBCA_HOME/p12/*" $HOSTNAME_NODE2 /tmp/backup_ejbca/p12/ $SSH_USER

	echo "######################################################"
	echo "#                                                    #"
	echo "# The p12/ directory is placed in /tmp/backup_ejbca/ #"
	echo "# You have to manually move it to \$EJBCA_HOME/       #"
	echo "# You also have to change the user and group rights  #"
	echo "#                                                    #"
	echo "######################################################"

	if [ $? -ne 0 ] ; then
		echo ""
		echo "Failed to contact other host"
	fi
else
        echo "Keys not copied."
fi

echo ""
read -p "Do you want to send syscheck to $HOSTNAME_NODE2 (y/N):" question

if [ "x$question" = "xy" ] ; then
	$SYSCHECK_HOME/related-enabled/906_ssh-copy-to-remote-machine.sh -s "$SYSCHECK_HOME/" $HOSTNAME_NODE2 /tmp/backup_syscheck $SSH_USER
	if [ $? -eq 0 ] ; then
		echo "####################################################################"
		echo "#                                                                  #"
		echo "# The syscheck directory is placed in /tmp/backup_syscheck/        #"
		echo "# You have to manually move it to \$SYSCHECK_HOME/ and change the   #"
		echo "# owner to root and the name of the directory.                     #"
		echo "#                                                                  #"
		echo "# Before you can move /tmp/backup_syscheck/ you have to remove     #"
		echo "# \$SYSCHECK_HOME/ or move it to a different location.              #"
                echo "#                                                                  #"
                echo "# Example:                                                         #"
		echo "# mv /tmp/backup_syscheck \$SYSCHECK_HOME/                          #"
                echo "# chown -R root:root \$SYSCHECK_HOME/                               #"
                echo "#                                                                  #"
		echo "####################################################################"
		echo ""
	else
		echo "Failed to contact other host"
	fi
else
        echo "Syscheck not copied."
fi
