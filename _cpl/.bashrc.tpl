#!/bin/bash
if [[ "$1" != "-force" ]]; then
  echo $0 not executed for @@TITLE@@ unles called with -force
  return 0
fi 
echo $0 executed for @@TITLE@@

set history=2000

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

# first override the $PATH, making sure to use *local* paths:
export PATH="${H}/bin:${HULB}:${HUL}/sbin:${HUL}/ssl/bin"
# then add the applications paths
#export PATH="$PATH:$HULA/gcc/bin"
#export PATH="$PATH:$HULA/git/bin:$HULA/svn/bin:$HULA/apache/bin"
#export PATH="$PATH:$HULA/perl/bin:$HULA/python/bin"
#export PATH="$PATH:$HULA/jdk/bin:$HULA/ant/bin"
# then add the few system paths we actually need
export PATH="${PATH}":/bin:/usr/bin/:/usr/sbin:/usr/ccs/bin:/usr/sfw/bin

export LDFLAGS="-L${HULL} -L${HUL}/ssl/lib -R${HUL}/ssl/lib -R${HULL}/sasl2"
export CFLAGS="-I${HULI} -I${HUL}/ssl/include -fPIC -O -U_FORTIFY_SOURCE"
export CPPFLAGS="$CFLAGS"
export LD_LIBRARY_PATH="${HULL}:${HUL}/ssl/lib:${HUL}/apps/svn/lib"
