#!/bin/sh

set -e

echo "release no:"
read rel

echo "progname: (syscheck):"
read progname
if [ "x${progname}" = "x" ] ; then
	progname=syscheck
fi

perl -pi -e 's/SYSCHECK_VERSION=.*/SYSCHECK_VERSION=${rel}/gio' resources.sh


find . -name \*.sh -exec chmod 755 {} \;

svn export . ../${progname}-${rel}
find ../${progname}-${rel} -name \*.sh -exec chmod 755 {} \;
find ../${progname}-${rel}/scripts-enabled/ -name \*.sh -exec chmod 755 {} \;
find ../${progname}-${rel}/related-enabled/ -name \*.sh -exec chmod 755 {} \;
find ../${progname}-${rel}/ -name \*\.pl -exec chmod 755 {} \;

zipname="${progname}-${rel}.zip"
cd ..
zip -r ${zipname} ${progname}-${rel}


md5sum ${zipname}          > ${zipname}.md5
sha1sum ${zipname}         > ${zipname}.sha1
gpg -o ${zipname}.gpg -sab   ${zipname} 

cd -
