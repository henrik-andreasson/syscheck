#!/bin/bash

NAME="syscheck"
VERSION="1.8.0"
DIRECTORIES="--directories /opt/syscheck"
URL="http://certificateservices.org/project/syscheck"
VENDOR="Certificate Service from CGI"
MAINTAINER="Henrik Andreasson <han@certificateservices.se>"
DESCRIPTION="syscheck is a tool to check services"
OUTPUT=..
SOURCE_PATH=.

while getopts o:v:s: flag; do
  case $flag in
    v)
	     VERSION="$OPTARG";
      ;;
    o)
  	     OUTPUT="$OPTARG";
        ;;
    s)
      	 SOURCE_PATH="$OPTARG";
        ;;
    ?)
      exit;
      ;;
  esac
done


rm -f *rpm
rm -f *deb

RPM_PKG="${OUTPUT}/${NAME}-${VERSION}.noarch.rpm"
DEB_PKG="${OUTPUT}/${NAME}_${VERSION}_noarch.deb"

fpm -s dir -t rpm -n ${NAME} -v ${VERSION} --url "${URL}" --vendor "${VENDOR}" --maintainer "${MAINTAINER}" --description "${DESCRIPTION}" ${DIRECTORIES}  --force  --exclude=".git" --config-files /opt/syscheck/config/ --prefix=/opt/syscheck --package="${RPM_PKG}" "$SOURCE_PATH"

fpm -s dir -t deb -n ${NAME} -v ${VERSION} --url "${URL}" --vendor "${VENDOR}" --maintainer "${MAINTAINER}" --description "${DESCRIPTION}" ${DIRECTORIES}  --force  --exclude=".git" --config-files /opt/syscheck/config/ --prefix=/opt/syscheck --package="${DEB_PKG}" "$SOURCE_PATH"
