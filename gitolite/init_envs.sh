#!/bin/bash

if [[ ! -e "${H}/.envs.private" ]] ; then exit 0 ; fi

source "${H}/sbin/usrcmd/get_tpl_value"

get_tpl_value "${H}/.envs.private" "@UPSTREAM_URL_HGIT@" upstream_url
get_tpl_value "${H}/.envs.private" "@UPSTREAM_NAME@" upstream_name

if [[ "${upstream_url}" == "" || "${upstream_name}" == "" ]] ; then exit 0 ; fi

gtl="${H}/gitolite"
cp_tpl "${gtl}/post-receive-gitolite-admin.tpl" "${gtl}"
ln -fs "../../../gitolite/post-receive-gitolite-admin" "${H}/repositories/gitolite-admin.git/hooks/post-receive"

r=$(GIT_DIR="${H}/repositories/gitolite-admin.git" xxgit=1 git remote show -n ${upstream_name}|grep "https")
if [[ "${r}" == "" ]] ; then
  GIT_DIR="${H}/repositories/gitolite-admin.git" xxgit=1 git remote add ${upstream_name} ${upstream_url}gitolite-admin
else
  GIT_DIR="${H}/repositories/gitolite-admin.git" xxgit=1 git remote set-url ${upstream_name} ${upstream_url}gitolite-admin
fi
