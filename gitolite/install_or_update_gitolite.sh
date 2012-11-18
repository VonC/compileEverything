#!/bin/bash

gtl="${H}/gitolite"
github="${gtl}/github"

if [[ ! -e "${github}" ]] ; then
  xxgit=1 git clone -n https://github.com/sitaramc/gitolite "${github}"
  cp "${gtl}/config" "${github}/.git/config"
  cp "${gtl}/attributes" "${github}/.git/info/attributes"
  xxgit=1 git --work-tree="${github}" --git-dir="${github}/.git" checkout master
else
  xxgit=1 git --work-tree="${github}" --git-dir="${github}/.git" pull
fi
mkdir -p "${gtl}/bin"
"${github}/install" -to "${gtl}/bin"
gen_sed -i "s,\$ENV{HOME} = \$ENV,\$ENV{HOME} = '${H}' ; } # \$ENV{HOME} = \$ENV,g" "${gtl}/bin/gitolite-shell"
# gen_sed -i "s,\"/projects.list\",\"/gitolite/projects.list\",g" "${H}/.gitolite.rc"
if [[ ! -e "${H}/.ssh/gitoliteadm" ]]; then
  ssh-keygen -t rsa -f "${H}/.ssh/gitoliteadm" -C "Gitolite Admin access (not interactive)" -q -P ""
fi
# ln -fs ../../../gitolite/check_commits_strict.sh "${H}/.gitolite/hooks/common/pre-receive"

if [[ ! -e "${H}/gitolite/projects.list" ]] ; then
  GITOLITE_HTTP_HOME= gitolite setup -pk "${H}/.ssh/gitoliteadm.pub"
  gen_sed -i "s,\"/projects.list\",\"/gitolite/projects.list\",g" "${H}/.gitolite.rc"
  gen_sed -i "22a\    GITWEB_PROJECTS_LIST        => '$HOME/gitolite/projects.list'," "${H}/.gitolite.rc"
  gen_sed -i "s,0077,0007,g" "${H}/.gitolite.rc"
  gen_sed -i "s,'','.*',g" "${H}/.gitolite.rc"
  if [[ -e "${H}/projects.list" ]] ; then
    mv "${H}/projects.list" "${H}/gitolite/"
  fi
  #echo "# REPO_UMASK = 0007" >> "${H}/.gitolite.rc"
else
  GITOLITE_HTTP_HOME= gitolite setup
  rm -f "${H}/projects.list"
fi

glc=$(grep "LOCAL_CODE" "${H}/.gitolite.rc")
if [[ "${glc}" == "" ]] ; then
  a=$(grep -n ");" "${H}/.gitolite.rc")
  a=${a%%:*}
  echo $a
  gen_sed -i "${a}i\    LOCAL_CODE                  => '$HOME/gitolite'," "${H}/.gitolite.rc"
fi

if [[ ! -e "${gtl}/ga" ]]; then
  git clone gitolitesrv:gitolite-admin "${gtl}/ga"
else
  git --git-dir="${gtl}/ga/.git" --work-tree="${gtl}/ga" pull
fi
