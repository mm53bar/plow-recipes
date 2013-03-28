export DEBIAN_FRONTEND=noninteractive

apt-get update
apt-get -y upgrade

apt-get -y install git-core ntp whiptail curl build-essential libssl-dev libreadline6-dev
