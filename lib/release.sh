#!/bin/bash

orgdir=`pwd`

echo "release no:"
read rel

echo "progname: (syscheck):"
read progname
if [ "x${progname}" = "x" ] ; then
	progname=syscheck
fi



find . -name \*.sh -exec chmod 755 {} \;

OUTPATH=../releases/
PROGPATH=${OUTPATH}/${progname}-${rel}

if [ ! -d "${OUTPATH}" ] ; then
    mkdir -p "${OUTPATH}"
fi

echo "git status locally:"
git status
echo "tag in git (Y/n)"
read tag
if [ "x$tag" = $"xy" -o "x$tag" = "xY" -o "x$tag" = "x" ] ; then
        git tag ${progname}-${rel}
	git push origin "${progname}-${rel}"
fi

cp -r ./config 							 ${PROGPATH}
cp -r ./console_syscheck.sh  ${PROGPATH}
cp -r ./doc                  ${PROGPATH}
cp -r ./getroot.sh           ${PROGPATH}
cp -r ./lang                 ${PROGPATH}
cp -r ./lib                  ${PROGPATH}
cp -r ./logbook.sh           ${PROGPATH}
cp -r ./readme.md            ${PROGPATH}
cp -r ./related-available    ${PROGPATH}
cp -r ./related-enabled      ${PROGPATH}
cp -r ./scripts-available    ${PROGPATH}
cp -r ./scripts-enabled      ${PROGPATH}
cp -r ./syscheck.sh          ${PROGPATH}
cp -r ./var                  ${PROGPATH}

perl -pi -e "s/SYSCHECK_VERSION=.*/SYSCHECK_VERSION=${rel}/gi"  ${PROGPATH}/config/common.conf
find ${PROGPATH} -name \*.sh -exec chmod 755 {} \;
find ${PROGPATH}/scripts-available/ -name \*.sh -exec chmod 755 {} \;
find ${PROGPATH}/scripts-enabled/ -name \*.sh -exec rm {} \;
find ${PROGPATH}/related-available/ -name \*.sh -exec chmod 755 {} \;
find ${PROGPATH}/related-enabled/ -name \*.sh -exec rm {} \;
find ${PROGPATH}/ -name \*\.pl -exec chmod 755 {} \;

zipname="${progname}-${rel}.zip"
cd ${OUTPATH}
zip --exclude "${progname}-${rel}/.git/*" -r ${zipname} ${progname}-${rel}

md5sum ${zipname}          > ${zipname}.md5
sha1sum ${zipname}         > ${zipname}.sha1
gpg -o ${zipname}.gpg -sab   ${zipname}

cd ${progname}-${rel} ; ./misc/make-rpm-deb.sh -v ${rel}


cd $orgdir
ls -la ${PROGPATH} ${OUTPATH}/${zipname} ${OUTPATH}/${zipname}.md5 ${OUTPATH}/${zipname}.sha1 ${OUTPATH}/${zipname}.gpg
