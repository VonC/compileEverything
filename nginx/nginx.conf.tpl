#no need to specify the user: launched as non-root
#user  mccprdi1;
worker_processes  1;

#error_log  logs/error.log;
error_log  logs/error.log  notice;
#error_log  logs/error.log  info;
pid        logs/nginx.pid;

events {
    worker_connections  250;
}

http {
    include       mime.types;
    default_type  application/octet-stream;
    log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                      '$status $body_bytes_sent "$http_referer" '
                      '"$http_user_agent" "$http_x_forwarded_for"';
    access_log  logs/access.log  main;

    sendfile        on;
    #tcp_nopush     on;
    #keepalive_timeout  0;
    keepalive_timeout  150;
    #gzip  on;

    port_in_redirect   on;
    proxy_redirect     off;
    proxy_set_header   Host             $host:$server_port;
    proxy_set_header   X-Real-IP        $remote_addr;
    proxy_set_header   X-Forwarded-For  $proxy_add_x_forwarded_for;
    #proxy_redirect     http://itsvc/git/  /git/;
    server_tokens off;
    add_header X-Frame-Options DENY;

    server {
        listen       @PORT_NGINX_HTTPS@;
        server_name  @FQN@ @HOSTNAME@;
        # default max client body size was 1m! => Error code is 413
        # here: max 10Mo
        client_max_body_size 10m;
        proxy_read_timeout 90s;

        ssl                  on;
        ssl_certificate      @H@/nginx/itsvc.world.company.crt;
        ssl_certificate_key  @H@/nginx/itsvc.world.company.key;
        ssl_session_timeout  5m;
        #ssl_protocols SSLv2 SSLv3 TLSv1; # NO: SSLv2 prohibited
        #ssl_protocols  SSLv3 TLSv1;
        ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
        #ssl_ciphers  ALL:!ADH:!EXPORT56:RC4+RSA:+HIGH:+MEDIUM:+LOW:+SSLv2:+EXP;
        ssl_ciphers "EECDH+ECDSA+AESGCM EECDH+aRSA+AESGCM EECDH+ECDSA+SHA384 EECDH+ECDSA+SHA256 EECDH+aRSA+SHA384 EECDH+aRSA+SHA256 EECDH+aRSA+RC4 EECDH EDH+aRSA RC4 !aNULL !eNULL !LOW !3DES !MD5 !EXP !PSK !SRP !DSS";
        ssl_prefer_server_ciphers   on;

        location /git/ {
          proxy_pass https://@FQN@:@PORT_HTTP_GITWEB@/git/;
        }
        location /g2it/ {
          proxy_pass https://@FQN@:@PORT_HTTP_GITWEB2@/g2it/;
        }
        location /hgit/ {
          proxy_pass https://@FQN@:@PORT_HTTP_HGIT@/hgit/;
        }
        location /hrgit/ {
          proxy_pass https://@FQN@:@PORT_HTTP_HGIT@/hrgit/;
        }
        location /h2git/ {
          proxy_pass https://@FQN@:@PORT_HTTP_HGIT@/h2git/;
        }
        location /cgit/ {
          proxy_pass https://@FQN@:@PORT_HTTP_CGIT@/cgit/;
        }
        location /gitlab/ {
          proxy_pass https://@FQN@:@PORT_HTTPS_GITLAB@/gitlab/;
        }

        location /Semantic-UI/ {
          proxy_pass https://@FQN@:@PORT_HTTP_GITWEB@/Semantic-UI/;
        }

        location /lockedout {
          proxy_pass https://@FQN@:@PORT_HTTP_GITWEB@/lockedout;
        }

        root @H@/nginx/html;
        location = / {
            index  index.html index.htm;
        }
    }
    server {
        listen       @PORT_NGINX_HTTP@;
        server_name  @FQN@ @HOSTNAME@;
        # default max client body size was 1m! => Error code is 413
        # here: max 10Mo
        client_max_body_size 10m;

        root @H@/nginx/html;        
        location = / {
            index  index.html index.htm;
        }
    }
}
