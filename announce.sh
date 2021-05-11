#!/bin/bash

#
#
# # get command line arguments
# INPUTARGS=`/usr/bin/getopt --options "hsvc" --long "help,screen,verbose,cert" -- "$@"`
# if [ $? != 0 ] ; then schelp ; fi
# #echo "TEMP: >$TEMP<"
# eval set -- "$INPUTARGS"
#
# while true; do
#   case "$1" in
#     -s|--status  ) STATUS=$2; shift 2;;
#     -v|--verbose ) PRINTVERBOSESCREEN=1 ; shift;;
#     -c|--cert )   CERTFILE=$2; shift 2;;
#     -h|--help )   schelp;exit;shift;;
#     --) break;;
#   esac
# done


curl -X POST -H 'Content-Type: application/json' --data \
 '{"text":"Syscheck","attachments":[{"title":"syscheck","title_link":"https://gocd.ci.crtsrv.se/go/pipelines/","text":"Syscheck passed CI/CD"}]}' \
  https://notify.certificateservices.se/hooks/fyng5jbMLaFXG9TjK/SkgCmmj7vgEAgFGCzP98BgDEuTJDEzT2ZvgYvHbvQERpZs8Xtook
