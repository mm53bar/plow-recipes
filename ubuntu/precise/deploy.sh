# Use git to deploy your rails app
#
# Environment variables required:
#
# DEPLOY_TO                 # directory where your app lives
# REF                       # if set, specifies the git ref to deploy
# REPO                      # git repo to clone
# DRY_RUN                   # if set, don't execute install

function check_deploy() {
  [[ -d $1 ]] && git status > /dev/null 2>&1
}

function deploy() {
  pushd $1
  git fetch origin && git reset --hard $2
  git rev-parse HEAD > REVISION
  bin/bundle install --deployment --quiet --binstubs --without development test
  bin/foreman run rake assets:precompile
  bin/bluepill --no-privileged -c $1/tmp restart
  popd
}

function deploy_setup() {
  mkdir -p $1
  git clone --no-checkout $2 $1
}

if [ -z "$REF" ]; then
  REMOTE_REF=origin/master
else
  REMOTE_REF=origin/$REF
fi

if ! check_deploy "$DEPLOY_TO" ; then
  echo "Setting up application at '$DEPLOY_TO'"
  [[ $DRY_RUN ]] || deploy_setup "$DEPLOY_TO" "$REPO"
fi

echo "Deploying to '$DEPLOY_TO'"
[[ $DRY_RUN ]] || deploy "$DEPLOY_TO" "$REF"


