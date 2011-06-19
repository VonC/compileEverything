#!/bin/bash
myhome=`pwd`
echo $myhome
DIR="$( basename `pwd` )"
echo $DIR
d=`date +"%Y%m%d"`
echo $d
if [[ ! -e dep ]]; then
  echo ~~~~ DEPS ~~~~ | tee -a log
  echo download deps | tee -a log
  wget http://sunfreeware.com/programlistsparc10.html -O dep$d 2>&1 | tee -a log
  ln -s dep$d dep 2>&1 | tee -a log
fi
