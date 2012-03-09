#!/bin/bash

gtl="${H}/gitolite"
github="${gtl}/github"

if [[ ! -e "${github}" ]] ; then
  xxgit=1 git clone https://github.com/sitaramc/gitolite "${github}"
else
  xxgit=1 git --work-tree="${github}" --git-dir="${github}/.git" pull
fi
"${github}/src/gl-system-install" "${H}/bin" "${gtl}/conf" "${gtl}/hooks"
if [[ ! -e "${H}/.ssh/gitoliteadm" ]]; then
  ssh-keygen -t rsa -f "${H}/.ssh/gitoliteadm" -C "Gitolite Admin with interactive access" -q -P ""
fi
gl-setup -q -q "${H}/.ssh/gitoliteadm.pub"
