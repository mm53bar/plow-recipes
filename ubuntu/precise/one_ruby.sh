# Install default ruby
# 
# Based on http://blog.arkency.com/2012/11/one-app-one-user-one-ruby/
#
# Environment variables required:
#
# RUBY_VERSION              # i.e. 1.9.3-p125, 2.0.0-p0
# DEPLOYER                  # should be same as $APP_NAME
# DRY_RUN                   # if set, don't execute install

function check_ruby_build() {
  which ruby-build > /dev/null 2>&1
}

function install_ruby_build() {
  mkdir -p /usr/local/sources
  git clone git://github.com/sstephenson/ruby-build.git /usr/local/sources/ruby-build
  (cd /usr/local/sources/ruby-build && ./install.sh)
}  

function check_ruby() {
  test -d "/home/$2/$1"
}

function install_ruby() {
  ruby-build $1 /home/$2/$1
}

function check_ruby_path() {
  grep -xq "export PATH=\$HOME/$1/bin:\$PATH" /home/$2/.bashrc
}

function install_ruby_path() {
  sed -i "1i export PATH=\$HOME/$1/bin:\$PATH" /home/$2/.bashrc
}

function check_bundler() {
  test -d /home/$2/$1/bin && /home/$2/$1/bin/gem list | grep -q bundler
}

function install_bundler() {
  /home/$2/$1/bin/gem install bundler --no-ri --no-rdoc
}

if ! check_ruby_build ; then
  echo "Installing ruby-build"
  [[ $DRY_RUN ]] || install_ruby_build
fi

if ! check_ruby "$RUBY_VERSION" "$DEPLOYER" ; then
  echo "Installing ruby $RUBY_VERSION"
  [[ $DRY_RUN ]] || install_ruby "$RUBY_VERSION" "$DEPLOYER"
fi

if ! check_ruby_path "$RUBY_VERSION" "$DEPLOYER" ; then
  echo 'Adding ruby to path'
  [[ $DRY_RUN ]] || install_ruby_path "$RUBY_VERSION" "$DEPLOYER"
fi

if ! check_bundler "$RUBY_VERSION" "$DEPLOYER" ; then
  echo "Installing bundler to ruby $RUBY_VERSION"
  [[ $DRY_RUN ]] || install_bundler "$RUBY_VERSION" "$DEPLOYER"
fi