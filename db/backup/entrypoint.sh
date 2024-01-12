#!/bin/sh

#mkdir -p /backup/new
#mv /backup/new/* /backup/old

until pg_basebackup --pgdata=/backup/$(date +%Y-%m-%d_%H-%M-%S) --host=badatabase_primary --port=5432
do
    echo 'Waiting for primary to connect...'
    sleep 1s
done

echo 'Backup done'
sleep 7d
