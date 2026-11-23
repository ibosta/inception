#!/bin/bash
set -e

CERT=/etc/ssl/certs/inception.crt
KEY=/etc/ssl/private/inception.key

if [ ! -f "$CERT" ] || [ ! -f "$KEY" ]; then
    openssl req -x509 -nodes -newkey rsa:2048 -days 365 \
        -keyout "$KEY" -out "$CERT" \
        -subj "/CN=$DOMAIN_NAME"
fi

exec nginx -g "daemon off;"
