#!/bin/bash

schelp(){

  /bin/echo
  /bin/echo -e "sysheck release tool"
  /bin/echo  "--------------------------------------"
  /bin/echo "-p|--program> 'syscheck'"
	/bin/echo "-v|--version> '1.0'"
	/bin/echo "-s|--sign> - gpg sign "
	/bin/echo "-o|--outpath> /tmp "
	/bin/echo "-g|--gittag> - tag in git"
  /bin/echo
}


# get command line arguments
INPUTARGS=`/usr/bin/getopt --options "hp:v:ogs" --long "help,program:,version:,outpath:,gittag,sign" -- "$@"`
eval set -- "$INPUTARGS"

while true; do
  case "$1" in
    -v|--version ) VERSION=$2 ; shift 2;;
    -p|--program ) PROGRAM=$2 ; shift 2;;
	-o|--outpath ) OUTPATH=$2 ; shift 2;;
	-s|--sign    ) SIGN=1 ; shift;;
	-g|--gittag  ) GITTAG=1 ; shift;;
    -h|--help )   schelp;exit;shift;;
    --) break;;
  esac
done


orgdir=`pwd`

if [ "x$VERSION" != "x" ] ; then
	rel=$VERSION
else
	echo "release no:"
	read rel
fi

if [ "x$PROGRAM" != "x" ] ; then
	progname=$PROGRAM
else
	echo "progname: (syscheck):"
	read progname
fi

if [ "x$OUTPATH" == "x" ] ; then
	OUTPATH=../releases/
fi

PROGPATH=${OUTPATH}/${progname}-${rel}

if [ ! -d "${OUTPATH}" ] ; then
    mkdir -p "${OUTPATH}"
fi

if [ "x$GITTAG" == "x1" ] ; then
	echo "git status locally:"
	git status
	echo "tag in git (Y/n)"
	read tag
	if [ "x$tag" = $"xy" -o "x$tag" = "xY" -o "x$tag" = "x" ] ; then
    git tag ${progname}-${rel}
		git push origin "${progname}-${rel}"
	fi
fi


mkdir -p                     ${PROGPATH}/config
mkdir -p                     ${PROGPATH}/misc
cp -r ./misc/make-deb.sh     ${PROGPATH}/misc/
cp -r ./config 				 ${PROGPATH}
cp -r ./console_syscheck.sh  ${PROGPATH}
cp -r ./docs                 ${PROGPATH}
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

sed -i "s/SYSCHECK_VERSION=.*/SYSCHECK_VERSION=${rel}/"  ${PROGPATH}/config/common.conf

find ${PROGPATH} -name \*.sh -exec chmod 755 {} \;
find ${PROGPATH}/scripts-available/ -name \*.sh -exec chmod 755 {} \;
find ${PROGPATH}/scripts-enabled/ -name \*.sh -exec rm {} \;
find ${PROGPATH}/related-available/ -name \*.sh -exec chmod 755 {} \;
find ${PROGPATH}/related-enabled/ -name \*.sh -exec rm {} \;
find ${PROGPATH}/ -name \*\.pl -exec chmod 755 {} \;

zipname="${progname}-${rel}.zip"
cd ${OUTPATH}
zip  -r ${zipname} ${progname}-${rel}

if [ "x$SIGN" == "x1" ] ; then

	md5sum ${zipname}          > ${zipname}.md5
	sha1sum ${zipname}         > ${zipname}.sha1
	gpg -o ${zipname}.gpg -sab   ${zipname}

fi

{
    cd ${progname}-${rel}
    ls -la
    ./misc/make-deb.sh -v ${rel} -o ".."
}

cd $orgdir
ls -la  ${OUTPATH}
