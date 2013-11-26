#!/bin/bash

if [[ ! -e "${H}/.envs.private" ]] ; then exit 0 ; fi

source "${H}/sbin/usrcmd/get_tpl_value"

get_tpl_value "${H}/.envs.private" "@UPSTREAM_URL_HGIT@" upstream_url
get_tpl_value "${H}/.envs.private" "@UPSTREAM_NAME@" upstream_name

if [[ "${upstream_url}" == "" || "${upstream_name}" == "" ]] ; then exit 0 ; fi

# A login must be defined for pushing gitolite admin repo
get_tpl_value "${H}/.envs.private" "@USER_GA_PUSH@" user_ga_push
if [[ "${user_ga_push}" == "" ]] ; then
  echo "No user is registered to push gitolite-admin to upstream url '${upstream_url}'"
  exit 0
fi

upstream_url="${upstream_url#https://}"
upstream_url="${upstream_url#*@}"
upstream_url="https://${user_ga_push}@${upstream_url#https://}"

export GIT_DIR="${H}/repositories/gitolite-admin.git"
export xxgit=1

r=$(git remote show -n ${upstream_name}|grep "https")

if [[ "${r}" == "" ]] ; then
  echo "register '${upstream_name}' as '${upstream_url}gitolite-admin'"
  git remote add ${upstream_name} ${upstream_url}gitolite-admin
fi

r=$(git remote show -n ${upstream_name}|grep "https"|grep "${user_ga_push}@")

if [[ "${r}" == "" ]] ; then
  echo "update '${upstream_name}' as '${upstream_url}gitolite-admin'"
  git remote set-url ${upstream_name} ${upstream_url}gitolite-admin
fi

if [[ -e "${H}/.gnupg/users.netrc.asc" ]]; then
  chelper=$(git config --local --get credential.helper)
  if [[ "${chelper}" == "" || "${chelper#netrc -}" == "${chelper}" ]] ; then
    git config --local credential.helper 'netrc -f ${H}/.gnupg/users.netrc.asc'
  fi
fi

gtl="${H}/gitolite"
ln -fs "../../../gitolite/post-receive-gitolite-admin" "${H}/repositories/gitolite-admin.git/hooks/post-receive"

unset xxgit
unset GIT_DIR
