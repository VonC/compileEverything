#!/bin/bash -x
if [[ "$1" != "-force" ]]; then
  echo $0 not executed
  return 0
fi 
echo $0 executed for @@TITLE@@

set history=2000

H=`pwd`
alias sc='source $H/.bashrc -force'

# first override the $PATH, making sure to use *local* paths:
export PATH=$H/bin:$H/usr/local/bin:$H/usr/local/sbin:$H/usr/local/ssl/bin
# then add the few system paths we actually need
export PATH=$PATH:/bin:/usr/bin/:/usr/sbin:/usr/css/bin:/usr/sfw/bin
