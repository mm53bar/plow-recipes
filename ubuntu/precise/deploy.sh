# Use git to deploy your rails app
#
# Environment variables required:
#
# DEPLOY_TO                 # directory where your app lives
# REF                       # if set, specifies the git ref to deploy
# DRY_RUN                   # if set, don't execute install

function deploy() {
  pushd $1
  git fetch origin && git reset --hard $2
  git rev-parse HEAD > REVISION
  bin/bundle install --deployment --quiet --binstubs --without development test
  bin/foreman run rake assets:precompile
  bin/bluepill --no-privileged -c $1/tmp restart
  popd
}

if [ -z "$REF" ]; then
  REMOTE_REF=origin/master
else
  REMOTE_REF=origin/$REF
fi

echo "Deploying to '$DEPLOY_TO'"
[[ $DRY_RUN ]] || deploy "$DEPLOY_TO" "$REMOTE_REF"