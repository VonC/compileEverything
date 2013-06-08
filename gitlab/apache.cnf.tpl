LoadModule passenger_module @PASSENGER-ROOT@/libout/apache2/mod_passenger.so
PassengerRoot @PASSENGER-ROOT@
PassengerRuby @H@/usr/local/apps/ruby/bin/ruby
PassengerDefaultUser @USERNAME@

# GitLabHq  on @PORT_HTTPS_GITLAB@
Listen @PORT_HTTPS_GITLAB@
<VirtualHost @FQN@:@PORT_HTTPS_GITLAB@>
    ServerName @FQN@
    ServerAlias @HOSTNAME@
    SSLCertificateFile "@H@/apache/crt"
    SSLCertificateKeyFile "@H@/apache/key"
    SSLEngine on
    SSLCipherSuite ALL:!ADH:!EXPORT56:RC4+RSA:+HIGH:+MEDIUM:+LOW:+SSLv2:+EXP:+eNULL
    SetEnv GIT_HTTP_BACKEND "@H@/usr/local/apps/git/libexec/git-core/git-http-backend"
    DocumentRoot @H@/gitlab
    Alias /gitlab @H@/gitlab
    <FilesMatch "\.(cgi|shtml|phtml|php)$">
      SSLOptions +StdEnvVars
    </FilesMatch>
    # http://stackoverflow.com/questions/13871154/gitlab-apache-phusion-passenger-no-such-file-or-directory-config-enviro/16393263#16393263
    RackBaseURI /gitlab
    PassengerEnabled On
    <Location /gitlab>
        SSLOptions +StdEnvVars

        PassengerEnabled on
        Options ExecCGI +FollowSymLinks +SymLinksIfOwnerMatch
        #AllowOverride All
        order allow,deny
        Allow from all
        Options -MultiViews
    </Location>

    CustomLog "@H@/gitlab/logs/apache_gitlab_ssl_request_log" \
              "%t %h %{SSL_PROTOCOL}x %{SSL_CIPHER}x \"%r\" %b"
    ErrorLog "@H@/gitlab/logs/apache_gitlab_error_log"
    TransferLog "@H@/gitlab/logs/apache_gitlab_access_log"
    LogLevel info
</VirtualHost>

