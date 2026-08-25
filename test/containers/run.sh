#!/bin/bash
# Run the syscheck testcontainers suite.
#
#   ./run.sh                       # everything
#   ./run.sh test_sc_01_diskusage.py -v
#   ./run.sh -k diskusage
#
# Requires docker and python3-venv. The venv is created on first run.
set -e
cd "$(dirname "$0")"

if [ ! -x .venv/bin/python ] ; then
  echo "creating venv ..."
  python3 -m venv .venv
  .venv/bin/pip install -q --upgrade pip
  .venv/bin/pip install -q -r requirements.txt
fi

exec .venv/bin/python -m pytest "$@"
