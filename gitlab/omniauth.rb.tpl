# Copy this file to 'omniauth.rb' and configure it as necessary.
# The wiki has further details on configuring each provider.

Devise.setup do |config|
  # config.omniauth :github 'APP_ID', 'APP_SECRET', :scope => 'user,public_repo'

   config.omniauth :ldap, 
       :host => '@LDAP_HOSTNAME@',
       :base => '@LDAP_BASE@',
       :uid => '@LDAP_UID@',
       :port => @LDAP_PORT@,
       :method => @LDAP_METHOD@,
       :bind_dn => '@LDAP_BINDDN@',
       :password => '@LDAP_PASSWORD@'
end
