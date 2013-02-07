# GitList  on @PORT_HTTPS_GITLIST@
Listen @PORT_HTTPS_GITLIST@
<VirtualHost @FQN@:@PORT_HTTPS_GITLIST@>
    ServerName @FQN@
    ServerAlias @HOSTNAME@
    SSLCertificateFile "@H@/apache/crt"
    SSLCertificateKeyFile "@H@/apache/key"
    SSLEngine on
    SSLCipherSuite ALL:!ADH:!EXPORT56:RC4+RSA:+HIGH:+MEDIUM:+LOW:+SSLv2:+EXP:+eNULL
    SetEnv GIT_HTTP_BACKEND "@H@/usr/local/apps/git/libexec/git-core/git-http-backend"
    DocumentRoot @H@/gitlist/github
    Alias /gitlist @H@/gitlist/github
    <FilesMatch "\.(cgi|shtml|phtml|php)$">
      SSLOptions +StdEnvVars
    </FilesMatch>
    <Location /gitlist>
        SSLOptions +StdEnvVars
        Options ExecCGI +FollowSymLinks +SymLinksIfOwnerMatch
        #AllowOverride All
        order allow,deny
        Allow from all
        Options -MultiViews
    </Location>

    CustomLog "@H@/gitlist/logs/apache_gitlist_ssl_request_log" \
              "%t %h %{SSL_PROTOCOL}x %{SSL_CIPHER}x \"%r\" %b"
    ErrorLog "@H@/gitlist/logs/apache_gitlist_error_log"
    TransferLog "@H@/gitlist/logs/apache_gitlist_access_log"
    LogLevel info
</VirtualHost>

