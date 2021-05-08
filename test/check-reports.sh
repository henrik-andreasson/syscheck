#!/bin/bash

if [ "x$1" != "x" ] ; then
  RESULT_PATH="test-results/"
else
  RESULT_PATH="$1"
fi

is_ok=0
# 0 = ok
# 1 =fail
for file in $(ls ${RESULT_PATH}) ; do

  CHECK_ERROR=$(cat ${RESULT_PATH}/$file | grep -v '^#' | grep ^not)

  if [ "x${CHECK_ERROR}" != "x" ] ; then
    echo "errors found in report ${RESULT_PATH}/$file"
    let ++is_ok
  else
    echo "report: ${RESULT_PATH}/$file seems fine "
  fi
done

exit $is_ok
