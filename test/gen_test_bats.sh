#!/bin/bash

for file in scripts-available/sc*sh ; do
  id=$(./$file --scriptid)
  scriptname=$(./$file --scriptname)

  echo "@test "$file" {"
  /bin/echo -e "\trun \${SYSCHECK_HOME}/$file  --screen"
  /bin/echo -e "\tline0=\$(echo \"\${lines[0]}\"  | egrep \"^$id-\" | egrep \"$scriptname\")"
  /bin/echo -e "\t[ \"\${lines[0]}\" = \"\$line0\" ]"
  echo "}"
  echo

done
