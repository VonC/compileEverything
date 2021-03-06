ServerName vonc-VirtualBox
Listen @PORT_HTTP_STATUS@
LoadModule negotiation_module modules/mod_negotiation.so
LoadModule ssl_module modules/mod_ssl.so
LoadModule ldap_module modules/mod_ldap.so
LoadModule socache_shmcb_module modules/mod_socache_shmcb.so
LoadModule authnz_ldap_module modules/mod_authnz_ldap.so
LoadModule rewrite_module modules/mod_rewrite.so
LoadModule slotmem_shm_module modules/mod_slotmem_shm.so
LoadModule cache_module modules/mod_cache.so
LoadModule cgid_module modules/mod_cgid.so
LoadModule session_module modules/mod_session.so
LoadModule session_crypto_module modules/mod_session_crypto.so
LoadModule session_cookie_module modules/mod_session_cookie.so
LoadModule request_module modules/mod_request.so
LoadModule auth_form_module modules/mod_auth_form.so

Include conf/extra/httpd-manual.conf
<IfModule mod_status.c>
#
# Allow server status reports generated by mod_status,
# with the URL of http://servername/server-status
# Uncomment and change the ".example.com" to allow
# access from other hosts.
#
ExtendedStatus On
<Location /server-status>
    SetHandler server-status
    Order deny,allow
    Deny from all
    Allow from localhost ip6-localhost <my ip address>
#    Allow from .example.com
</Location>

</IfModule>

Session On
SessionCryptoPassphrase secretgit
SessionCookieName session path=/;httponly;secure;
SessionMaxAge 900

TraceEnable off
Header always append X-Frame-Options DENY

SSLCACertificateFile "@H@/apache/global_ca.crt"
LDAPTrustedGlobalCert CA_BASE64 "@H@/openldap/global_ca.crt"
LDAPVerifyServerCert off

SSLRandomSeed startup file:/dev/urandom 512
SSLRandomSeed connect file:/dev/urandom 512
SSLPassPhraseDialog  builtin
AddType application/x-x509-ca-cert .crt
AddType application/x-pkcs7-crl    .crl
SSLSessionCache        "shmcb:@H@/apache/ssl_scache(512000)"
SSLSessionCacheTimeout  300
# http://stackoverflow.com/a/15633390/6309
Mutex sysvsem default
#SSLMutex  "file:@H@/apache/ssl_mutex"

<AuthnProviderAlias ldap myldap>
  AuthLDAPBindDN cn=Manager,dc=example,dc=com
  AuthLDAPBindPassword secret
  AuthLDAPURL ldap://localhost:@PORT_LDAP_TEST@/dc=example,dc=com?uid?sub?(objectClass=*)
</AuthnProviderAlias>

# LDAP_START
<AuthnProviderAlias ldap companyldap>
  AuthLDAPBindDN "@LDAP_BINDDN@"
  AuthLDAPBindPassword @LDAP_PASSWORD@
  AuthLDAPURL @LDAP_URL@
</AuthnProviderAlias>
# LDAP_END

Options -Indexes

ServerTokens Prod
CacheIgnoreHeaders Set-Cookie
SetEnv no-cache
SetEnv no-store
SetEnv must-revalidate
Header merge Cache-Control no-cache
Header add Pragma no-cache
Header merge Cache-Control no-store
Header merge Cache-Control must-revalidate
MaxKeepAliveRequests 5

SSLProtocol all -SSLv2 -SSLv3
SSLHonorCipherOrder on
SSLCipherSuite "EECDH+ECDSA+AESGCM EECDH+aRSA+AESGCM EECDH+ECDSA+SHA384 EECDH+ECDSA+SHA256 EECDH+aRSA+SHA384 EECDH+aRSA+SHA256 EECDH+aRSA+RC4 EECDH EDH+aRSA RC4 !aNULL !eNULL !LOW !3DES !MD5 !EXP !PSK !SRP !DSS"

