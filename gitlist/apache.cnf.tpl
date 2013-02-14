# GitList on @PORT_HTTPS_GITLIST@
<IfModule !php5_module>
  LoadModule php5_module modules/libphp5.so
</IfModule>
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
    <FilesMatch ".php$">
      SetHandler application/x-httpd-php
    </FilesMatch>
    <FilesMatch ".phps$">
      SetHandler application/x-httpd-php-source
    </FilesMatch>
    <Directory @H@/gitlist/github>
        SSLOptions +StdEnvVars
        Options ExecCGI +Indexes +FollowSymLinks
        AllowOverride All
        order allow,deny
        Allow from all
        Options -MultiViews

        DirectoryIndex index.php
        RewriteEngine On

        RewriteBase /
        RewriteCond %{REQUEST_FILENAME} !-f
        RewriteRule ^(.*)$ gitlist/index.php/$1 [L,NC,QSA]

    </Directory>

    # RewriteLog "@H@/gitlist/logs/apache_gitlist_rewrite_log"
    # RewriteLogLevel 3
    CustomLog "@H@/gitlist/logs/apache_gitlist_ssl_request_log" \
              "%t %h %{SSL_PROTOCOL}x %{SSL_CIPHER}x \"%r\" %b"
    ErrorLog "@H@/gitlist/logs/apache_gitlist_error_log"
    TransferLog "@H@/gitlist/logs/apache_gitlist_access_log"
    LogLevel info
</VirtualHost>

