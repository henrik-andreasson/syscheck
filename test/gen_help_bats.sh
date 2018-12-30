#!/bin/bash

for file in scripts-available/sc*sh ; do
  id=$(./$file --scriptid)
  humanname=$(./$file --scripthumanname)

  echo "@test "$file" {"
  /bin/echo -e "\trun \${SYSCHECK_HOME}/$file  --help"
  /bin/echo -e "\tline0=\$(echo \"\${lines[0]}\"  | grep \"$id - $humanname\")"
  /bin/echo -e "\t[ \"\${lines[0]}\" = \"\$line0\" ]"
  echo "}"
  echo

done
