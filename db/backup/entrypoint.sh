#!/bin/sh

BACKUP_DIR=/backup/$(date +%Y-%m-%d_%H-%M-%S)

mkdir -p $BACKUP_DIR

until pg_basebackup --pgdata=$BACKUP_DIR --host=badatabase_primary --port=5432
do
    echo 'Waiting for primary to connect...'
    sleep 1s
done

echo 'Backup done'
