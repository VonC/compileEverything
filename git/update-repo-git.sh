#!/bin/sh

if [[ ! -e "${H}/.git" ]] ; then

  homed=${H##*/};
  if [[ ! -e "${H}/../.offline.${homed}" ]]; then
    xxgit=1 git clone --bare https://VonC@github.com/VonC/compileEverything "${H}/.git"
  else
    file=$(ls -rt1 "${H}/.cpl/src/_pkgs/repos/"|grep -i compileEverything|grep bundle|tail -1);
    if [[ "${file}" == "" ]]; then
      echo "no compileEverything bundle found" ; exit 1 ;
    fi;
    xxgit=1 git clone --bare "${H}/.cpl/src/_pkgs/repos/${file}" "${H}/.git"
  fi

  xxgit=1 git config --local --bool core.bare false
  xxgit=1 git reset HEAD -- .
  xxgit=1 git config --local remote.origin.fetch +refs/heads/*:refs/remotes/origin/*
  xxgit=1 git fetch origin
  xxgit=1 git branch -u origin/master master
  xxgit=1 git reset HEAD -- .

fi

cp_tpl "${H}/.cpl/.gitconfig.tpl" "${H}"; 
set +e; complete -r git ; set -e
"${H}/.gnupg/ini-git-credential-netrc"
git config --local credential.helper netrc
