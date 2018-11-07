#!/bin/bash

NAME="syscheck"
VERSION="1.8.0"
DIRECTORIES="--directories /opt/syscheck"
URL="http://certificateservices.org/project/syscheck"
VENDOR="Certificate Service from CGI"
MAINTAINER="Henrik Andreasson <han@certificateservices.se>"
DESCRIPTION="syscheck is a tool to check services"

while getopts o:v:s: flag; do
  case $flag in
    v)
	VERSION="$OPTARG";
      ;;
    ?)
      exit;
      ;;
  esac
done


rm -f *rpm

fpm -s dir -t rpm -n ${NAME} -v ${VERSION} --url "${URL}" --vendor "${VENDOR}" --maintainer "${MAINTAINER}" --description "${DESCRIPTION}" ${DIRECTORIES}  --force  --exclude=".git" --config-files /opt/syscheck/config/ --prefix=/opt/syscheck --package=../ . 

fpm -s dir -t deb -n ${NAME} -v ${VERSION} --url "${URL}" --vendor "${VENDOR}" --maintainer "${MAINTAINER}" --description "${DESCRIPTION}" ${DIRECTORIES}  --force  --exclude=".git" --config-files /opt/syscheck/config/ --prefix=/opt/syscheck --package=../ .


