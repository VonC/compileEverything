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
  #echo "D: b1 asp '$asp', b1 ascript '$ascript'"
  if [[ "$asp" == "." && "$ascript" != "bash" && "$ascript" != "./.bashrc" ]] ; then asp="${BASH_SOURCE[0]%/*}"
  elif [[ "$asp" == "." && "$ascript" == "./.bashrc" ]] ; then asp=$(pwd)
  else
    if [[ "$ascript" == "bash" ]] ; then
      ascript=${BASH_SOURCE[0]}
      asp="$(dirname $ascript)"
      if [[ "$asp" == "." ]] ; then asp=$(pwd) ; fi
      #echo "D: bb asp '$asp', b1 ascript '$ascript'"
    fi
    #echo "D: b2 asp '$asp', b2 ascript '$ascript'"
    if [[ "${ascript#/}" != "$ascript" ]]; then asp=$asp ;
    elif [[ "${ascript#../}" != "$ascript" ]]; then
      asp=$(pwd)
      while [[ "${ascript#../}" != "$ascript" ]]; do
        asp=${asp%/*}
        ascript=${ascript#../}
      done
    elif [[ "${ascript#*/}" != "$ascript" ]];  then
      if [[ "$asp" == "." ]] ; then asp=$(pwd) ; elif [[ "${asp#/}" == "${asp}" ]]; then asp="$(pwd)/${asp}"; fi
    fi
  fi
  eval $_sp="'$asp'"
}

bashscriptpath H
export H=${H}
export HOME=${H}
echo "bashrc set local home to '${H}'"
export HB="$H"/bin
export HS="$H"/sbin
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
export HISTIGNORE="&:[ ]*:exit:history:h:l"

# first override the $PATH, making sure to use *local* paths:
export PATH="${H}/sbin:${H}/bin:${HULB}:${HUL}/sbin:${HUL}/ssl/bin"
# then add the applications paths
#export PATH="$PATH:$HULA/gcc/bin"
#export PATH="$PATH:$HULA/git/bin:$HULA/svn/bin:$HULA/apache/bin"
#export PATH="$PATH:$HULA/perl/bin:$HULA/python/bin"
#export PATH="$PATH:$HULA/jdk/bin:$HULA/ant/bin"
# then add the few system paths we actually need
if [[ -e "${HUL}/jdk6" ]] ; then
  export JAVA_HOME="${HUL}/jdk6"
  export PATH="${PATH}":"${JAVA_HOME}/bin"
else
  export JAVA_HOME=""
fi
if [[ -e "${HUL}/apps/ant" ]] ; then 
  export ANT_HOME="${HUL}/apps/ant"
else
  export -n ANT_HOME
fi
#export GITOLITE_HTTP_HOME=${H}
export GITOLITE_HOME="${H}/gitolite"
export PATH="${PATH}":"${GITOLITE_HOME}/bin"
export PATH="${PATH}":/usr/local/bin:/bin:/usr/bin/:/usr/sbin:/usr/ccs/bin:/usr/sfw/bin

export -n NGX_PM_CFLAGS
export -n CC
export CC=gcc
export -n LDDLFLAGS
export -n LD_LIBRARY_PATH
export -n PKG_CONFIG_PATH
export -n PERL_LIB
export -n NGX_AUX

export LD_RUN_PATH="${HULL}:${HUL}/ssl/lib:${HULA}/svn/lib:${HULA}/python/lib:${HULA}/gcc/lib"
export LDFLAGS="-L${HULL} -L${HUL}/ssl/lib -L${HULA}/python/lib -Wl,-rpath=${LD_RUN_PATH}"
export CFLAGS="-I${HULI} -I${HUL}/ssl/include -fPIC -O -U_FORTIFY_SOURCE @@M64@@ @@CYGWIN@@"
export CPPFLAGS="$CFLAGS"
export PERL5LIB="${HULA}/perl/lib/site_perl/current:${HULA}/perl/lib/current"

export SSL_CERT_FILE="${H}/openssl/cert.pem"

export LYNX_CFG="${H}/lynx/lynx.cfg"

export CATALINA_HOME="${H}/usr/local/apps/tomcat"
export CATALINA_BASE="${H}/tomcat"

