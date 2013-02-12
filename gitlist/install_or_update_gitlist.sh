#!/bin/bash

gtl="${H}/gitlist"
github="${gtl}/github"
mkdir -p "${gtl}/logs"

if [[ ! -e "${github}" ]] ; then
  xxgit=1 git clone https://github.com/klaussilveira/gitlist "${github}"
else
  xxgit=1 git --work-tree="${github}" --git-dir="${github}/.git" pull
fi
if [[ -f "${github}/.htaccess" ]] ; then
  mv "${github}/.htaccess" "${github}/.htaccess.example"
  #ln -fs ../htaccess "${github}/.htaccess"
  rm -f "${github}/.htaccess"
fi
if [[ ! -e "${github}/config.ini" ]] ; then
  ln -fs ../config.ini "${github}/config.ini"
fi
cp_tpl "${gtl}/apache.cnf.tpl" "${gtl}"
cp_tpl "${gtl}/config.ini.tpl" "${gtl}"

g=$(grep gitlist "${H}/apache/cnf")
if [[ "${g}" == "" ]] ; then echo "Include ${H}/gitlist/apache.cnf" >> "${H}/apache/cnf" fi
g=$(grep gitlist "${H}/apache/cnf.tpl")
if [[ "${g}" == "" ]] ; then echo "Include @H@/gitlist/apache.cnf" >> "${H}/apache/cnf.tpl" fi
