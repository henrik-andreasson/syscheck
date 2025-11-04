#!/bin/bash

SYSCHECK_HOME="${SYSCHECK_HOME:-/opt/syscheck}" # use default if  unset
if [ ! -f ${SYSCHECK_HOME}/syscheck.sh ] ; then
  echo "Can't find $SYSCHECK_HOME/syscheck.sh"
  exit
fi

if [ ! -f ${SYSCHECK_HOME}/syscheck.sh ] ; then echo "Can't find $SYSCHECK_HOME/syscheck.sh" ;exit ; fi

## Import common definitions ##
source $SYSCHECK_HOME/config/syscheck-scripts.conf

# script name, used when integrating with nagios/icinga
SCRIPTNAME=rittal_rack_sensors

# uniq ID of script (please use in the name of this file also for convinice for finding next availavle number)
SCRIPTID=43

# how many info/warn/error messages
NO_OF_ERR=2
initscript $SCRIPTID $NO_OF_ERR

default_script_getopt $*

# main part of script

SCRIPTINDEX=$(addOneToIndex $SCRIPTINDEX)

# Test loop boolean operand
Sub_Compare()(

  exec test $*
)

# Check Rittal
Sub_Check_Rittal(){
    SNMP_TRAP=$1
    RESULT=$2
    SCRIPTINDEX=$3
    OPERAND=$4
    HOST=$5

    STATUS=$(egrep "${SNMP_TRAP} =" /tmp/snmp.txt |awk '{print $9}'|sed 's/Value//;s/^$//;/^$/d;s/ //g')
    SNMP_OBJECT=$(egrep "${SNMP_TRAP} =" /tmp/snmp.txt |awk '{print $8}')

    if Sub_Compare "${STATUS} ${OPERAND} ${RESULT}" ; then
      printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[1]} -d "${DESCR[1]}" -1 "${HOST} ${SNMP_OBJECT} ${STATUS} shulde be ${RESULT}"
    else
   	  printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $INFO -e ${ERRNO[2]}  -d "${DESCR[2]}" -1 "${HOST} ${SNMP_OBJECT} ${STATUS}"
    fi
}

# Get info from rack censors

Sub_Get_Snmp_Info(){
	HOST=$1
	snmpwalk -v2c -c public ${HOST} 1.3.6.1.4.1.2606.7.4.3.2.1.16 > /tmp/${HOST}.txt
}

for (( i = 0 ;  i < ${#HOSTS[@]} ; i++ )) ; do
    Sub_Get_Snmp_Info ${HOSTS[$i]}
        if [ $? != 1 ];then
		printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[1]} -d "${DESCR[1]}" -1 "Can't connect to ${HOST}"
        else
                for (( j = 0 ;  j < ${#SNMP[@]} ; j++ )) ; do
                SCRIPTINDEX=$(addOneToIndex $SCRIPTINDEX)
                Sub_Check_Rittal ${SNMP[$j]}  ${RESULT[$j]} $SCRIPTINDEX ${OPERAND[$j]} ${HOSTS[$i]}
                done
       fi

done
