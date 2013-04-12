# Install node.js
#
# Environment variables required:
#
# DRY_RUN                   # if set, don't execute install

function check_nodejs() {
  dpkg -s "nodejs"  > /dev/null 2>&1
}

function install_nodejs() {
  apt-get install -y python-software-properties
  add-apt-repository ppa:chris-lea/node.js
  apt-get update
  apt-get install -y nodejs
}

if ! check_nodejs; then
  echo "Installing node.js"
  [[ $DRY_RUN ]] || install_nodejs
fi