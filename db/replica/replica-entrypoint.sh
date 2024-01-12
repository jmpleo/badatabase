#!/bin/sh

BACKUP_DIR=/backups/$(date +%Y-%m-%d_%H-%M-%S)

until pg_basebackup --pgdata=/var/lib/postgresql/data -R --slot=replication_slot --host=badatabase_primary --port=5432
do
    echo 'Waiting for primary to connect...'
    sleep 1s
done

echo 'Backup done, starting replica...'

chmod 0700 /var/lib/postgresql/data
mkdir -p $BACKUP_DIR && mv /var/lib/postgresql/data/* $BACKUP_DIR

postgres