# GitWeb on @PORT_HTTP_GITWEB@
Listen @PORT_HTTP_GITWEB@
<VirtualHost @FQN@:@PORT_HTTP_GITWEB@>
    ServerName @FQN@
    ServerAlias @HOSTNAME@
    SSLCertificateFile "@H@/apache/crt"
    SSLCertificateKeyFile "@H@/apache/key"
    SSLEngine on
    SetEnv GIT_HTTP_BACKEND "@H@/usr/local/apps/git/libexec/git-core/git-http-backend"
    DocumentRoot @H@/gitweb
    Alias /git @H@/gitweb
    <FilesMatch "\.(cgi|shtml|phtml|php)$">
      SSLOptions +StdEnvVars
    </FilesMatch>
    <Directory @H@/gitweb>
        SSLOptions +StdEnvVars
        Options +ExecCGI +FollowSymLinks +SymLinksIfOwnerMatch
        AllowOverride All

        SetEnvIf Request_URI "^/lockedout$" NOPASSWD=true
        SetEnvIf Request_URI "^/Semantic-UI/.*$" NOPASSWD=true

        AuthFormProvider ldap
        AuthLDAPBindDN "@LDAP_BINDDN@"
        AuthLDAPBindPassword @LDAP_PASSWORD@
        AuthLDAPURL @LDAP_URL@
        AuthLDAPGroupAttribute member
        AuthLDAPGroupAttributeIsDN on

        ErrorDocument 401 /login.html
        AuthType form
        AuthName "LDAP authentication for ITSVC Prod GitWeb repositories"
        AuthFormAuthoritative On
        AuthFormAttempts 4
        AuthFormLockout 180

        # http://stackoverflow.com/questions/11438764/can-an-htpasswd-apply-to-all-urls-except-one

        Order Deny,Allow
        # Any requirment satisfies
        Satisfy any
        # Deny all requests
        Deny from all
        # except if user is authenticated
        <RequireAny>
          # or if NOPASSWD is set
          Require env NOPASSWD
          <RequireAll>
            Require valid-user
            # Require ldap-group @LDAP_GROUP@
            # Require ldap-group @LDAP_NOGROUP@
            # Require ldap-filter @LDAP_NOGROUP@
          </RequireAll>
        </RequireAny>

        AddHandler cgi-script cgi
        DirectoryIndex gitweb.cgi

        RewriteEngine Off
        RewriteCond %{REQUEST_FILENAME} !-f
        RewriteCond %{REQUEST_FILENAME} !-d
        RewriteRule ^[a-zA-Z0-9_\-]+\.git/?(\?.*)?$ /gitweb.cgi%{REQUEST_URI} [L,PT]
    </Directory>
    BrowserMatch ".*MSIE.*" \
         nokeepalive ssl-unclean-shutdown \
         downgrade-1.0 force-response-1.0
    LogLevel error authnz_ldap_module:trace7 authz_core_module:trace7
    # LogLevel error auth_form_module:trace1
    # LogLevel debug ssl_module:error core_module:trace5 socache_shmcb_module:error ssl:error auth_form_module:trace1
    LogFormat "%t %h %{SSL_PROTOCOL}x %{SSL_CIPHER}x \"%r\" %b" custom_gitweb
    CustomLog "|@H@/bin/rotatelogs @H@/apache/log/gitweb_ssl_request_log_%Y%m%d 86400" custom_gitweb
    ErrorLog "|@H@/bin/rotatelogs @H@/apache/log/gitweb_error_log_%Y%m%d 86400"
    TransferLog "|@H@/bin/rotatelogs @H@/apache/log/gitweb_access_log_%Y%m%d 86400"
</VirtualHost>

