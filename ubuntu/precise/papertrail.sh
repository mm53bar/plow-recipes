# Add papertrailapp.com to rsyslog
#
# Environment variables required:
#
# PAPERTRAIL_PORT           # should be same as $APP_NAME
# DRY_RUN                   # if set, don't execute install

function check_papertrail_rsyslog() {
  test -f /etc/rsyslog.d/papertrail.conf
}

function create_papertrail_rsyslog() {
  echo "$1" > /etc/rsyslog.d/papertrail.conf
  restart rsyslog
}

papertrail_config=$(cat <<EOF
*.*;bluepilld.none          @logs.papertrailapp.com:$PAPERTRAIL_PORT
EOF
)

if ! check_papertrail_rsyslog; then
  echo "Adding papertrail to rsyslog"
  [[ $DRY_RUN ]] || create_papertrail_rsyslog "$papertrail_config"
fi