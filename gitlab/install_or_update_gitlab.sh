#!/bin/bash

gtl="${H}/gitlab"
github="${gtl}/github"

if [[ ! -e "${github}" ]] ; then
  xxgit=1 git clone https://github.com/gitlabhq/gitlabhq "${github}"
else
  xxgit=1 git --work-tree="${github}" --git-dir="${github}/.git" pull
fi
