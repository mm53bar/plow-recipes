# Install nginx from source
#
# Environment variables required:
#
# DRY_RUN                   # if set, don't execute install

function check_nginx() {
  test -x /opt/nginx
}

function install_nginx() {
  apt-get -y install libpcre3 libpcre3-dev libpcrecpp0 libssl-dev zlib1g-dev

  mkdir -p /usr/local/nginx && mkdir -p /usr/local/build && mkdir -p /usr/local/sources
  wget -cq --directory-prefix='/usr/local/sources' http://nginx.org/download/nginx-1.3.7.tar.gz
  tar xzf /usr/local/sources/nginx-1.3.7.tar.gz -C /usr/local/build
  (cd /usr/local/build/nginx-1.3.7 &&
  ./configure --prefix=/opt/nginx --user=nginx --group=nginx --with-http_ssl_module --with-http_stub_status_module --with-http_gzip_static_module --without-mail_pop3_module --without-mail_imap_module --without-mail_smtp_module &&
  make && make install )
  adduser --system --no-create-home --disabled-login --disabled-password --group nginx
}

function check_nginx_upstart() {
  test -e /etc/init/nginx.conf
}

function create_nginx_upstart() {
  echo "$1" > /etc/init/nginx.conf
  restart nginx
}

function check_nginx_config() {
  test -d /opt/nginx/sites-available && test -d /opt/nginx/sites-enabled
}

function create_nginx_config() {
  mkdir -p /opt/nginx/sites-available
  mkdir -p /opt/nginx/sites-enabled
  rm /opt/nginx/conf/nginx.conf
  echo "$1" > /opt/nginx/conf/nginx.conf
  restart nginx
}

upstart=$(cat <<EOF
# nginx
 
description "nginx http daemon"
author "George Shammas <georgyo@gmail.com>"
 
start on (filesystem and net-device-up IFACE=lo)
stop on runlevel [!2345]
 
env DAEMON=/opt/nginx/sbin/nginx
env PID=/var/run/nginx.pid
 
expect fork
respawn
respawn limit 10 5
#oom never
 
pre-start script
        $DAEMON -t
        if [ $? -ne 0 ]
                then exit $?
        fi
end script
 
exec $DAEMON
EOF
)

config=$(cat <<EOF
user  nginx;
worker_processes  1;

#error_log  logs/error.log;
#error_log  logs/error.log  notice;
#error_log  logs/error.log  info;

#pid        logs/nginx.pid;


events {
    worker_connections  1024;
}


http {
    include       mime.types;
    default_type  access_modulelication/octet-stream;

    #log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
    #                  '$status $body_bytes_sent "$http_referer" '
    #                  '"$http_user_agent" "$http_x_forwarded_for"';

    #access_log  logs/access.log  main;

    sendfile        on;
    #tcp_nopush     on;

    #keepalive_timeout  0;
    keepalive_timeout  65;

    gzip                    on;
    gzip_http_version       1.1;
    gzip_disable            "msie6";
    gzip_vary               on;
    gzip_min_length         1100;
    gzip_buffers            64 8k;
    gzip_comp_level         3;
    gzip_proxied            any;
    gzip_types              text/plain text/css application/x-javascript text/xml application/xml;
    
    include /opt/nginx/sites-enabled/*;
    
    server {
        listen       80;
        server_name  localhost;

        #charset koi8-r;

        #access_log  logs/host.access.log  main;

        location / {
            root   html;
            index  index.html index.htm;
        }

        #error_page  404              /404.html;

        # redirect server error pages to the static page /50x.html
        #
        error_page   500 502 503 504  /50x.html;
        location = /50x.html {
            root   html;
        }

        # proxy the PHP scripts to Apache listening on 127.0.0.1:80
        #
        #location ~ \.php$ {
        #    proxy_pass   http://127.0.0.1;
        #}

        # pass the PHP scripts to FastCGI server listening on 127.0.0.1:9000
        #
        #location ~ \.php$ {
        #    root           html;
        #    fastcgi_pass   127.0.0.1:9000;
        #    fastcgi_index  index.php;
        #    fastcgi_param  SCRIPT_FILENAME  /scripts$fastcgi_script_name;
        #    include        fastcgi_params;
        #}

        # deny access to .htaccess files, if Apache's document root
        # concurs with nginx's one
        #
        #location ~ /\.ht {
        #    deny  all;
        #}
    }


    # another virtual host using mix of IP-, name-, and port-based configuration
    #
    #server {
    #    listen       8000;
    #    listen       somename:8080;
    #    server_name  somename  alias  another.alias;

    #    location / {
    #        root   html;
    #        index  index.html index.htm;
    #    }
    #}


    # HTTPS server
    #
    #server {
    #    listen       443;
    #    server_name  localhost;

    #    ssl                  on;
    #    ssl_certificate      cert.pem;
    #    ssl_certificate_key  cert.key;

    #    ssl_session_timeout  5m;

    #    ssl_protocols  SSLv2 SSLv3 TLSv1;
    #    ssl_ciphers  HIGH:!aNULL:!MD5;
    #    ssl_prefer_server_ciphers   on;

    #    location / {
    #        root   html;
    #        index  index.html index.htm;
    #    }
    #}

}
EOF
)

if ! check_nginx ; then
  echo "Installing nginx from source"
  [[ $DRY_RUN ]] || install_nginx
fi

if ! check_nginx_upstart ; then
  echo "Installing nginx upstart config"
  [[ $DRY_RUN ]] || create_nginx_upstart "$upstart"
fi

if ! check_nginx_config ; then
  echo "Installing nginx config"
  [[ $DRY_RUN ]] || create_nginx_config "$config"
fi