#!/bin/sh

set -e

echo "release no:"
read rel

echo "progname: (syscheck):"
read progname
if [ "x${progname}" = "x" ] ; then
	progname=syscheck
fi

svn export . ../${progname}-${rel}

zipname="${progname}-${rel}.zip"
cd ..
zip -r ${zipname} ${progname}-${rel}


md5sum ${zipname}          > ${zipname}.md5
sha1sum ${zipname}         > ${zipname}.sha1
gpg -o ${zipname}.gpg -sab   ${zipname} 

cd -
