#!/bin/bash
echo "Display refs in post-receive of gitolite-adm"
while read oldrev newrev ref
do
  branchname=${ref#refs/heads/}
  echo "Gitolite-admin received commit on: '${ref}' => '${branchname}'"
  if [[ "${branchname}" == "@LOCAL_GA_BRANCH@" ]] ; then
    echo "Commits on master-ext detected => pushing to @UPSTREAM_NAME@".
    git push -f @UPSTREAM_NAME@ master-ext:master
  fi
done
