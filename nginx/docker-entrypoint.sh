#!/bin/bash

set -e

# HOST_DOMAIN="host.docker.internal"
# ping -q -c1 $HOST_DOMAIN > /dev/null 2>&1
# if [ $? -ne 0 ]; then
#   HOST_IP=$(ip route | awk 'NR==1 {print $3}')
#   echo -e "$HOST_IP\t$HOST_DOMAIN" >> /etc/hosts
# fi

echo

find /etc/nginx \
    -type f -exec sed -i \
        -e "s|\\\.example\\\.com|\\\.$(echo $APP_DOMAIN | sed 's/\./\\\\./g')|g" \
        -e "s|example\\\.com|$(echo $APP_DOMAIN | sed 's/\./\\\\./g')|g" \
    {} \;

find /etc/nginx \
    -type f -exec sed -i \
        -e "s|{{APP_DOMAIN}}|$APP_DOMAIN|g" \
        -e "s|{{REMOTE_SRC}}|$REMOTE_SRC|g" \
        -e "s|{{ROOT_SRC}}|$ROOT_SRC|g" \
    {} \;

echo 'Server Started...'
echo

exec "$@"
