#!/bin/bash

gtl="${H}/gitlab"
github="${gtl}/github"
mysqlgtl="${H}/mysql/sandboxes/gitlab"
gitolite="${H}/.gitolite"
gtls="${gtl}/gitlab-shell"
mkdir -p "${gtl}/logs"

demod stop
upgradedb=0
if [[ ! -e "${gtl}/gitlab-satellites" ]] ; then mkdir "${gtl}/gitlab-satellites" ; fi
if [[ ! -e "${github}" ]] ; then
  xxgit=1 git clone -n https://github.com/gitlabhq/gitlabhq "${github}"
  cp "${gtl}/config.git" "${github}/.git/config"
  cp "${gtl}/attributes.git" "${github}/.git/info/attributes"
  xxgit=1 git --work-tree="${github}" --git-dir="${github}/.git" checkout master
  cp_tpl "${gtl}/p.rake.tpl" "${github}/lib/tasks"
  gi=$(grep "/lib/tasks/p.rake" "${github}/.git/info/exclude")
  if [[ "${gi}" == "" ]] ; then echo "/lib/tasks/p.rake" >> "${github}/.git/info/exclude"; fi
  gi=$(grep "/dump.rdb" "${github}/.git/info/exclude")
  if [[ "${gi}" == "" ]] ; then echo "/dump.rdb" >> "${github}/.git/info/exclude"; fi
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
gtls_install=0
if [[ ! -e "${gtls}" ]] ; then
  xxgit=1 git clone https://github.com/gitlabhq/gitlab-shell "${gtls}"
  gtls_install=1
else
  xxgit=1 git --work-tree="${gtls}" --git-dir="${gtls}/.git" pull
fi
cp_tpl "${gtl}/config.yml.tpl" "${gtl}"
ln -fs ../config.yml "${gtls}/config.yml"
if [[ "${gtls_install}" == "1" ]] ; then "${gtls}/bin/install" ; fi
if [[ ! -e "${mysqlgtl}" ]] ; then
  mysqlv=$(mysql -V); mysqlv=${mysqlv%%,*} ; mysqlv=${mysqlv##* }
  make_sandbox ${mysqlv} -- -d gitlab --no_confirm -P @PORT_MYSQL@ --check_port
  upgradedb=1
  "${mysqlgtl}/start"
  # mysql -u root --socket=@MYSQL_gitlab_socket@ --password=msandbox -e "CREATE USER 'gitlab'@'localhost' IDENTIFIED BY 'gitlab';"
  # mysql -u root --socket=@MYSQL_gitlab_socket@ --password=msandbox -e "DROP DATABASE gitlabhq_production;"
  # mysql -u root --socket=@MYSQL_gitlab_socket@ --password=msandbox -e "CREATE DATABASE IF NOT EXISTS gitlabhq_production DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci;"
  # mysql -u root --socket=@MYSQL_gitlab_socket@ --password=msandbox -e "GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, INDEX, ALTER ON gitlabhq_production.* TO gitlab@localhost;"
fi
"${mysqlgtl}/start"
cp_tpl "${gtl}/gitlab.yml.tpl" "${gtl}"
cp_tpl "${gtl}/database.yml.tpl" "${gtl}"
cp_tpl "${gtl}/unicorn.rb.tpl" "${gtl}"
cp_tpl "${gtl}/resque.yml.tpl" "${gtl}"
#cp_tpl "${gtl}/omniauth.rb.tpl" "${gtl}"
ln -fs ../../gitlab.yml "${github}/config/gitlab.yml"
ln -fs ../../database.yml "${github}/config/database.yml"
ln -fs ../../unicorn.rb "${github}/config/unicorn.rb"
ln -fs ../../resque.yml "${github}/config/resque.yml"
cp "${gtls}/hooks/post-receive" "${gitolite}/hooks/common/"
cp "${gtls}/hooks/update" "${gitolite}/hooks/common/"
d=$(pwd) ; cd "${github}"
if [[ ! "$(ls -A ${github}/vendor/bundle/ruby/1.9.1/gems)" ]] ; then 
  echo Install gem bundles
  gem install charlock_holmes --version '0.6.9'
  gem install bundler
fi
echo "Install/update bundles"
bundle install --deployment --without development test postgres
cd "${d}"
sshd start
redisd start
d=$(pwd) ; cd "${github}"
${gtl}/sidekiqd stop
if [[ "${upgradedb}" == "1" || ${gitlabForceInit[@]} ]] ; then
  echo "Initialize GitLab database"
  bundle exec rake db:setup RAILS_ENV=production
  ${gtl}/sidekiqd start
  bundle exec rake db:seed_fu RAILS_ENV=production
  bundle exec rake gitlab:enable_automerge RAILS_ENV=production
else
  ${gtl}/sidekiqd start
  echo "Upgrade GitLab database"
  bundle exec rake db:migrate RAILS_ENV=production
  echo "Upgrade GitLab database done"
fi
echo "(Re-)Create satellite repos"
bundle exec rake gitlab:satellites:create RAILS_ENV=production
echo Check if GitLab and its environment is configured correctly:
bundle exec rake gitlab:env:info RAILS_ENV=production
echo To make sure you didn't miss anything run a more thorough check with:
#'
bundle exec rake gitlab:check RAILS_ENV=production

cd "${d}"

demod start

echo "Checking Gitlab-shell:"
${gtls}/bin/check
