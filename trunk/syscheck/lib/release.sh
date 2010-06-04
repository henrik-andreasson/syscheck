#!/bin/sh

#set -e

orgdir=`pwd`

echo "release no:"
read rel

echo "progname: (syscheck):"
read progname
if [ "x${progname}" = "x" ] ; then
	progname=syscheck
fi



find . -name \*.sh -exec chmod 755 {} \;

OUTPATH=../../releases/
PROGPATH=${OUTPATH}/${progname}-${rel}


svn export . ${PROGPATH}
perl -pi -e "s/SYSCHECK_VERSION=.*/SYSCHECK_VERSION=${rel}/gi"  ${PROGPATH}/resources.sh
find ${PROGPATH} -name \*.sh -exec chmod 755 {} \;
find ${PROGPATH}/scripts-available/ -name \*.sh -exec chmod 755 {} \;
find ${PROGPATH}/scripts-enabled/ -name \*.sh -exec rm {} \;
find ${PROGPATH}/related-available/ -name \*.sh -exec chmod 755 {} \;
find ${PROGPATH}/related-enabled/ -name \*.sh -exec rm {} \;
find ${PROGPATH}/ -name \*\.pl -exec chmod 755 {} \;

zipname="${progname}-${rel}.zip"
cd ${OUTPATH}
zip -r ${zipname} ${progname}-${rel}


md5sum ${zipname}          > ${zipname}.md5
sha1sum ${zipname}         > ${zipname}.sha1
gpg -o ${zipname}.gpg -sab   ${zipname} 

cd $orgdir
ls -la ${PROGPATH} ${OUTPATH}/${zipname} ${OUTPATH}/${zipname}.md5 ${OUTPATH}/${zipname}.sha1 ${OUTPATH}/${zipname}.gpg
