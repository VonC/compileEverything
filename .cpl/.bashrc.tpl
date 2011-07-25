#!/bin/bash
if [[ "$1" != "-force" ]]; then
  echo $0 not executed for @@TITLE@@ unles called with -force
  return 0
fi
echo $0 executed for @@TITLE@@

function bashscriptpath() {
  local _sp=$1
  local ascript="$0"
  local asp="$(dirname $0)"
  #echo "b1 asp '$asp', b1 ascript '$ascript'"
  if [[ "$asp" == "." && "$ascript" != "bash" && "$ascript" != "./.bashrc" ]] ; then asp="${BASH_SOURCE[0]%/*}"
  elif [[ "$asp" == "." && "$ascript" == "./.bashrc" ]] ; then asp=$(pwd)
  else
    if [[ "$ascript" == "bash" ]] ; then
      ascript=${BASH_SOURCE[0]}
      asp="$(dirname $ascript)"
      if [[ "$asp" == "." ]] ; then asp=$(pwd) ; fi
      #echo "bb asp '$asp', b1 ascript '$ascript'"
    fi
    #echo "b2 asp '$asp', b2 ascript '$ascript'"
    if [[ "${ascript#/}" != "$ascript" ]]; then asp=$asp ;
    elif [[ "${ascript#../}" != "$ascript" ]]; then
      asp=$(pwd)
      while [[ "${ascript#../}" != "$ascript" ]]; do
        asp=${asp%/*}
        ascript=${ascript#../}
      done
    elif [[ "${ascript#*/}" != "$ascript" ]];  then
      if [[ "$asp" == "." ]] ; then asp=$(pwd) ; else asp="$(pwd)/${asp}"; fi
    fi
  fi
  eval $_sp="'$asp'"
}

bashscriptpath H
export H=${H}
echo "bashrc set local home to '${H}'"
export HB="$H"/bin
export HU="$H"/usr
export HUL="${HU}"/local
export HULL="${HUL}"/lib
export HULI="${HUL}"/include
export HULB="${HUL}"/bin
export HULA="${HUL}"/apps
export HULS="${HUL}"/libs
alias sc='source $H/.bashrc -force'

export HISTSIZE=3000
export HISTFILE="${H}/.bash_history"
export HISTFILESIZE=2000
export HISTTIMEFORMAT='%Y-%m-%d %H:%M:%S - '
export HISTIGNORE="&:[ \t]*:exit:history:h:l"

# first override the $PATH, making sure to use *local* paths:
export PATH="${H}/bin:${HULB}:${HUL}/sbin:${HUL}/ssl/bin"
# then add the applications paths
#export PATH="$PATH:$HULA/gcc/bin"
#export PATH="$PATH:$HULA/git/bin:$HULA/svn/bin:$HULA/apache/bin"
#export PATH="$PATH:$HULA/perl/bin:$HULA/python/bin"
#export PATH="$PATH:$HULA/jdk/bin:$HULA/ant/bin"
# then add the few system paths we actually need
export PATH="${PATH}":/bin:/usr/bin/:/usr/sbin:/usr/ccs/bin:/usr/sfw/bin

export -n NGX_PM_CFLAGS
export -n CC
export -n LDDLFLAGS

export LDFLAGS="-L${HULL} -L${HUL}/ssl/lib -L${HULA}/python/lib"
export CFLAGS="-I${HULI} -I${HUL}/ssl/include -fPIC -O -U_FORTIFY_SOURCE @@M64@@"
export CPPFLAGS="$CFLAGS"
export LD_LIBRARY_PATH="${HULL}:${HUL}/ssl/lib:${HULA}/svn/lib:${HULA}/python/lib:${HULA}/gcc/lib"
export PERL5LIB="${HULA}/perl/lib/site_perl/current:${HULA}/perl/lib/current"

alias a=alias
alias l='ls -alrt'
alias h=history
alias vi=vim
if [[ -e /usr/local/bin/vim ]] ; then vimp="/usr/local/bin/vim" ; else vimp="$(which vim)" ; fi
alias vim='"${vimp}" -u "${H}/.vimrc"'

alias git="${H}/bin/wgit"

if [[ -e "${H}/.bashrc_aliases_git" ]] ; then source "${H}/.bashrc_aliases_git" ]] ; fi

if [[ ! -e "${H}/.ssh/curl-ca-bundle.crt" ]] ; then
  cp "${H}/.ssh/curl-ca-bundle.crt.tpl" "${H}/.ssh/curl-ca-bundle.crt"
fi
if [[ -e "${H}/.ssh/curl-ca-bundle.crt.secret" ]] ; then 
  a=$(tail -10 "${H}/.ssh/curl-ca-bundle.crt.secret")
  b=$(tail -10 "${H}/.ssh/curl-ca-bundle.crt")
  if [[ "$a" != "$b" ]] ; then 
    cat "${H}/.ssh/curl-ca-bundle.crt.secret" >> "${H}/.ssh/curl-ca-bundle.crt"
  fi
fi

export GIT_SSL_CAINFO="${H}/.ssh/curl-ca-bundle.crt"
if [[ ! -e "${H}/.gitconfig" ]] ; then
  cp "${H}/.cpl/.gitconfig.tpl" "${H}/.gitconfig"
fi
if [[ ! -e "${H}/.bashrc_aliases_git" ]] ; then cp "$H/.cpl/.bashrc_aliases_git.tpl" "$H/.bashrc_aliases_git" ; fi

export EDITOR=vim