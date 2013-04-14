# Restore postgres from pg_backup
#
# Environment variables required:
#
# DB_NAME                   # database name
# DRY_RUN                   # if set, don't execute install
#
# Recipes required:
#
# postgres
# pg_backup
# s3fs

function restore_database() {
  local backup_path="/mnt/s3/pg_backup/hourly"
  local latest_dump_file=`ls $backup_path | sort -nr | head -n 1`
  gunzip -c $backup_path/$latest_dump_file | sudo -u postgres psql -d $1
}

echo "Restoring postgres database '$DB_NAME'"
[[ $DRY_RUN ]] || restore_database "$DB_NAME"
