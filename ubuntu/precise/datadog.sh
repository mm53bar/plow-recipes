# Install datadog
#
# Environment variables required:
#
# DATADOG_API_KEY           # should be same as $APP_NAME
# DRY_RUN                   # if set, don't execute install

function check_datadog() {
  dpkg -s "datadog-agent"  > /dev/null 2>&1
}

function install_datadog() {
  DD_API_KEY=$1 bash -c "$(curl -L http://dtdg.co/agent-install-ubuntu)"
}

if ! check_datadog; then
  echo "Installing datadog agent"
  [[ $DRY_RUN ]] || install_datadog "$DATADOG_API_KEY"
fi