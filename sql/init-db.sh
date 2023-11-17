#!/bin/bash

if [ $# -ne 1 ]; then
    echo "Usage: $0 <db-name>"
    exit 1
fi

psql -c "create database $1 owner $(whoami)" && \
psql -d $1 -f "./init.sql"
