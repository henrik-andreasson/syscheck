#!/bin/sh

# Set default home if not already set.
SYSCHECK_HOME=${SYSCHECK_HOME:-"/usr/local/syscheck"}


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
