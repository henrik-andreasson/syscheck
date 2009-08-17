#!/bin/sh

# Set default home if not already set.
SYSCHECK_HOME=${SYSCHECK_HOME:-"/usr/local/syscheck"}


## Import common definitions ##
. $SYSCHECK_HOME/resources.sh



OUTPUT=/tmp/syscheckdoc.html



echo "<h1>Syscheck version $SYSCHECK_VERSION </h1>" > ${OUTPUT}
echo "<b>Dokumentation generated: </b>" >> ${OUTPUT}
date >> ${OUTPUT}


cd $SYSCHECK_HOME/related-available
for file in * ; do 
	echo "<h1>$file</h1><pre>" >> ${OUTPUT} 
	./$file --help             >> ${OUTPUT}
	echo "</pre>"              >> ${OUTPUT}
done

cd $SYSCHECK_HOME/scripts-available
for file in * ; do 
	echo "<h1>$file</h1><pre>" >> ${OUTPUT} 
	./$file --help             >> ${OUTPUT}
	echo "</pre>"              >> ${OUTPUT}
done

echo "Syscheck doc is at: $OUTPUT"