alias a=alias
alias l='ls -alrt'
alias h=history
alias vi=vim
alias t='tail --follow=name'
alias tl='while ! tail --max-unchanged-stats=2 --follow=name "${H}/.lastlog" ; do sleep 2 ; done'
alias psw='ps auxwww|grep "${H}"|grep -v grep|grep'

if [[ -e /usr/local/bin/vim ]] ; then vimp="/usr/local/bin/vim" ; else vimp="$(which vim)" ; fi
alias vim='"${vimp}" -u "${H}/.vimrc"'

oag=$(alias git 2>/dev/null| grep "${H}" | grep " u ")
if [[ "${oag}" == "" ]] ; then
  alias git="${H}/sbin/wgit"
fi

if [[ -e "${H}/.bashrc_aliases_git" ]] ; then source "${H}/.bashrc_aliases_git" ]] ; fi

if [[ ! -e "${H}/.ssh/curl-ca-bundle.crt" ]] ; then cp "${H}/.cpl/scripts/curl-ca-bundle.crt" "${H}/.ssh"; fi
if [[ -e "${H}/.ssh/curl-ca-bundle.crt.secret" ]] ; then
  a=$(tail -10 "${H}/.ssh/curl-ca-bundle.crt.secret")
  b=$(tail -10 "${H}/.ssh/curl-ca-bundle.crt")
  if [[ "$a" != "$b" ]] ; then
    cat "${H}/.ssh/curl-ca-bundle.crt.secret" >> "${H}/.ssh/curl-ca-bundle.crt"
  fi
fi

export GIT_SSL_CAINFO="${H}/.ssh/curl-ca-bundle.crt"
if [[ ! -e "${H}/.gitconfig" ]] ; then
  "${H}/sbin/cp_tpl" "${H}/.cpl/.gitconfig.tpl" "${H}"
fi
if [[ ! -e "${H}/.bashrc_aliases_git" ]] ; then cp "$H/.cpl/.bashrc_aliases_git.tpl" "$H/.bashrc_aliases_git" ; fi

export EDITOR=vim

findg() { find . -name '*' |  xargs grep -nHr "$1" ; }

if [[ -e "${H}/.proxy" ]] ; then source "${H}/.proxy" ; fi

alias gr='git update-index --assume-unchanged "${H}/README.md"'

if [[ ! ${ce_key128} ]] ; then
  ce_key128=$(echo "key-$RANDOM-$$-$(date)" | md5sum | md5sum)
  ce_key128=${ce_key128:0:32}
  export ce_key128=${ce_key128}
fi
if [[ ! ${ce_iv} ]] ; then
  ce_iv=$(echo "iv-$RANDOM-$$-$(date)" | md5sum | md5sum)
  ce_iv=${ce_iv:0:32}
  export ce_iv=${ce_iv}
fi
if [[ ! ${ce_session} ]] ; then
  ce_session=$(echo "session-$RANDOM-$$-$(date)" | md5sum | md5sum)
  ce_session=${ce_session:0:32}
  export ce_session=${ce_session}
  mkdir -p "${H}/.crypt/${ce_session}"
fi

export SANDBOX_HOME="${H}/mysql/sandboxes"
export SANDBOX_BINARY="${H}/usr/local/apps/mysql"

if [[ -e "${HULA}/pkgconfig" ]] ; then
  export PKG_CONFIG_PATH="${HULL}/pkgconfig:${HUL}/ssl/lib/pkgconfig"
fi

export CMAKE_PREFIX_PATH="${HUL}:${HUL}/ssl"
export CMAKE_LIBRARY_PATH="${HULL}:${HUL}/ssl/lib"
export CMAKE_INCLUDE_PATH="${HULI}:${HUL}/ssl/include"
export CMAKE_SYSTEM_IGNORE_PATH="/lib/i386-linux-gnu:/usr/lib64:/usr/lib"
export CMAKE_IGNORE_PATH="/lib/i386-linux-gnu:/usr/lib64:/usr/lib"
export CMAKE_SYSTEM_LIBRARY_PATH="/lib:/usr/lib"
export CMAKE_PROGRAM_PATH="${HB}"
