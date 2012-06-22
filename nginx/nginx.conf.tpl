#no need to specify the user: launched as non-root
#user  mccprdi1;
worker_processes  1;

#error_log  logs/error.log;
#error_log  logs/error.log  notice;
error_log  logs/error.log  info;
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
    proxy_set_header   Host             $host;
    proxy_set_header   X-Real-IP        $remote_addr;
    proxy_set_header   X-Forwarded-For  $proxy_add_x_forwarded_for;
    #proxy_redirect     http://itsvc/git/  /git/;

    server {
        listen       @PORT_NGINX_HTTPS@;
        server_name  @FQN@ @HOSTNAME@;
        # default max client body size was 1m! => Error code is 413
        # here: max 10Go
        client_max_body_size 10000m;

        ssl                  on;
        ssl_certificate      @H@/nginx/itsvc.world.company.crt;
        ssl_certificate_key  @H@/nginx/itsvc.world.company.key;
        ssl_session_timeout  5m;
        #ssl_protocols SSLv2 SSLv3 TLSv1; # NO: SSLv2 prohibited
        ssl_protocols  SSLv3 TLSv1;
        ssl_ciphers  ALL:!ADH:!EXPORT56:RC4+RSA:+HIGH:+MEDIUM:+LOW:+SSLv2:+EXP;
        ssl_prefer_server_ciphers   on;

        location /git/ {
          proxy_pass https://@FQN@:@PORT_HTTP_GITWEB@/git/;
        }
        location /hgit/ {
          proxy_pass https://@FQN@:@PORT_HTTP_HGIT@/hgit/;
        }
        location /cgit/ {
          proxy_pass https://@FQN@:@PORT_HTTP_CGIT@/cgit/;
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
        # here: max 10Go
        client_max_body_size 10000m;

        root @H@/nginx/html;        
        location = / {
            index  index.html index.htm;
        }
    }
 
    upstream gitlab {
        server unix:@H@/gitlab/github/tmp/sockets/gitlab.socket;
    }

    server {
        listen       @PORT_HTTP_GITLAB@;
        server_name  @FQN@ @HOSTNAME@;
        root @H@/gitlab/github/public;

        # individual nginx logs for this gitlab vhost
        access_log  @H@/gitlab/nginx_gitlab_access.log;
        error_log   @H@/gitlab/nginx_gitlab_error.log;

        location / {
            # serve static files from defined root folder;.
            # @gitlab is a named location for the upstream fallback, see below
            try_files $uri $uri/index.html $uri.html @gitlab;
        }

        # if a file, which is not found in the root folder is requested, 
        # then the proxy pass the request to the upsteam (gitlab unicorn)
        location @gitlab {
            proxy_redirect     off;
            # you need to change this to "https", if you set "ssl" directive to "on"
            proxy_set_header   X-FORWARDED_PROTO http;
            proxy_set_header   Host              @FQN@:@PORT_HTTP_GITLAB@;
            proxy_set_header   X-Real-IP         $remote_addr;

            proxy_pass http://gitlab;
        }

    }
}