# GitWeb on @PORT_HTTP_GITWEB2@
Listen @PORT_HTTP_GITWEB2@
<VirtualHost @FQN@:@PORT_HTTP_GITWEB2@>
    ServerName @FQN@
    ServerAlias @HOSTNAME@
    SSLCertificateFile "@H@/apache/crt"
    SSLCertificateKeyFile "@H@/apache/key"
    SSLEngine on
    SetEnv GIT_HTTP_BACKEND "@H@/usr/local/apps/git/libexec/git-core/git-http-backend"
    DocumentRoot @H@/gitweb
    Alias /g2it @H@/gitweb
    <FilesMatch "\.(cgi|shtml|phtml|php)$">
      SSLOptions +StdEnvVars
    </FilesMatch>
    <Directory @H@/gitweb>
        SSLOptions +StdEnvVars
        Options +ExecCGI +FollowSymLinks +SymLinksIfOwnerMatch
        AllowOverride All

        SetEnvIf Request_URI "^/lockedout$" NOPASSWD=true
        SetEnvIf Request_URI "^/Semantic-UI/.*$" NOPASSWD=true

        AuthFormProvider ldap
        AuthLDAPBindDN cn=Manager,dc=example,dc=com
        AuthLDAPBindPassword secret
        AuthLDAPURL ldap://localhost:@PORT_LDAP_TEST@/dc=example,dc=com?uid?sub?(objectClass=*)

        ErrorDocument 401 /login.html
        AuthType form
        AuthName "LDAP dummy authentication for ITSVC Prod GitWeb repositories"
        AuthFormAuthoritative On
        AuthFormAttempts 4
        AuthFormLockout 180

        # http://stackoverflow.com/questions/11438764/can-an-htpasswd-apply-to-all-urls-except-one

        Order Deny,Allow
        # Any requirment satisfies
        Satisfy any
        # Deny all requests
        Deny from all
        # except if user is authenticated
        <RequireAny>
          # or if NOPASSWD is set
          Require env NOPASSWD
          Require valid-user
        </RequireAny>

        AddHandler cgi-script cgi
        DirectoryIndex gitweb.cgi
        
        RewriteEngine Off
        RewriteCond %{REQUEST_FILENAME} !-f
        RewriteCond %{REQUEST_FILENAME} !-d
        RewriteRule ^[a-zA-Z0-9_\-]+\.git/?(\?.*)?$ /gitweb.cgi%{REQUEST_URI} [L,PT]
    </Directory>
    BrowserMatch ".*MSIE.*" \
         nokeepalive ssl-unclean-shutdown \
         downgrade-1.0 force-response-1.0
    LogLevel error authnz_ldap_module:trace7 authz_core_module:trace7
    # LogLevel error auth_form_module:trace1
    # LogLevel debug ssl_module:error core_module:trace5 socache_shmcb_module:error ssl:error auth_form_module:trace1
    LogFormat "%t %h %{SSL_PROTOCOL}x %{SSL_CIPHER}x \"%r\" %b" custom_gitweb
    CustomLog "|@H@/bin/rotatelogs @H@/apache/log/gitweb_ssl_request_log_%Y%m%d 86400" custom_gitweb
    ErrorLog "|@H@/bin/rotatelogs @H@/apache/log/gitweb_error_log_%Y%m%d 86400"
    TransferLog "|@H@/bin/rotatelogs @H@/apache/log/gitweb_access_log_%Y%m%d 86400"
</VirtualHost>

# GitHttp on @PORT_HTTP_HGIT@
Listen @PORT_HTTP_HGIT@
<VirtualHost @FQN@:@PORT_HTTP_HGIT@>
    ServerName @FQN@
    ServerAlias @HOSTNAME@
    SSLCertificateFile "@H@/apache/crt"
    SSLCertificateKeyFile "@H@/apache/key"
    SSLEngine on
    SetEnv GIT_PROJECT_ROOT @H@/repositories
    SetEnv GIT_HTTP_EXPORT_ALL
    SetEnv GITOLITE_HTTP_HOME @H@
    ScriptAlias /hgit/ @H@/sbin/gitolite-shell/
    SetEnv GIT_HTTP_BACKEND "@H@/usr/local/apps/git/libexec/git-core/git-http-backend"
    <FilesMatch "\.(cgi|shtml|phtml|php)$">
      SSLOptions +StdEnvVars
    </FilesMatch>
    <Location /hgit>
        SSLOptions +StdEnvVars
        Options +ExecCGI +FollowSymLinks +SymLinksIfOwnerMatch
        #AllowOverride All
        order allow,deny
        Allow from all
        AuthName "LDAP authentication for ITSVC Smart HTTP Git repositories"
        AuthType Basic
        AuthBasicProvider ldap
        AuthLDAPBindDN "@LDAP_BINDDN@"
        AuthLDAPBindPassword @LDAP_PASSWORD@
        AuthLDAPURL @LDAP_URL@
        AuthLDAPGroupAttribute member
        AuthLDAPGroupAttributeIsDN on
        <RequireAll>
          Require valid-user
          # Require ldap-group @LDAP_GROUP@
          # Require ldap-group @LDAP_NOGROUP@
        </RequireAll>
        AddHandler cgi-script cgi
    </Location>
    ScriptAlias /hrgit/ @H@/git/reset_group
    <Location /hrgit>
        SSLOptions +StdEnvVars
        Options +ExecCGI +FollowSymLinks +SymLinksIfOwnerMatch
        #AllowOverride All
        order allow,deny
        Allow from all
        AuthName "LDAP authentication for ITSVC LDAP reset"
        AuthType Basic
        AuthBasicProvider ldap
        AuthLDAPBindDN "@LDAP_BINDDN@"
        AuthLDAPBindPassword @LDAP_PASSWORD@
        AuthLDAPURL @LDAP_URL@
        AuthLDAPGroupAttribute member
        AuthLDAPGroupAttributeIsDN on
        <RequireAll>
          Require valid-user
          # Require ldap-group @LDAP_GROUP@
          # Require ldap-group @LDAP_NOGROUP@
        </RequireAll>
        AddHandler cgi-script cgi
    </Location>
    ScriptAlias /h2git/ @H@/sbin/gitolite-shell/
    <Location /h2git>
        SSLOptions +StdEnvVars
        Options +ExecCGI +FollowSymLinks +SymLinksIfOwnerMatch
        #AllowOverride All
        order allow,deny
        Allow from all
        AuthName "LDAP authentication for ITSVC Smart HTTP Git repositories 2"
        AuthType Basic
        AuthBasicProvider myldap
        Require valid-user
        AddHandler cgi-script cgi
    </Location>
    LogLevel authnz_ldap:info
    BrowserMatch ".*MSIE.*" \
         nokeepalive ssl-unclean-shutdown \
         downgrade-1.0 force-response-1.0
    LogFormat "%t %h %{SSL_PROTOCOL}x %{SSL_CIPHER}x \"%r\" %b" custom_githttp
    CustomLog "|@H@/bin/rotatelogs @H@/apache/log/githttp_ssl_request_log_%Y%m%d 86400" custom_githttp
    ErrorLog "|@H@/bin/rotatelogs @H@/apache/log/githttp_error_log_%Y%m%d 86400"
    TransferLog "|@H@/bin/rotatelogs @H@/apache/log/githttp_access_log_%Y%m%d 86400"
