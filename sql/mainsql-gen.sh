#!/bin/sh

echo "-- main.sql --" > main.sql

for file in ./entity/*; do
    if [ -f "$file" ]; then
        echo "add... $file"
        cat "$file" >> main.sql
    fi
done

echo "add... ./role.sql"
cat ./role.sql >> main.sql

echo "add... ./old-db-consistency.sql"
cat ./old-db-consistency.sql >> main.sql

for file in ./func/*; do
    if [ -f "$file" ]; then
        echo "add... $file"
        cat "$file" >> main.sql
    fi
done

for file in ./trigger/*; do
    if [ -f "$file" ]; then
        echo "add... $file"
        cat "$file" >> main.sql
    fi
done


echo "done!"
