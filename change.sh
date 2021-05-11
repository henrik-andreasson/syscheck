#!/bin/bash

git clone http://changes:${git_pass_changes}@gitea.ci.crtsrv.se/cicd/changes.git

cd changes

if [ "x${RELEASE}" != "x" ] ; then
  release_dir="${GO_PIPELINE_NAME}/${RELEASE}"
else
  release_dir="${GO_PIPELINE_NAME}/${GO_PIPELINE_COUNTER}"
fi

mkdir -p "${release_dir}"

cp template/instruction.md "${release_dir}"
cp template/notes.md "${release_dir}"

mkdir -p "${release_dir}/cicd"
cp ../reports/* "${release_dir}/cicd"

git add "${release_dir}"

git config user.name "change"
git commit -m "${release_dir}"

git push
