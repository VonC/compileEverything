<IfModule mod_rewrite.c>
    Options All +Indexes +FollowSymLinks
    AllowOverride All

    RewriteEngine On
    RewriteBase @H@/gitlist/github/

    RewriteCond %{REQUEST_FILENAME} !-f
    RewriteRule ^(.*)$ index.php [L,NC]
</IfModule>
<Files config.ini>
    order allow,deny
    deny from all
</Files>
