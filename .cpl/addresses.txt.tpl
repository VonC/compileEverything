SSH                              : @USERNAME@@@FQN@:@PORT_SSHD@

~~~~~~~~~~~~~~
Apache:
  status (localhost only)        : https://localhost:@PORT_HTTP_STATUS@/server-status
  gitweb                         : https://@FQN@:@PORT_HTTP_GITWEB@/git/
  https                          : https://@FQN@:@PORT_HTTP_HGIT@/hgit/
  cgit                           : https://@FQN@:@PORT_HTTP_CGIT@/cgit/
  gitlab                         : https://@FQN@:@PORT_HTTPS_GITLAB@/gitlab/
  gitlist                        : https://@FQN@:@PORT_HTTPS_GITLIST@/gitlist/
  
~~~~~~~~~~~~~~
NGiNX:
  RootDir                       : http://@FQN@:@PORT_NGINX_HTTP@/
  Redirection gitweb            : https://@FQN@:@PORT_NGINX_HTTPS@/git/
  Redirection hgit              : https://@FQN@:@PORT_NGINX_HTTPS@/hgit/
  Redirection cgit              : https://@FQN@:@PORT_NGINX_HTTPS@/cgit/
  Redirection gitlist           : https://@FQN@:@PORT_NGINX_HTTPS@/gitlist/
  GitLab                        : https://@FQN@:@PORT_NGINX_HTTPS@/gitlab/
                                  (admin@local.host/5iveL!fe)

~~~~~~~~~~~~~~
Redis                           : https://@FQN@:@PORT_REDIS@/

~~~~~~~~~~~~~~
LDAP:
  Test:
  AuthLDAPBindDN                  cn=Manager,dc=example,dc=com
  AuthLDAPBindPassword            secret
  AuthLDAPURL                     ldap://localhost:@PORT_LDAP_TEST@/dc=example,dc=com?uid?sub?(objectClass=*)
  AuthLDAPURL                     ldap://@FQN@:@PORT_LDAP_TEST@/dc=example,dc=com?uid?sub?(objectClass=*)

  Private (if defined):
  host:                  '@LDAP_HOSTNAME@'
  base:                  '@LDAP_BASE@'
  port:                   @LDAP_PORT@
  uid:                   '@LDAP_UID@'
  method:                '@LDAP_METHOD@'
  bind_dn:               '@LDAP_BINDDN@'
  password:              '@LDAP_PASSWORD@'
  AuthLDAPBindDN         "@LDAP_BINDDN@"
  AuthLDAPBindPassword   @LDAP_PASSWORD@
  AuthLDAPURL            @LDAP_URL@

~~~~~~~~~~~~~~~
Tomcat (not used yet)
  Http                        : http://@FQN@:@PORT_TOMCAT_CATALINA@/
  Https                       : https://@FQN@:@PORT_TOMCAT_CATALINA_REDIRECT@/
  Ajp                         : http://@FQN@:@PORT_TOMCAT_AJP@/
  Shutdown                    : http://@FQN@:@PORT_TOMCAT_SHUTDOWN@/
