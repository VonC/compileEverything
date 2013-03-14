#!/bin/bash

gtl="${H}/gitolite"
github="${gtl}/github"
githubdir="${H}/.git/modules/gitolite"

if [[ ! -e "${github}/.git" ]] ; then
  cd "${H}"
  xxgit=1 git submodule update --init
fi
if [[ ! -e "${H}/.git/modules/gitolite/config" ]]; then
  cp "${gtl}/config" "${githubdir}/config"
  cp "${gtl}/attributes" "${githubdir}/info/attributes"
  xxgit=1 git --work-tree="${github}" --git-dir="${githubdir}" checkout master
  xxgit=1 git --work-tree="${github}" --git-dir="${githubdir}" checkout HEAD -- "{github}"
else
  xxgit=1 git --work-tree="${github}" --git-dir="${githubdir}" pull origin master
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
  chmod -R ug+rwX,o-rwx "${H}/repositories/"
  chmod -R ug-s "${H}/repositories/"
  chmod 750 "${H}/.gitolite"
  find "${H}/repositories/" -type d -print0 | xargs -0 chmod g+s
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

sshd start

if [[ ! -e "${gtl}/ga" ]]; then
  git clone gitolitesrv:gitolite-admin "${gtl}/ga"
else
  git --git-dir="${gtl}/ga/.git" --work-tree="${gtl}/ga" pull
fi

if [[ ! -e "${H}/sbin/gitolite-shell" ]] ; then cp_tpl "${H}/sbin/gitolite-shell" "${H}/sbin" ; fi
if [[ ! -e "${gtl}/VREF/CHECKID" ]] ; then cp_tpl "${gtl}/VREF/CHECKID" "${gtl}/VREF" ; fi

GL_USER=gitoliteadm gitolite print-default-rc > "${gtl}/default.gitolite.rc"
set +e
diff "${gtl}/default.gitolite.rc" "${H}/.gitolite.rc"
set -e
