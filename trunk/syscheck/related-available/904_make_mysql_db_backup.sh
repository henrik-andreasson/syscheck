#!/bin/bash

# Set default home if not already set.
SYSCHECK_HOME=${SYSCHECK_HOME:-"/usr/local/syscheck"}

# Import common resources
. $SYSCHECK_HOME/config/related-scripts.conf

SCRIPTID=904

getlangfiles $SCRIPTID 
getconfig $SCRIPTID

ERRNO_1="${SCRIPTID}1"
ERRNO_2="${SCRIPTID}2"
ERRNO_3="${SCRIPTID}3"
ERRNO_4="${SCRIPTID}4"

PRINTTOSCREEN=0

schelp () {
	/bin/echo -e "$HELP"
	/bin/echo -e "$ERRNO_1/$DESCR_1 - $HELP_1"
	/bin/echo -e "$ERRNO_2/$DESCR_2 - $HELP_2"
	/bin/echo -e "$ERRNO_3/$DESCR_3 - $HELP_3"
	/bin/echo -e "${SCREEN_HELP}"
	exit
}


TEMP=`/usr/bin/getopt --options "hsymwdxb" --long "help,screen,default,daily,weekly,monthly,yearly,batch" -- "$@"`
if [ $? != 0 ] ; then help ; fi
eval set -- "$TEMP"

while true; do
  case "$1" in
    -x|--default ) TYPE=${SUBDIR_DEFAULT}; shift;;
    -d|--daily   ) TYPE=${SUBDIR_DAILY}; shift;;
    -w|--weekly  ) TYPE=${SUBDIR_WEEKLY}; shift;;
    -m|--monthly ) TYPE=${SUBDIR_MONTHLY}; shift;;
    -y|--yearly  ) TYPE=${SUBDIR_YEARLY}; shift;;
    -s|--screen ) PRINTTOSCREEN=1; shift;;
    -b|--batch )  BATCH=1; shift;;
    -h|--help )   schelp;shift;;
    --) break ;;
  esac
done

EXTRADIR=
if [ "x${TYPE}" = "x" ] ; then
	EXTRADIR=${SUBDIR_DEFAULT}	
else
	EXTRADIR=${TYPE}
fi

if [ ! -d "${MYSQLBACKUPDIR}/${EXTRADIR}" ] ; then
	printlogmess $ERROR $ERRNO_3 "$DESCR_3" "${MYSQLBACKUPDIR}/${EXTRADIR}"
	exit 1
fi

MYSQLBACKUPFULLFILENAME="${MYSQLBACKUPDIR}/${EXTRADIR}/${MYSQLBACKUPFILE}"
dumpret=$($MYSQLDUMP_BIN -u root --password="${MYSQLROOT_PASSWORD}" ${DB_NAME} 2>&1 > ${MYSQLBACKUPFULLFILENAME} )

if [ $? = 0 ] ; then
  gzip $MYSQLBACKUPFULLFILENAME
  if [ $? = 0 ] ; then
      printlogmess $INFO $ERRNO_1 "$DESCR_1" $MYSQLBACKUPFULLFILENAME.gz

      if [ "x$BATCH" = "x1" ] ; then
 	     echo "$MYSQLBACKUPFULLFILENAME.gz"
      fi
  else
      printlogmess $ERROR $ERRNO_2 "$DESCR_2" $MYSQLBACKUPFULLFILENAME
  fi  
else
  printlogmess $ERROR $ERRNO_4 "$DESCR_4" "$dumpret"
fi 






