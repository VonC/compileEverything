#!/bin/bash

gtl="${H}/gitolite"
github="${gtl}/github"

if [[ ! -e "${github}" ]] ; then
  xxgit=1 git clone https://github.com/sitaramc/gitolite "${github}"
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
  gen_sed -i "s,0077,0007,g" "${H}/.gitolite.rc"
  mv "${H}/projects.list" "${H}/gitolite/"
else
  GITOLITE_HTTP_HOME= gitolite setup
  rm -f "${H}/projects.list"
fi
