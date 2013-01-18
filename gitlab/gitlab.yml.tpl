# # # # # # # # # # # # # # # # # # 
# Gitlab application config file  #
# # # # # # # # # # # # # # # # # #
#
# How to use:
# 1. copy file as gitlab.yml
# 2. Replace gitlab -> host with your domain
# 3. Replace gitolite -> ssh_host with your domain
# 4. Replace gitlab -> email_from

#
# 1. GitLab app settings
# ==========================

## GitLab settings
gitlab:
  ## Web server settings
  host: localhost
  port: @PORT_HTTPS_GITLAB@
  https: true
  # Uncomment and customize to run in non-root path
  # Note that ENV['RAILS_RELATIVE_URL_ROOT'] in config/unicorn.rb may need to be changed
  relative_url_root: /gitlab

  # Uncomment and customize if you can't use the default user to run GitLab (default: 'gitlab')
  user: @USERNAME@

  ## Email settings
  # Email address used in the "From" field in mails sent by GitLab
  email_from: gitoliteadm@mail.com

  ## Project settings
  default_projects_limit: 10

## Gravatar
gravatar:
  enabled: true                 # Use user avatar images from Gravatar.com (default: true)
  # plain_url: "http://..."     # default: http://www.gravatar.com/avatar/%{hash}?s=%{size}&d=mm
  # ssl_url:   "https://..."    # default: https://secure.gravatar.com/avatar/%{hash}?s=%{size}&d=mm



#
# 2. Auth settings
# ==========================

## LDAP settings
ldap: 
  enabled: true
  host: '@LDAP_HOSTNAME@'
  base: '@LDAP_BASE@'
  port: @LDAP_PORT@
  uid: '@LDAP_UID@'
  method: '@LDAP_METHOD_NC@'
  bind_dn: '@LDAP_BINDDN@'
  password: '@LDAP_PASSWORD@'

## Omniauth settings
omniauth:
  # Enable ability for users
  # Allow logging in via Twitter, Google, etc. using Omniauth providers
  enabled: false

  # CAUTION!
  # This allows users to login without having a user account first (default: false)
  # User accounts will be created automatically when authentication was successful.
  allow_single_sign_on: false
  # Locks down those users until they have been cleared by the admin (default: true)
  block_auto_created_users: true

  ## Auth providers
  # Uncomment the lines and fill in the data of the auth provider you want to use
  # If your favorite auth provider is not listed you can user others:
  # see https://github.com/gitlabhq/gitlabhq/wiki/Using-Custom-Omniauth-Providers
  # The 'app_id' and 'app_secret' parameters are always passed as the first two
  # arguments, followed by optional 'args' which can be either a hash or an array.
  providers:
    # - { name: 'google_oauth2', app_id: 'YOUR APP ID',
    #     app_secret: 'YOUR APP SECRET',
    #     args: { access_type: 'offline', approval_prompt: '' } }
    # - { name: 'twitter', app_id: 'YOUR APP ID',
    #     app_secret: 'YOUR APP SECRET'}
    # - { name: 'github', app_id: 'YOUR APP ID',
    #     app_secret: 'YOUR APP SECRET' }



#
# 3. Advanced settings
# ==========================

# GitLab Satellites
satellites:
  # Relative paths are relative to Rails.root (default: tmp/repo_satellites/)
  path: @H@/gitlab/gitlab-satellites/

## Backup settings
backup:
  path: "tmp/backups"   # Relative paths are relative to Rails.root (default: tmp/backups/)
  # keep_time: 604800   # default: 0 (forever) (in seconds)

## Gitolite settings
gitolite:
  install_path: @H@/gitolite/bin/
  admin_uri: gitolitesrv:gitolite-admin
  # repos_path must not be a symlink
  repos_path: @H@/repositories/
  hooks_path: @H@/.gitolite/hooks/
  admin_key: gitoliteadm
  upload_pack: true
  receive_pack: true
  ssh_user: @USERNAME@
  ssh_host: localhost
  ssh_port: @PORT_SSHD@
  # config_file: gitolite.conf
  # Uncomment and customize if you can't use the default group to own the repositories and run Gitolite (default: same as the 'ssh_user' above)
  owner_group: @USERGROUP@

## Git settings
# CAUTION!
# Use the default values unless you really know what you are doing
git:
  bin_path: @H@/bin/git
  # Max size of git object like commit, in bytes
  # This value can be increased if you have a very large commits
  max_size: 5242880 # 5.megabytes
  # Git timeout to read commit, in seconds
  timeout: 10
