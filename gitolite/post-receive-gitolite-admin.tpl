#!/bin/bash
echo "Display refs in post-receive of gitolite-adm"
fenv="${H}/../.envs.private"
while read oldrev newrev ref
do
  branchname=${ref#refs/heads/}
  echo "Gitolite-admin received commit on: '${ref}' => '${branchname}'"
  if [[ "${branchname}" == "@LOCAL_GA_BRANCH@" ]] ; then
    if [[ -e "${fenv}" ]] ; then
      echo "Commits on master-ext detected => pushing to @UPSTREAM_NAME@".
      cp "${fenv}" "${H}/.netrc"
      git push -f @UPSTREAM_NAME@ @LOCAL_GA_BRANCH@:master
      rm "${H}/.netrc"
    fi
  fi
done
