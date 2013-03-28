# Install unicorn-friendly vhost for nginx
#
# Environment variables required:
#
# APP_NAME                  # application name
# SSL_CERT                  # filename for ssl certificate
# SSL_KEY                   # filename for ssl key

function check_vhost() {
  [[ -e /opt/nginx/sites-enabled/$1 ]] && 
  diff -q /opt/nginx/sites-enabled/$1 files/unicorn_vhost > /dev/null 2>&1
}

function create_vhost() {
  rm -f /opt/nginx/sites-available/$1
  cp files/unicorn_vhost /opt/nginx/sites-available/$1
  ln -sf /opt/nginx/sites-available/$1 /opt/nginx/sites-enabled/$1
  cp files/$2 /etc/ssl/
  cp files/$3 /etc/ssl/
  restart nginx
}

if ! check_vhost "$APP_NAME"; then
  echo "Creating vhost for '$APP_NAME'"
  [[ $DRY_RUN ]] || create_vhost "$APP_NAME" "$SSL_CERT" "$SSL_KEY"
fi