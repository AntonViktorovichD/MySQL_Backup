#!/bin/bash

DB_HOST="****************"
DB_USER="****************"
DB_PASS="****************"
DB_NAME="****************"

BACKUP_DIR="/home/grand/web/grandgold.jewelry/public_html/MySQL_Backup"
BACKUP_FILE="backup_$(date +%Y-%m-%d_%H-%M-%S).sql.gz"

REMOTE_USER="*****************"
REMOTE_HOST="*****************"
REMOTE_DIR="/home/User/web/MySQL_Backup"
REMOTE_BACKUP_PATTERN="backup_*_${DB_NAME}.sql.gz"

remove_old_backups() {
    local dir=$1
    local pattern=$2
    local current_file=$3
    local num_to_keep=$4

    old_backups=$(ls -1t "$dir" | grep "$pattern" | grep -v "$current_file" | tail -n +"$((num_to_keep+1))")

    if [[ -n "$old_backups" ]]; then
        echo "Removing old backups:"
        echo "$old_backups"
        rm -f $dir/$old_backups
    fi
}

mkdir -p "$BACKUP_DIR"

if [[ $(date +%d) == "01" ]]; then

    BACKUP_FILE="$BACKUP_DIR/backup_$(date +%Y-%m-%d_%H-%M-%S).sql.gz"

    mysqldump -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" | gzip > "$BACKUP_FILE"

    remove_old_backups "$BACKUP_DIR" "backup_$(date +%Y-%m)-01.*_${DB_NAME}.sql.gz" "$(basename $BACKUP_FILE)" 10
else

    BACKUP_FILE="$BACKUP_DIR/backup_$(date +%Y-%m-%d_%H-%M-%S).sql.gz"

    mysqldump -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" | gzip > "$BACKUP_FILE"

    remove_old_backups "$BACKUP_DIR" "backup_$(date +%Y-%m-%d).*_${DB_NAME}.sql.gz" "$(basename $BACKUP_FILE)" 10
fi

rsync "$BACKUP_DIR/$(ls -1t "$BACKUP_DIR" | grep "backup_*_${DB_NAME}.sql.gz" | head -n 1)" "$REMOTE_USER"@"$REMOTE_HOST":"$REMOTE_DIR"

old_remote_backups=$(ssh "$REMOTE_USER"@"$REMOTE_HOST" "ls -1t $REMOTE_DIR/$REMOTE_BACKUP_PATTERN | grep -v "$(date +%Y-%m-%d)" | tail -n +11")

if [[ -n "$old_remote_backups" ]]; then
echo "Removing old backups on remote server:"
echo "$old_remote_backups"
ssh "$REMOTE_USER"@"$REMOTE_HOST" "rm -f $old_remote_backups"
fi
