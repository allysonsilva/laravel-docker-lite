#!/bin/bash

set -e

echo

find /etc/nginx \
    -type f -exec sed -i \
        -e "s|{{SITE_DOMAIN}}|$SITE_DOMAIN|g" \
        -e "s|{{SITE_SRC}}|$SITE_SRC|g" \
    {} \;

# ================================================
# ================================================

export DNS_DOCKER_SERVER=$(cat /etc/resolv.conf | grep -i '^nameserver' | head -n1 | cut -d ' ' -f2)

if [[ -z "$ADMIN_DOMAIN" ]]; then
    rm -f /etc/nginx/servers/admin.conf 2> /dev/null
fi

for conf in $(find /etc/nginx -type f -not -path '*/\.*' -regex '.*\.conf' | sort);
do
    envsubst '${DNS_DOCKER_SERVER}
              $ADMIN_DOMAIN
              ${ADMIN_SRC}' \
                < $conf | sponge $conf
done

if [ -n "$ADMIN_HTPASSWD" ]; then
    echo $ADMIN_HTPASSWD > /etc/nginx/auths/admin.htpasswd
fi

# ================================================
# ================================================

mkdir -p "$SITE_SRC/public" \
         "$ADMIN_SRC/public"

touch "$SITE_SRC/public/index.php" \
      "$ADMIN_SRC/public/index.php"

# ================================================
# ================================================

if [[ ${FORCE_CHANGE_OWNERSHIP:-false} == true ]]; then
    echo
    echo "CHOWN - Change User Ownership"
    echo

    chown -R ${USER_NAME}:${GROUP_NAME} $SITE_SRC $ADMIN_SRC
fi

# ================================================
# ================================================

echo '================='
echo 'Server Started...'
echo '================='

exec "$@"
