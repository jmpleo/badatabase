#!/bin/bash

source `dirname $0`/configureKerberosClient.sh

# Your application

# You can use the `kadminCommand` function to perform kadmin commands. Example:

until pg_isready -U badatabase -d badatabase -h primary.badatabase.local; do
    echo 'Waiting auth...'
    sleep 1
done

echo 'Kerberos authentication success'