</VirtualHost>


# CGit on @PORT_HTTP_CGIT@
Listen @PORT_HTTP_CGIT@
<VirtualHost @FQN@:@PORT_HTTP_CGIT@>
    ServerName @FQN@
    ServerAlias @HOSTNAME@
    SSLCertificateFile "@H@/apache/crt"
    SSLCertificateKeyFile "@H@/apache/key"
    SSLEngine on
    SetEnv GIT_HTTP_BACKEND "@H@/usr/local/apps/git/libexec/git-core/git-http-backend"
    DocumentRoot @H@/cgit
    Alias /cgit @H@/cgit
    <FilesMatch "\.(cgi|shtml|phtml|php)$">
      SSLOptions +StdEnvVars
    </FilesMatch>
    <Directory @H@/cgit>
        SSLOptions +StdEnvVars
        Options +ExecCGI +FollowSymLinks +SymLinksIfOwnerMatch
        AllowOverride All
        order allow,deny
        Allow from all

        AddHandler cgi-script .cgi .pl
        DirectoryIndex cgit.pl

        #RewriteEngine on
 
        SetEnv GIT_PROJECT_ROOT=@H@/repositories
 
        AuthName "LDAP authentication for ITSVC CGit repositories"
        AuthType Basic
        AuthBasicProvider myldap companyldap
        # AuthzLDAPAuthoritative Off
        Require valid-user

        #RewriteCond %{REQUEST_FILENAME} !-f
        #RewriteCond %{REQUEST_FILENAME} !-d 
        #RewriteRule "^(.*)/(.*)/(HEAD|info/refs|objects/(info/[^/]+|[0-9a-f]{2}/[0-9a-f]{38}|pack/pack-[0-9a-f]{40}\.(pack|idx))|git-(upload|receive)-pack)$" /git-http-backend.cgi/$1.git/$2 [NS,L,QSA]
 
        #RewriteCond %{REQUEST_FILENAME} !-f
        #RewriteCond %{REQUEST_FILENAME} !-d
        #RewriteRule ^/$ /cgit.pl/ [L,PT,NS]
        #RewriteRule ^/.+ /cgit.pl$0 [L,PT,NS]

    </Directory>
    BrowserMatch ".*MSIE.*" \
         nokeepalive ssl-unclean-shutdown \
         downgrade-1.0 force-response-1.0
    LogFormat "%t %h %{SSL_PROTOCOL}x %{SSL_CIPHER}x \"%r\" %b" custom_cgit
    CustomLog "|@H@/bin/rotatelogs @H@/apache/log/gitcgit_ssl_request_log_%Y%m%d 86400" custom_cgit
    ErrorLog "|@H@/bin/rotatelogs @H@/apache/log/gitcgit_error_log_%Y%m%d 86400"
    TransferLog "|@H@/bin/rotatelogs @H@/apache/log/gitcgit_access_log_%Y%m%d 86400"
    LogLevel info
</VirtualHost>

IncludeOptional @H@/gitlab/apache*.cnf

IncludeOptional @H@/gitlist/apache*.cnf
