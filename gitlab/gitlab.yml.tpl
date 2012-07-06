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


# 
# 2. Advanced settings: 
# ==========================

# Git Hosting congiguration
git_host:
  system: gitolite
  admin_uri: gitolitesrv:gitolite-admin
  base_path: @H@/repositories/
  host: @FQN@
  git_user: @USERNAME@
  port: @PORT_SSHD@

# Git settings
# Use default values unless you understand it
git:
  # Max size of git object like commit, in bytes
  # This value can be increased if you have a very large commits
  git_max_size: 5242880 # 5.megabytes
  # Git timeout to read commit, in seconds
  git_timeout: 10
