# Configure misc stuff for a Rails app
#
# Environment variables required:
#
# DEPLOYER                  # should be same as $APP_NAME
# GIT_HOST                  # ex. github.com
# DRY_RUN                   # if set, don't execute install
#
# Recipes required:
#
# deployer

function check_app_folder() {
  test -d /srv/$1
}

function create_app_folder() {
  mkdir -p /srv/$1
  chown $1 /srv/$1
}

function check_git_host() {
  test -e /home/$1/.ssh/known_hosts && 
     grep -Fq $2 /home/$1/.ssh/known_hosts
}

function create_git_host() {
  ssh-keyscan $2 | tee /home/$1/.ssh/known_hosts
  chown $1:$1 /home/$1/.ssh/known_hosts
}

if ! check_app_folder; then
  echo "Creating folder for '$DEPLOYER'"
  [[ $DRY_RUN ]] || create_app_folder "$DEPLOYER"
fi

if ! check_git_host; then
  echo "Adding git host"
  [[ $DRY_RUN ]] || create_git_host "$DEPLOYER" "$GIT_HOST"
fi