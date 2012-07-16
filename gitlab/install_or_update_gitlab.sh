#!/bin/bash

gtl="${H}/gitlab"
github="${gtl}/github"
mysqlgtl="${H}/mysql/sandboxes/gitlab"
mkdir -p "${gtl}/logs"

if [[ ! -e "${github}" ]] ; then
  xxgit=1 git clone https://github.com/gitlabhq/gitlabhq "${github}"
  d=$(pwd)
  cd "${github}"
  bundle config build.charlock_holmes --with-icu-dir="${HUL}"
  bundle config build.raindrops --with-atomic_ops-dir="${HUL}"
  bundle config build.sqlite3 --with-sqlite3-dir="${HUL}"
  bundle config build.mysql2  --with-mysql-config="${HB}/mysql_config" --with-ssl-dir="${HUL}/ssl" 
  cd "${d}"
else
  xxgit=1 git --work-tree="${github}" --git-dir="${github}/.git" pull
fi
if [[ ! -e "${mysqlgtl}" ]] ; then
  mysqlv=$(mysql -V); mysqlv=${mysqlv%%,*} ; mysqlv=${mysqlv##* }
  make_sandbox ${mysqlv} -- -d gitlab --no_confirm
fi
cp_tpl "${gtl}/gitlab.yml.tpl" "${gtl}"
cp_tpl "${gtl}/database.yml.tpl" "${gtl}"
cp_tpl "${gtl}/unicorn.rb.tpl" "${gtl}"
cp_tpl "${gtl}/omniauth.rb.tpl" "${gtl}"
ln -fs ../../gitlab.yml "${github}/config/gitlab.yml"
ln -fs ../../database.yml "${github}/config/database.yml"
ln -fs ../../unicorn.rb "${github}/config/unicorn.rb"
if [[ -e "${H}/.ldap.private" || -e "${H}/../.ldap.private" ]] ; then
  ln -fs ../../../omniauth.rb "${github}/config/initializers/omniauth.rb"
fi
if [[ ! "$(ls -A ${github}/vendor/bundle/ruby/1.9.1/gems)" ]] ; then 
  d=$(pwd) ; cd "${github}"
  bundle install --without development test --deployment
  cd "${d}"
fi
sshd start
redisd start
d=$(pwd) ; cd "${github}"
bundle exec rake gitlab:app:setup RAILS_ENV=production
fix=$(grep "Syc" -nrlHIF "${github}/vendor/bundle/ruby/1.9.1/specifications/")
while read line; do
  gen_sed -i "s/\"#<Syck::DefaultKey:.*>/\"~>/g" "${line}"
done < <(echo "${fix}") 
bundle exec rake gitlab:app:status RAILS_ENV=production

cd "${d}"
