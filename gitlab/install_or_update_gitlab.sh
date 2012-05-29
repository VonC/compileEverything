#!/bin/bash

gtl="${H}/gitlab"
github="${gtl}/github"
mysqlgtl="${H}/mysql/sandboxes/gitlab"

if [[ ! -e "${github}" ]] ; then
  xxgit=1 git clone https://github.com/gitlabhq/gitlabhq "${github}"
  bundle config build.charlock_holmes --with-icu-dir="${HUL}"
  bundle config build.raindrops --with-atomic_ops-dir="${HUL}"
  bundle config build.sqlite3 --with-sqlite3-dir="${HUL}"
else
  xxgit=1 git --work-tree="${github}" --git-dir="${github}/.git" pull
fi
cp_tpl "${gtl}/gitlab.yml.tpl" "${gtl}"
cp_tpl "${gtl}/database.yml.tpl" "${gtl}"
ln -fs ../../gitlab.yml "${github}/gitlab.yml"
ln -fs ../../database.yml "${github}/database.yml"
if [[ !- "${mysqlgtl}" ]] ; then
  mysqlv=$(mysql -V); =${mysqlv%%,*} ; =${mysqlv##* }
  make_sandbox ${mysqlv} -- -d "${mysqlgtl}"
fi
