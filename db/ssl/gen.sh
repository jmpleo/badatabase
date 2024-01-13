#!/bin/bash

openssl req -new \
        -newkey rsa:2048 \
        -days 365 \
        -nodes -x509 \
        -subj "/C=US/ST=State/L=City/O=Organization/CN=localhost" \
        -keyout postgres.key -out postgres.crt

