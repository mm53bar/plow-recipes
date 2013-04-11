# Install unicorn-friendly vhost for nginx
#
# Environment variables required:
#
# APP_NAME                  # application name
# DOMAIN_NAME               # domain name i.e. example.com
# SSL_CERT                  # filename for ssl certificate
# SSL_KEY                   # filename for ssl key

function check_vhost() {
  local vhost=$(</opt/nginx/sites-enabled/$1)
  [[ -e /opt/nginx/sites-enabled/$1 ]] && 
    diff -q <(echo "$vhost") <(echo "$2") > /dev/null 2>&1
}

function create_vhost() {
  rm -f /opt/nginx/sites-available/$1
  echo "$3" > /opt/nginx/sites-available/$1 
  ln -sf /opt/nginx/sites-available/$1 /opt/nginx/sites-enabled/$1
  cp files/$4 /etc/ssl/
  cp files/$5 /etc/ssl/
  restart nginx
}

new_vhost=$(cat <<EOF
  upstream app_server {
    server unix:/srv/$APP_NAME/tmp/sockets/unicorn.sock fail_timeout=0;
  }

  server {
    listen 80;
    server_name www.$DOMAIN_NAME;

    client_max_body_size 4G;

    access_log /srv/$APP_NAME/log/access.log;
    error_log /srv/$APP_NAME/log/error.log;

    root /srv/$APP_NAME/public/;

    try_files \$uri/index.html \$uri.html \$uri @app;
    error_page 502 503 =503                  @maintenance;
    error_page 500 504 =500                  @server_error;

    location @app {
      proxy_set_header X-Real-IP \$remote_addr;
      proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
      proxy_set_header Host \$http_host;
      proxy_redirect off;

      # enable this if and only if you use HTTPS, this helps Rack
      # set the proper protocol for doing redirects:
      # proxy_set_header X-Forwarded-Proto https;

      proxy_pass http://app_server;
    }

    location @maintenance {
      root /srv/$APP_NAME/public;
      try_files /503.html =503;
    }

    location @server_error {
      root /srv/$APP_NAME/public;
      try_files /500.html =500;
    }

    location = /favicon.ico {
      expires    max;
      add_header Cache-Control public;
    }
  }

  server {
    listen 443;
    server_name www.$DOMAIN_NAME;
    ssl on;

    ssl_certificate      /etc/ssl/$SSL_CERT;
    ssl_certificate_key  /etc/ssl/$SSL_KEY;

    client_max_body_size 4G;

    access_log /srv/$APP_NAME/log/access.log;
    error_log /srv/$APP_NAME/log/error.log;

    root /srv/$APP_NAME/public/;

    try_files \$uri/index.html \$uri.html \$uri @app;
    error_page 502 503 =503                  @maintenance;
    error_page 500 504 =500                  @server_error;

    location @app {
      proxy_set_header X-Real-IP \$remote_addr;
      proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
      proxy_set_header Host \$http_host;
      proxy_redirect off;

      # enable this if and only if you use HTTPS, this helps Rack
      # set the proper protocol for doing redirects:
      proxy_set_header X-Forwarded-Proto https;

      proxy_pass http://app_server;
    }

    location @maintenance {
      root /srv/$APP_NAME/public;
      try_files /503.html =503;
    }

    location @server_error {
      root /srv/$APP_NAME/public;
      try_files /500.html =500;
    }

    location ^~ /assets/ {
      gzip_static on;
      expires max;
      add_header Cache-Control public;
    }

    location = /favicon.ico {
      expires    max;
      add_header Cache-Control public;
    }
  }

  server {
    listen 80;
    server_name assets.$DOMAIN_NAME;

    root /srv/$APP_NAME/public/;

    access_log /srv/$APP_NAME/log/access-assets.log;
    error_log /srv/$APP_NAME/log/error-assets.log;

    location / {
      deny all;
    }

    location ^~ /assets/ {
      allow all;
      gzip_http_version 1.0;
      gzip_static  on;
      expires      365d;
      add_header   Last-Modified "";
      add_header   Cache-Control public;
    }
  }
EOF
)

if ! check_vhost "$APP_NAME" "$new_vhost"; then
  echo "Creating vhost for '$APP_NAME'"
  [[ $DRY_RUN ]] || create_vhost "$APP_NAME" "$DOMAIN_NAME" "$new_vhost" "$SSL_CERT" "$SSL_KEY"
fi