# Create S3 backups for postgres
#
# Environment variables required:
#
# DB_NAME                   # database that should be backed up
# DRY_RUN                   # if set, don't execute install
#
# Recipes required:
#
# s3fs

function check_pg_backup() {
  test -x /usr/local/bin/pg_backup.sh
}

function create_pg_backup() {
  echo "$1" > /usr/local/bin/pg_backup.sh
  chmod +x /usr/local/bin/pg_backup.sh
  echo "$2" > /etc/cron.d/pg_backup
  mkdir -p /mnt/s3/pg_backup
}

pg_backup_script=$(cat <<EOF
# Postgres backup script

fail()
{
    echo `date +%h:%m:%s` error: $1
    kill -sigint $$
}

if [ "$1" ]
then
   frequency=$1
else
    fail "frequency missing (arg 1)"
fi

if [ "$2" ]
then
   backup_dir=$2
else
    fail "path to backup dir missing (arg 2)"
fi

if [ "$3" ]
then
    user=$3
else
    fail "user missing (arg 3)"
fi

if [ "$4" ]
then
    keep=$4
else
    fail "number of keeps missing (arg 4)"
fi

before=`date +%s`
printf "\n------------------------------------------------------------------------------\n"
printf "%s: STARTING %s backups ........\n" `date +%h:%m:%s` $frequency

full_path=$backup_dir/$frequency
date=`date +%Y%m%d%H%M`
mkdir -p $full_path

ignore="staging|test"

database_list=`psql -l | egrep -v $ignore | grep $user | awk '{print $1}' | grep -v \|`

count=`ls $full_path | wc -l`

if [ $count -gt $keep ]
then
    remove=`expr $count - $keep`
    files=`ls $full_path | sort -n | head -$remove`
    for file in $files
    do    
        rm $full_path/$file
    done
fi

for database in $database_list
do
    database_before=`date +%s`
    printf "%s: creating %s backup for %s\n" `date +%h:%m:%s` $frequency $database
    dump_file="$full_path/$database-$date.gz"
    `pg_dump --no-acl --no-owner --clean $database | gzip > $dump_file`
    database_after=`date +%s`
    database_elapsed_seconds=`expr $database_after - $database_before`
    printf "%s: %s backup for %s finished in %s seconds\n" `date +%h:%m:%s` $frequency $database $database_elapsed_seconds
done

after=`date +%s`
elapsed_seconds=`expr $after - $before`

if [ "$elapsed_seconds" ]
then
   printf "%s: COMPLETED %s backups in %s seconds\n" `date +%h:%m:%s` $frequency  $elapsed_seconds
fi
EOF
)

pg_backup_cron=$(cat <<EOF
02 * * * * postgres /usr/local/bin/pg_backup.sh hourly /mnt/s3/pg_backup $DB_NAME 24 >> /mnt/s3/pg_backup/pg_backup.log 2>&1
02 1 * * * postgres /usr/local/bin/pg_backup.sh daily /mnt/s3/pg_backup $DB_NAME 5 >> /mnt/s3/pg_backup/pg_backup.log 2>&1
02 3 * * 0 postgres /usr/local/bin/pg_backup.sh weekly /mnt/s3/pg_backup $DB_NAME 4 >> /mnt/s3/pg_backup/pg_backup.log 2>&1
02 5 1 * * postgres /usr/local/bin/pg_backup.sh monthly /mnt/s3/pg_backup $DB_NAME 4 >> /mnt/s3/pg_backup/pg_backup.log 2>&1
EOF
)

if ! check_pg_backup; then
  echo "Creating backups from postgres to S3"
  [[ $DRY_RUN ]] || create_pg_backup "$pg_backup_script" "$pg_backup_cron"
fi