#!/bin/bash

SOURCE_PATH=.
INSTALL_PATH="/opt/syscheck"
RESULT_PATH="results/"
TESTRESULT_PATH="test-results/"
WORK_PATH="."
SUDO=""

# get command line arguments
INPUTARGS=`/usr/bin/getopt --options "s:r:i:w:dot:" --long "source:,results:,install:,work:,deps,sudo,test" -- "$@"`
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

pwd

find . -ls

if [ "x$INSTALL_DEPS" == "x1" ] ; then
  yum install -y ruby-devel gcc make rpm-build rubygems
  gem install --no-ri --no-rdoc fpm
fi

mkdir -p "$WORK_PATH"

cp -ra $SOURCE_PATH/* "$WORK_PATH"

cd "$WORK_PATH"

export SYSCHECK_HOME=$INSTALL_PATH
rm -rf $TESTRESULT_PATH/
rm -rf $RESULT_PATH/syscheck*rpm
rm -rf $RESULT_PATH/syscheck*zip
rm -rf $RESULT_PATH/syscheck*deb
mkdir -p $TESTRESULT_PATH/
mkdir -p $RESULT_PATH/

echo "test report of syscheck"                          | tee -a $TESTRESULT_PATH/summary.txt
echo                                                    | tee -a $TESTRESULT_PATH/summary.txt
echo "start date"                                       | tee -a $TESTRESULT_PATH/summary.txt
date                                                    | tee -a $TESTRESULT_PATH/summary.txt

echo "release build start"                              | tee -a $TESTRESULT_PATH/summary.txt
rel_start=$(date +"%s")
./lib/release.sh  --program syscheck --version snapshot --outpath $RESULT_PATH | tee -a $TESTRESULT_PATH/build-log.txt
ls -la $RESULT_PATH
rel_end=$(date +"%s")
rel_delta=$(expr $rel_end - $rel_start )
echo "release step: done in $rel_delta sec"              | tee -a $TESTRESULT_PATH/summary.txt


echo "install build start"                               | tee -a $TESTRESULT_PATH/summary.txt
install_start=$(date +"%s")
is_syscheck_installed=$(rpm -q syscheck)
if [ $? -eq 0 ] ; then
  $SUDO rpm -e syscheck
fi
$SUDO rpm -Uvh $RESULT_PATH/syscheck-snapshot-1.x86_64.rpm
install_end=$(date +"%s")
install_delta=$(expr $install_end - $install_start )
echo "install step: done in $install_delta sec"          | tee -a $TESTRESULT_PATH/summary.txt

find . -ls


ts1_start=$(date +"%s")
echo "running test suite 1"                             | tee -a $TESTRESULT_PATH/summary.txt
test/bats-core/bin/bats test/help.bats                  | tee -a  $TESTRESULT_PATH/test_1_help.txt
ts1_end=$(date +"%s")
ts1_delta=$(expr $ts1_end - $ts1_start )
echo "test suite 1 done in $ts1_delta sec"               | tee -a $TESTRESULT_PATH/summary.txt

ts2_start=$(date +"%s")
echo "running test suite 2"                             | tee -a $TESTRESULT_PATH/summary.txt
test/bats-core/bin/bats test/help-scripts.bats          | tee -a  $TESTRESULT_PATH/test_2_help_scripts.txt
ts2_end=$(date +"%s")
ts2_delta=$(expr $ts2_end - $ts2_start )
echo "test suite 2 done in $ts2_delta sec"              | tee -a $TESTRESULT_PATH/summary.txt

ts3_start=$(date +"%s")
echo "running test suite 3"                             | tee -a $TESTRESULT_PATH/summary.txt
test/bats-core/bin/bats test/test-scripts.bats          | tee -a $TESTRESULT_PATH/test_3_scripts.txt
ts3_end=$(date +"%s")
ts3_delta=$(expr $ts3_end - $ts3_start)
echo "test suite 3 done in $ts3_delta sec"              | tee -a $TESTRESULT_PATH/summary.txt

ts4_start=$(date +"%s")
echo "running test suite 4"                             | tee -a $TESTRESULT_PATH/summary.txt
$SUDO test/bats-core/bin/bats test/test-syscheck-console.bats | tee -a  $TESTRESULT_PATH/test_4_console.txt
ts4_end=$(date +"%s")
ts4_delta=$(expr $ts4_end - $ts4_start )
echo "test suite 4 done in $ts4_delta sec"              | tee -a $TESTRESULT_PATH/summary.txt

echo "end date"                                         | tee -a $TESTRESULT_PATH/summary.txt
date                                                    | tee -a $TESTRESULT_PATH/test-reports/summary.txt
