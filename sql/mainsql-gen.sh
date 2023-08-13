#!/bin/sh

echo "add... table.sql"
cat ./table.sql > main.sql

for file in ./func/*; do
    if [ -f "$file" ]; then
        echo "add... $file"
        cat "$file" >> main.sql
    fi
done

echo "done!"