#!/bin/sh

cd sql/

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

echo "-- init.sql --" > init.sql

for unit in $sql; do
    if [ -d $unit ]; then
        for file in $unit/*; do
            if [ -f "$file" ]; then
                cat "$file" >> init.sql && echo "add... $file"
            fi
        done
    elif [ -f $unit ]; then
        cat "$unit" >> init.sql && echo "add... $unit"
    fi
done


#for file in ./entity/*; do
#    if [ -f "$file" ]; then
#        echo "add... $file"
#        cat "$file" >> main.sql
#    fi
#done
#
#cat ./role.sql >> main.sql && echo "add... ./role.sql"
#
#cat ./users.sql >> main.sql && echo "add... ./users.sql"
#
#cat ./rls.sql >> main.sql && echo "add... ./rls.sql"
#
#echo "add... ./old-db-consistency.sql"
#cat ./old-db-consistency.sql >> main.sql
#
#for file in ./func/*; do
#    if [ -f "$file" ]; then
#        echo "add... $file"
#        cat "$file" >> main.sql
#    fi
#done
#
#for file in ./trigger/*; do
#    if [ -f "$file" ]; then
#        echo "add... $file"
#        cat "$file" >> main.sql
#    fi
#done

mv init.sql ..
echo "done!"
