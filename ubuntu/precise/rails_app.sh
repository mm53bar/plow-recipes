# Configure misc stuff for a Rails app
#
# Environment variables required:
#
# DEPLOY_TO                 # path where your app lives
# DEPLOYER                  # user that will be deploying the app
# GIT_HOST                  # ex. github.com
# DRY_RUN                   # if set, don't execute install
#
# Recipes required:
#
# deployer

function set_deploy_permissions() {
  local base_deploy_path=`dirname $1`
  mkdir -p $base_deploy_path
  chown -R root:deployers $base_deploy_path
  chmod -R 0775 $base_deploy_path
}

function check_git_host() {
  test -e /home/$1/.ssh/known_hosts && 
     grep -Fq $2 /home/$1/.ssh/known_hosts
}

function create_git_host() {
  ssh-keyscan $2 | tee /home/$1/.ssh/known_hosts
  chown $1:$1 /home/$1/.ssh/known_hosts
}

[[ $DRY_RUN ]] || set_deploy_permissions "$DEPLOY_TO"

if ! check_git_host "$DEPLOYER" "$GIT_HOST"; then
  echo "Adding git host"
  [[ $DRY_RUN ]] || create_git_host "$DEPLOYER" "$GIT_HOST"
fi