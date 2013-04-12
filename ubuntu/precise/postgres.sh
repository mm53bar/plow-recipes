# Install postgres
#
# Environment variables required:
#
# DB_USER                   # database user
# DB_PASSWORD               # database password
# DB_NAME                   # database name
# DRY_RUN                   # if set, don't execute install

function check_postgres() {
  dpkg -s "postgresql-9.2"  > /dev/null 2>&1
}

function install_postgres() {
  add-apt-repository ppa:pitti/postgresql
  apt-get update
  apt-get install -y postgresql-9.2 libpq-dev

}

function check_postgres_user() {
  sudo -u postgres psql -tAc "SELECT 1 FROM pg_roles WHERE rolname='$1'" | grep -q 1
}

function create_postgres_user() {
  echo "CREATE USER $1 WITH PASSWORD '$2';" | sudo -u postgres psql
  echo "CREATE DATABASE $3 OWNER $1;" | sudo -u postgres psql
}

if ! check_postgres; then
  echo "Installing postgres"
  [[ $DRY_RUN ]] || install_postgres
fi

if ! check_postgres_user "$DB_USER"; then
  echo "Create postgres user and database"
  [[ $DRY_RUN ]] || create_postgres_user "$DB_USER" "$DB_PASSWORD" "$DB_NAME"
fi