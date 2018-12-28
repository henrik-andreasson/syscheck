#!/bin/bash

# Set SYSCHECK_HOME if not already set.

SYSCHECK_HOME="${SYSCHECK_HOME:-/opt/syscheck}" # use default if  unset
if [ ! -f ${SYSCHECK_HOME}/syscheck.sh ] ; then 
  echo "Can't find $SYSCHECK_HOME/syscheck.sh"
  exit 
fi
if [ "x${SYSCHECK_HOME}" = "x" ] ; then
# 2. Check if /etc/syscheck.conf exists then source that (put SYSCHECK_HOME=/path/to/syscheck in ther)
    if [ -e /etc/syscheck.conf ] ; then 
	source /etc/syscheck.conf 
    else
# 3. last resort use default path
	SYSCHECK_HOME="/opt/syscheck"
    fi
fi

if [ ! -f ${SYSCHECK_HOME}/syscheck.sh ] ; then echo "Can't find $SYSCHECK_HOME/syscheck.sh" ;exit ; fi





## Import common definitions ##
. $SYSCHECK_HOME/config/common.conf



OUTPUT=/tmp/syscheckdoc.wiki



echo "= Syscheck version $SYSCHECK_VERSION =" > ${OUTPUT}
echo "!!!Documentation generated: !!!" >> ${OUTPUT}
date >> ${OUTPUT}


cd $SYSCHECK_HOME/related-available
for file in * ; do 
	echo "==  $file ==  {{{  " >> ${OUTPUT} 
	./$file --help             >> ${OUTPUT}
	echo "  }}} "              >> ${OUTPUT}
done

cd $SYSCHECK_HOME/scripts-available
for file in * ; do 
	echo " == $file == {{{   " >> ${OUTPUT} 
	./$file --help             >> ${OUTPUT}
	echo " }}}"              >> ${OUTPUT}
done

echo "Syscheck doc is at: $OUTPUT"
