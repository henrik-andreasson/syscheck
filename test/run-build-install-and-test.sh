#!/bin/bash

if [ "x$1" != "x" ] ; then
  SOURCE_PATH=$1
else
  echo "arg1 should be the path to source"
  exit
fi

if [ "x$2" != "x" ] ; then
  INSTALL_PATH=$2
else
  echo "arg2 should be the where syscheck is installed"
  exit
fi

if [ "x$3" != "x" ] ; then
  RESULT_PATH=$3

else
  echo "arg3 should be the where to put resulting packages and reports"
  exit
fi


if [ "x$4" != "x" ] ; then
  WORK_PATH=$4
else
    WORK_PATH="/tmp/sysceck"
fi

if [ "x$5" == "installdeps" ] ; then
  yum install -y ruby-devel gcc make rpm-build rubygems
  gem install --no-ri --no-rdoc fpm
fi

mkdir -p "$WORK_PATH"

cp -ra $SOURCE_PATH/* "$WORK_PATH"

cd "$WORK_PATH"

export SYSCHECK_HOME=$INSTALL_PATH
rm -rf $RESULT_PATH/test-reports/
rm -rf $RESULT_PATH/syscheck*rpm
rm -rf $RESULT_PATH/syscheck*zip
rm -rf $RESULT_PATH/syscheck*deb
mkdir -p $RESULT_PATH/test-reports/

echo "test report of syscheck"                          | tee -a $RESULT_PATH/test-reports/summary.txt
echo                                                    | tee -a $RESULT_PATH/test-reports/summary.txt
echo "start date"                                       | tee -a $RESULT_PATH/test-reports/summary.txt
date                                                    | tee -a $RESULT_PATH/test-reports/summary.txt

echo "release build start"                  | tee -a $RESULT_PATH/test-reports/summary.txt
rel_start=$(date +"%s")
./lib/release.sh  --program syscheck --version snapshot --outpath $RESULT_PATH | tee -a $RESULT_PATH/test-reports/build-log.txt
rel_end=$(date +"%s")
rel_delta=$(expr $rel_end - $rel_start )
echo "release step: done in $rel_delta sec"              | tee -a $RESULT_PATH/test-reports/summary.txt

install_start=$(date +"%s")
#test/bats-core/bin/bats test/test-install.bats           | tee -a  $RESULT_PATH/test-reports/test_install.txt

is_syscheck_installed=$(rpm -q syscheck)
if [ $? -eq 0 ] ; then
  rpm -e syscheck
fi
run rpm -Uvh /results/syscheck-snapshot-1.x86_64.rpm

install_end=$(date +"%s")
install_delta=$(expr $install_end - $install_start )
echo "install step: done in $install_delta sec"          | tee -a $RESULT_PATH/test-reports/summary.txt



ts1_start=$(date +"%s")
echo "running test suite 1"                             | tee -a $RESULT_PATH/test-reports/summary.txt
test/bats-core/bin/bats test/help.bats                  | tee -a  $RESULT_PATH/test-reports/test_1_help.txt
ts1_end=$(date +"%s")
ts1_delta=$(expr $ts1_end - $ts1_start )
echo "test suite 1 done in $ts1_delta sec"               | tee -a $RESULT_PATH/test-reports/summary.txt

ts2_start=$(date +"%s")
echo "running test suite 2"                             | tee -a $RESULT_PATH/test-reports/summary.txt
test/bats-core/bin/bats test/help-scripts.bats          | tee -a  $RESULT_PATH/test-reports/test_2_help_scripts.txt
ts2_end=$(date +"%s")
ts2_delta=$(expr $ts2_end - $ts2_start )
echo "test suite 2 done in $ts2_delta sec"              | tee -a $RESULT_PATH/test-reports/summary.txt

ts3_start=$(date +"%s")
echo "running test suite 3"                             | tee -a $RESULT_PATH/test-reports/summary.txt
test/bats-core/bin/bats test/test-scripts.bats          | tee -a $RESULT_PATH/test-reports/test_3_scripts.txt
ts3_end=$(date +"%s")
ts3_delta=$(expr $ts3_end - $ts3_start)
echo "test suite 3 done in $ts3_delta sec"              | tee -a $RESULT_PATH/test-reports/summary.txt

ts4_start=$(date +"%s")
echo "running test suite 4"                             | tee -a $RESULT_PATH/test-reports/summary.txt
test/bats-core/bin/bats test/test-syscheck-console.bats | tee -a  $RESULT_PATH/test-reports/test_4_console.txt
ts4_end=$(date +"%s")
ts4_delta=$(expr $ts4_end - $ts4_start )
echo "test suite 4 done in $ts4_delta sec"              | tee -a $RESULT_PATH/test-reports/summary.txt

echo "end date"                                         | tee -a $RESULT_PATH/test-reports/summary.txt
date                                                    | tee -a $RESULT_PATH/test-reports/summary.txt
