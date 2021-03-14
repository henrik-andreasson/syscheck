#!/bin/bash

RESULT_PATH="results/"

# get command line arguments
INPUTARGS=`/usr/bin/getopt --options "s:r:i:w:dot:" --long "source:,results:,install:,work:,deps,sudo,test:" -- "$@"`
if [ $? != 0 ] ; then exit ; fi
eval set -- "$INPUTARGS"

while true; do
  case "$1" in
    -o|--sudo )    SUDO="sudo"     ; shift;;
    -s|--source )  SOURCE_PATH=$2  ; shift 2;;
    -r|--results ) RESULT_PATH=$2  ; shift 2;;
    -i|--install ) INSTALL_PATH=$2 ; shift 2;;
    -t|--test    ) TESTRESULT_PATH=$2 ; shift 2;;
    -w|--work )    WORK_PATH=$2    ; shift 2;;
    -d|--deps )    INSTALL_DEPS=1  ; shift;;
    --) break;;
  esac
done

cd ${RESULT_PATH}

CHECK_ERROR=$(grep -i error summary.html build-log.txt test_1_help.txt test_2_help_scripts.txt test_3_scripts.txt test_4_console.txt)

if [ "x${CHECK_ERROR}" != "x" ] ; then
  echo "errors found in reports"
  exit 1
else
  echo "reports seems fine "
  exit 0
fi
