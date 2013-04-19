# GitLab user. git by default
user: @USERNAME@

# Url to gitlab instance. Used for api calls. Should be ends with slash.
gitlab_url: "https://@FQN@:@PORT_HTTPS_GITLAB@/gitlab/"

http_settings:
#  user: someone
#  password: somepass
  self_signed_cert: false

# Repositories path
repos_path: "@H@/repositories"

# File used as authorized_keys for gitlab user
auth_file: "@H@/.ssh/authorized_keys"
