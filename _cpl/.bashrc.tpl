#!/bin/bash -x
if [[ "$1" != "-force" ]]; then
  echo $0 not executed for @@TITLE@@ unles called with -force
  return 0
fi 
echo $0 executed for @@TITLE@@

set history=2000

export H=${scriptPath:-`pwd`}
export HB="$H"/bin
export HU="$H"/usr
export HUL="$HU"/local
export HULL="$HUL"/lib
export HULI="$HUL"/include
export HULB="$HUL"/bin
export HULA="$HUL"/apps
export HULB="$HUL"/libs
alias sc='source $H/.bashrc -force'

# first override the $PATH, making sure to use *local* paths:
export PATH="$H/bin:$HULB:$HUL/sbin:$HUL/ssl/bin"
# then add the applications paths
#export PATH="$PATH:$HULA/gcc/bin"
#export PATH="$PATH:$HULA/git/bin:$HULA/svn/bin:$HULA/apache/bin"
#export PATH="$PATH:$HULA/perl/bin:$HULA/python/bin"
#export PATH="$PATH:$HULA/jdk/bin:$HULA/ant/bin"
# then add the few system paths we actually need
export PATH=$PATH:/bin:/usr/bin/:/usr/sbin:/usr/css/bin:/usr/sfw/bin

export LDFLAGS="-L$HULL -L$HUL/ssl/lib -R$HUL/ssl/lib -R$HULL/sasl2"
export CFLAGS="-I$HULI -I$HUL/ssl/include -fPIC -O -U_FORTIFY_SOURCE"
export CPPFLAGS="$CFLAGS"
export LD_LIBRARY_PATH="$HULL:$HUL/ssl/lib:$HUL/apps/svn/lib"
