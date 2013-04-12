# Install s3fs from source
#
# Environment variables required:
#
# AWS_ACCESS_KEY            # access key for aws
# AWS_SECRET_KEY            # secret key for aws
# S3_BUCKET                 # bucket for s3 backups
# DRY_RUN                   # if set, don't execute install

function check_s3fs() {
  which s3fs > /dev/null 2>&1
}

function install_s3fs() {
  apt-get -y install build-essential libfuse-dev fuse-utils libcurl4-openssl-dev libxml2-dev mime-support
  mkdir -p /usr/local/build && mkdir -p /usr/local/sources
  wget -cq --directory-prefix='/usr/local/sources' http://s3fs.googlecode.com/files/s3fs-1.62.tar.gz
  tar -xzf /usr/local/sources/s3fs-1.62.tar.gz -C /usr/local/build
  (cd /usr/local/build/s3fs-1.62 &&
  ./configure --prefix=/usr/local &&
  make && make install)
}

function check_nginx_upstart() {
  test -e /etc/init/s3.conf
}

function create_nginx_upstart() {
  echo "$1" > /etc/init/s3.conf
  start s3
}

function check_s3fs_password() {
  local password=$(</etc/passwd-s3fs)
  [[ -e /etc/passwd-s3fs ]] && 
    diff -q <(echo "$password") <(echo "$1") > /dev/null 2>&1
}

function create_s3fs_password() {
  echo "$1" > /etc/passwd-s3fs
  chmod 650 /etc/passwd-s3fs  
}

function check_s3fs_mount() {
  test -d /mnt/s3
}

function create_s3fs_mount() {
  mkdir -p /mnt/s3
}

s3fs_password=$(cat <<EOF
$AWS_ACCESS_KEY:$AWS_SECRET_KEY
EOF
)

s3fs_upstart=$(cat <<EOF
description "Mount Amazon S3 file system on system start" 

start on (local-filesystems and net-device-up IFACE!=lo)
stop on runlevel [016]

respawn

exec s3fs -f $S3_BUCKET /mnt/s3 -o use_cache=/tmp -o allow_other
EOF
)

if ! check_s3fs ; then
  echo "Installing s3fs from source"
  [[ $DRY_RUN ]] || install_s3fs
fi

if ! check_s3fs_upstart ; then
  echo "Creating s3fs upstart config"
  [[ $DRY_RUN ]] || create_s3fs_upstart "$s3fs_upstart"
fi

if ! check_s3fs_password "$s3fs_password"; then
  echo "Creating s3fs password"
  [[ $DRY_RUN ]] || create_s3fs_password "$s3fs_password"
fi

if ! check_s3fs_mount; then
  echo "Creating s3fs mount"
  [[ $DRY_RUN ]] || create_s3fs_mount
fi