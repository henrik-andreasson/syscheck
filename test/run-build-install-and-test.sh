#!/bin/bash

SOURCE_PATH=.
INSTALL_PATH="/opt/syscheck"
RESULT_PATH="results/"
TESTRESULT_PATH="test-results/"
WORK_PATH="."
SUDO=""

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


ABS_RESULT_PATH=$(echo "$(cd "$(dirname "$RESULT_PATH")"; pwd)/$(basename "$RESULT_PATH")")
ABS_TESTRESULT_PATH=$(echo "$(cd "$(dirname "$TESTRESULT_PATH")"; pwd)/$(basename "$TESTRESULT_PATH")")
ABS_WORK_PATH=$(echo "$(cd "$(dirname "$WORK_PATH")"; pwd)/$(basename "$WORK_PATH")")

if [ "x$INSTALL_DEPS" == "x1" ] ; then
  yum install -y ruby-devel gcc make rpm-build rubygems
  gem install --no-ri --no-rdoc fpm
fi

if [ "x${WORK_PATH}" != "x." ] ; then
  mkdir -p "${ABS_WORK_PATH}"
  cp -ra "${SOURCE_PATH}/"* "${ABS_WORK_PATH}"
  cd "${ABS_WORK_PATH}"
fi

SYSCHECK_HOME="$INSTALL_PATH"
export SYSCHECK_HOME
rm -rf $ABS_TESTRESULT_PATH/
rm -rf $ABS_RESULT_PATH/syscheck*rpm
rm -rf $ABS_RESULT_PATH/syscheck*zip
rm -rf $ABS_RESULT_PATH/syscheck*deb
mkdir -p $ABS_TESTRESULT_PATH/
mkdir -p $ABS_RESULT_PATH/

echo "<h1>test report of syscheck</h1>"                          | tee -a $ABS_TESTRESULT_PATH/summary.html
echo                                                             | tee -a $ABS_TESTRESULT_PATH/summary.html
echo "<b>start date</b>"                                         | tee -a $ABS_TESTRESULT_PATH/summary.html
date                                                             | tee -a $ABS_TESTRESULT_PATH/summary.html

echo "<h2>release build start</h2>"                              | tee -a $ABS_TESTRESULT_PATH/summary.html
rel_start=$(date +"%s")

VERSION="snapshot"
if [ "x$RELEASE" != "x" ] ; then
  VERSION="$RELEASE"
fi
echo "Building release: $VERSION"

./lib/release.sh  --program syscheck --version "$VERSION" --outpath $ABS_RESULT_PATH | tee -a $ABS_TESTRESULT_PATH/build-log.txt
rel_end=$(date +"%s")
rel_delta=$(expr $rel_end - $rel_start )
echo "release step: done in $rel_delta sec"              | tee -a $ABS_TESTRESULT_PATH/summary.html


echo "<h2>install build start</h2>"                               | tee -a $ABS_TESTRESULT_PATH/summary.html
install_start=$(date +"%s")
is_syscheck_installed=$(rpm -q syscheck)
if [ $? -eq 0 ] ; then
  $SUDO rpm -e syscheck
fi
$SUDO rpm -Uvh "$ABS_RESULT_PATH/syscheck-${VERSION}.noarch.rpm"
install_end=$(date +"%s")
install_delta=$(expr $install_end - $install_start )
echo "install step: done in $install_delta sec"          | tee -a $ABS_TESTRESULT_PATH/summary.html


ts1_start=$(date +"%s")
echo "<h2>running test suite 1</h2>"                    | tee -a $ABS_TESTRESULT_PATH/summary.html
test/bats-core/bin/bats --formatter junit test/help.bats                  | tee -a  $ABS_TESTRESULT_PATH/test_1_help.txt
ts1_end=$(date +"%s")
ts1_delta=$(expr $ts1_end - $ts1_start )
echo "test suite 1 done in $ts1_delta sec"              | tee -a $ABS_TESTRESULT_PATH/summary.html

ts2_start=$(date +"%s")
echo "<h2>running test suite 2</h2>"                    | tee -a $ABS_TESTRESULT_PATH/summary.html
test/bats-core/bin/bats --formatter junit test/help-scripts.bats          | tee -a  $ABS_TESTRESULT_PATH/test_2_help_scripts.txt
ts2_end=$(date +"%s")
ts2_delta=$(expr $ts2_end - $ts2_start )
echo "test suite 2 done in $ts2_delta sec"              | tee -a $ABS_TESTRESULT_PATH/summary.html

ts3_start=$(date +"%s")
echo "<h2>running test suite 3</h2>"                    | tee -a $ABS_TESTRESULT_PATH/summary.html
test/bats-core/bin/bats --formatter junit test/test-scripts.bats          | tee -a $ABS_TESTRESULT_PATH/test_3_scripts.txt
ts3_end=$(date +"%s")
ts3_delta=$(expr $ts3_end - $ts3_start)
echo "test suite 3 done in $ts3_delta sec"              | tee -a $ABS_TESTRESULT_PATH/summary.html

ts4_start=$(date +"%s")
echo "<h2>running test suite 4</h2>"                    | tee -a $ABS_TESTRESULT_PATH/summary.html
$SUDO test/bats-core/bin/bats --formatter junit test/test-syscheck-console.bats | tee -a  $ABS_TESTRESULT_PATH/test_4_console.txt
ts4_end=$(date +"%s")
ts4_delta=$(expr $ts4_end - $ts4_start )
echo "test suite 4 done in $ts4_delta sec"              | tee -a $ABS_TESTRESULT_PATH/summary.html

echo "end date"                                         | tee -a $ABS_TESTRESULT_PATH/summary.html
date                                                    | tee -a $ABS_TESTRESULT_PATH/summary.html
