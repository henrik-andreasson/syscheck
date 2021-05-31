#!/bin/bash

git clone http://changes:${git_pass_changes}@gitea.ci.crtsrv.se/cicd/changes.git

cd changes

if [ "x${RELEASE}" != "x" ] ; then
  release_dir="${GO_PIPELINE_NAME}/${RELEASE}"
  release_no="${RELEASE}"
else
  release_dir="${GO_PIPELINE_NAME}/${GO_PIPELINE_COUNTER}"
  release_no="${GO_PIPELINE_COUNTER}"
fi

mkdir -p "${release_dir}"

echo "# Release: $release_no" > "${release_dir}/instruction.md"
echo "Date: $(date) "        >> "${release_dir}/instruction.md"
cat template/instruction.md  >> "${release_dir}/instruction.md"

echo "# Release: $release_no" > "${release_dir}/notes.md"
echo "Date: $(date) "        >> "${release_dir}/notes.md"
cat  template/notes.md       >> "${release_dir}/notes.md"

mkdir -p "${release_dir}/cicd"
cp ../reports/* "${release_dir}/cicd"

git add "${release_dir}"

git config user.name "change"
git commit -m "${release_dir}"

git push
