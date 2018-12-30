#!/bin/bash
cd $1

export SYSCHECK_HOME=$2

./lib/release.sh  --program syscheck --version snapshot --outpath $1

rpm -Uvh /$1/syscheck-snapshot-1.x86_64.rpm

test/bats-core/bin/bats test/help.bats

test/bats-core/bin/bats test/help-scripts.bats

test/bats-core/bin/bats test/test-scripts.bats
