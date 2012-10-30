# # # # # # # # # # # # # # # # # # 
# Gitlab application config file  #
# # # # # # # # # # # # # # # # # #

#
# 1. Common settings
# ==========================

# Web application specific settings
web:
  host: localhost
  port: @PORT_HTTPS_GITLAB@
  https: true

# Email used for notification
# about new issues, comments
email:
  from: notify@localhost

# Application specific settings
# Like default project limit for user etc
app: 
  default_projects_limit: 10 
  # backup_path: "/vol/backups"   # default: Rails.root + backups/
  # backup_keep_time: 604800      # default: 0 (forever) (in seconds)

#
# 2. Auth settings
# ==========================
ldap: 
  enabled: false
  host: '@LDAP_HOSTNAME@'
  base: '@LDAP_BASE@'
  port: @LDAP_PORT@
  uid: '@LDAP_UID@'
  method: '@LDAP_METHOD@'
  bind_dn: '@LDAP_BINDDN@'
  password: '@LDAP_PASSWORD@'

omniauth:
  # Enable ability for users
  # to login via twitter, google ..
  enabled: false

  # IMPORTANT! 
  # It allows user to login without having user account
  allow_single_sign_on: false
  block_auto_created_users: true

  # Auth providers 
  providers:
    # - { name: 'google_oauth2', app_id: 'YOUR APP ID',
    #     app_secret: 'YOUR APP SECRET',
    #     args: { access_type: 'offline', approval_prompt: '' } }
    # - { name: 'twitter', app_id: 'YOUR APP ID',
    #     app_secret: 'YOUR APP SECRET'}
    # - { name: 'github', app_id: 'YOUR APP ID',
    #     app_secret: 'YOUR APP SECRET' }

# 
# 3. Advanced settings: 
# ==========================

# Git Hosting configuration
git_host:
  admin_uri: gitolitesrv:gitolite-admin
  base_path: @H@/repositories/
  hooks_path: @H@/.gitolite/hooks/
  gitolite_admin_key: gitoliteadm
  git_user: @USERNAME@
  upload_pack: true
  receive_pack: true
  host: @FQN@
  port: @PORT_SSHD@

# Git settings
# Use default values unless you understand it
git:
  path: @H@/bin/git
  # Max size of git object like commit, in bytes
  # This value can be increased if you have a very large commits
  git_max_size: 5242880 # 5.megabytes
  # Git timeout to read commit, in seconds
  git_timeout: 10
