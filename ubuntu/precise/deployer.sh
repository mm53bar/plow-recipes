# Install deploy user
#
# Environment variables required:
#
# DEPLOYER                  # should be same as $APP_NAME
# DRY_RUN                   # if set, don't execute install

function check_deployer() {
  test -f /home/$1/.ssh/authorized_keys
}

function create_deployer() {
  useradd --create-home --shell /bin/bash --user-group --groups admin $1  
  mkdir -p /home/$1/.ssh
  cp files/id_rsa.pub /home/$1/.ssh/authorized_keys
  chmod 700 /home/$1/.ssh
  chmod 600 /home/$1/.ssh/authorized_keys
  chown -R $1:$1 /home/$1/.ssh
}

if ! check_deployer "$DEPLOYER"; then
  echo "Creating user '$DEPLOYER'"
  [[ $DRY_RUN ]] || create_deployer "$DEPLOYER"
fi