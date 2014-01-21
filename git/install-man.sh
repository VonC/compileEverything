#!/bin/sh

# TODO func for git-htmldocs
if [[ ! -e "${H}/.cpl/src/git-manpages" ]]; then
  homed=${H##*/}
  if [[ ! -e "${H}/../.offline.${homed}" ]] ; then
    xxgit=1 git config --global --unset credential.helper
    xxgit=1 git clone https://github.com/gitster/git-manpages "${H}/.cpl/src/git-manpages"
    xxgit=1 git config --global credential.helper netrc
  else
    if [[ ! -e "${H}/.cpl/src/_pkgs/git-manpages.bundle" ]]; then
      echo "${H}/.cpl/src/_pkgs/git-manpages.bundle unavailable"  > /dev/stderr ; exit 1
    fi
    xxgit=1 git clone "${H}/.cpl/src/_pkgs/git-manpages.bundle" "${H}/.cpl/src/git-manpages"
  fi
else
  cd "${H}/.cpl/src/git-manpages"
  xxgit=1 git fetch origin
fi
cd "${H}/.cpl/src/git-manpages"
ver=$(cat "${H}/.cpl/src/git/GIT-VERSION-FILE"|grep GIT_VERSION|awk '{print $3}')
sha1=$(git log --all --pretty=format:"%H %s"|grep "${ver}-"|head -1|awk '{print $1}')
echo "ver='${ver}' => sha1='${sha1}'"
git checkout ${sha1}

if [[ ! -e "${H}/.cpl/src/_pkgs/git-manpages.bundle-${sha1}" ]]; then
  git bundle create "${H}/.cpl/src/_pkgs/git-manpages.bundle-${sha1}" --all
fi
ln -fs "git-manpages.bundle-${sha1}" "${H}/.cpl/src/_pkgs/git-manpages.bundle"


if [[ ! -e "${HUL}/share/man/man1/git.1" ]]; then
  cd "${H}/.cpl/src/git"
  make quick-install-man
  # make quick-install-html
  gver=$(readlink ${HULA}/git)
  cd ${HUL}/share/man
  cd man1
  ln -fs ../../../apps/${gver}/share/man/man1/* .
  cd ../man3
  ln -fs ../../../apps/${gver}/share/man/man3/* .
  cd ../man5
  ln -fs ../../../apps/${gver}/share/man/man5/* .
  cd ../man7
  ln -fs ../../../apps/${gver}/share/man/man7/* .
fi
