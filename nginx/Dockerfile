FROM nginx:1.16-alpine

# Remove default files
RUN set -xe \
    && rm /etc/nginx/fastcgi_params \
    && rm /etc/nginx/koi-utf \
    && rm /etc/nginx/koi-win \
    && rm /etc/nginx/scgi_params \
    && rm /etc/nginx/uwsgi_params \
    && rm /etc/nginx/win-utf \
    && rm -rf /etc/nginx/conf.d

RUN apk --update upgrade --no-cache -q; \
    apk add --no-cache \
        jq \
        sudo \
        curl \
        wget \
        bash \
        tzdata \
        openssl \
        openssh \
        coreutils \
        ca-certificates \
    && rm -rf /var/cache/apk/*

ARG USER_NAME=app
ENV USER_NAME $USER_NAME

ARG GROUP_NAME=app
ENV GROUP_NAME $GROUP_NAME

ARG APP_DOMAIN
ENV APP_DOMAIN ${APP_DOMAIN:-domain.xyz}

# Should be the same project container path as the application that is running PHP-FPM
ARG REMOTE_SRC=/var/www/app
ENV REMOTE_SRC $REMOTE_SRC

ARG ROOT_SRC=${REMOTE_SRC}/public
ENV ROOT_SRC $ROOT_SRC

RUN set -xe; \
    addgroup --gid ${USER_GID:-1000} $GROUP_NAME; \
    addgroup root $GROUP_NAME; \
    adduser --uid ${USER_UID:-1000} -h /home/$USER_NAME -s /bin/bash -D -G $GROUP_NAME $USER_NAME; \
    echo "$USER_NAME ALL = (ALL) NOPASSWD: ALL" >> /etc/sudoers

RUN set -xe; \
    touch /var/run/nginx.pid; \
    mkdir -p $REMOTE_SRC; \
    mkdir -p $ROOT_SRC; \
    touch $ROOT_SRC/index.php

ARG TZ=America/Fortaleza

RUN set -xe \
    && ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone \
    && ln -sf /dev/stdout /var/log/nginx/${APP_DOMAIN}.access.log \
    && ln -sf /dev/stderr /var/log/nginx/${APP_DOMAIN}.error.log

# RUN echo '30 2 * * 1 /usr/bin/certbot renew --force-renew --renew-hook "/usr/sbin/nginx -s reload"' >> /var/spool/cron/crontabs/root \
#     && echo "# Empty Line" >> /etc/crontabs/root

COPY ./certs/ /etc/nginx/certs
COPY ./configs/ /etc/nginx/

RUN set -xe; \
    chown -R ${USER_NAME}:${GROUP_NAME} $REMOTE_SRC; \
    chown -R ${USER_NAME}:${GROUP_NAME} /etc/nginx /var/log; \
    chown ${USER_NAME}:${GROUP_NAME} /var/run/nginx.pid

# Expose webserver port
EXPOSE 80 443

COPY ./docker-entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

WORKDIR /etc/nginx/

ENTRYPOINT ["/entrypoint.sh"]

CMD ["nginx", "-g", "daemon off;"]

# vim:set ft=dockerfile:
