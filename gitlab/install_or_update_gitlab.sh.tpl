#!/bin/bash

gtl="${H}/gitlab"
github="${gtl}/github"
mysqlgtl="${H}/mysql/sandboxes/gitlab"
gitolite="${H}/.gitolite"
mkdir -p "${gtl}/logs"

gitlabd stop
upgradedb=0
if [[ ! -e "${github}" ]] ; then
  xxgit=1 git clone https://github.com/gitlabhq/gitlabhq "${github}"
  cp -f "${gtl}/boot.rb" "${github}/config/boot.rb"
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
  make_sandbox ${mysqlv} -- -d gitlab --no_confirm -P @PORT_MYSQL@ --check_port
  upgradedb=1
fi
"${mysqlgtl}/start"
cp_tpl "${gtl}/gitlab.yml.tpl" "${gtl}"
cp_tpl "${gtl}/database.yml.tpl" "${gtl}"
cp_tpl "${gtl}/unicorn.rb.tpl" "${gtl}"
#cp_tpl "${gtl}/omniauth.rb.tpl" "${gtl}"
ln -fs ../../gitlab.yml "${github}/config/gitlab.yml"
ln -fs ../../database.yml "${github}/config/database.yml"
ln -fs ../../unicorn.rb "${github}/config/unicorn.rb"
if [[ ! -e "${gitolite}/hooks/common/post-receive" ]] ; then
  cp "${github}/lib/hooks/post-receive" "${gitolite}/hooks/common/"
fi
if [[ ! "$(ls -A ${github}/vendor/bundle/ruby/1.9.1/gems)" ]] ; then 
  d=$(pwd) ; cd "${github}"
  echo Install bundles
  gem install charlock_holmes --version '0.6.8'
  gem install bundler
  bundle install --without development test sqlite postgres --deployment
  cd "${d}"
fi
sshd start
redisd start
d=$(pwd) ; cd "${github}"
if [[ "${upgradedb}" == "1" ]] ; then
  echo Initialize app
  bundle exec rake gitlab:app:setup RAILS_ENV=production
  fix=$(grep "Syc" -nrlHIF "${github}/vendor/bundle/ruby/1.9.1/specifications/")
  while read line; do
    gen_sed -i "s/\"#<Syck::DefaultKey:.*>/\"~>/g" "${line}"
  done < <(echo "${fix}") 
  bundle exec rake gitlab:app:setup RAILS_ENV=production
else
  echo Upgrade database
  bundle exec rake db:migrate RAILS_ENV=production
  echo Upgrade database done
fi
bundle exec rake gitlab:app:status RAILS_ENV=production

cd "${d}"

gitlabd start

