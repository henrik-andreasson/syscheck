#!/bin/bash

# get command line arguments
INPUTARGS=`/usr/bin/getopt --options "c:i:" --long "container:,image:" -- "$@"`
if [ $? != 0 ] ; then exit ; fi
eval set -- "$INPUTARGS"

while true; do
  case "$1" in
    -c|--container ) docker_container=$2    ; shift 2;;
    -i|--image )     docker_image=$2  ; shift 2;;
    --) break;;
  esac
done

docker container inspect "${docker_container}"
if [ $? -eq 0 ] ;then
  docker container rm "${docker_container}"
fi

docker image inspect "${docker_image}"
if [ $? -eq 0 ] ;then
  docker image rm "${docker_image}"
fi
