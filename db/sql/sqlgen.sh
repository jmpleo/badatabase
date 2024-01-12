#!/bin/sh

if [ -z "$1" ] || [ ! -d "$1" ] || [ -z "$2" ] || [ ! -d "$2" ]; then
    exit 1
fi

SQL_PATH=$1
INIT_SQL_SCRIPT=$2/init.sql

cd $SQL_PATH

# WARNING! it is important to follow the script sequence
sql="\
crypto.sql \
entity \
func \
trigger \
view \
role.sql \
users.sql \
rls.sql \
replication.sql \
"

echo "-- init.sql --" > $INIT_SQL_SCRIPT

for unit in $sql; do
    if [ -d $unit ]; then
        for file in $unit/*; do
            if [ -f "$file" ]; then
                cat "$file" >> $INIT_SQL_SCRIPT && echo "add... $file"
            fi
        done
    elif [ -f $unit ]; then
        cat "$unit" >> $INIT_SQL_SCRIPT && echo "add... $unit"
    fi
done

echo "done!"
