#!/bin/sh

set -e

echo "release no:"
read rel

pwd=`pwd`
basename=`basename $pwd`
rm -rf ${basename}-${rel}.zip ${basename}-${rel}
cp -r . ../${basename}-${rel}

cd ..
zip -r ${basename}-${rel}.zip ${basename}-${rel}


md5sum ${basename}-${rel}.zip > ${basename}-${rel}.zip.md5
sha1sum ${basename}-${rel}.zip > ${basename}-${rel}.zip.sha1
gpg -o ${basename}-${rel}.zip.gpg -sab ${basename}-${rel}.zip 

cd $pwd
