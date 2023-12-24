#!/bin/sh

cd sql/

# WARNING! it is important to follow the script sequence
sql="\
entity \
func \
trigger \
role.sql \
users.sql \
rls.sql \
"

echo "-- main.sql --" > main.sql

for unit in $sql; do
    if [ -d $unit ]; then
        for file in $unit/*; do
            if [ -f "$file" ]; then
                cat "$file" >> main.sql && echo "add... $file"
            fi
        done
    elif [ -f $unit ]; then
        cat "$unit" >> main.sql && echo "add... $unit"
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


echo "done!"
