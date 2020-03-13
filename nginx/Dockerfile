ARG TAG_SITE_IMAGE
ARG TAG_ADMIN_IMAGE

FROM ${TAG_SITE_IMAGE} as SITE_IMAGE
FROM ${TAG_ADMIN_IMAGE} as ADMIN_IMAGE

FROM nginx:1.17-alpine

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
        moreutils \
        ca-certificates \
    && rm -rf /var/cache/apk/*

ARG USER_NAME=app
ENV USER_NAME $USER_NAME

ARG GROUP_NAME=app
ENV GROUP_NAME $GROUP_NAME

ARG SITE_DOMAIN
ARG SITE_SRC

ARG ADMIN_DOMAIN
ARG ADMIN_SRC

RUN set -xe; \
    addgroup --gid ${USER_GID:-1000} $GROUP_NAME; \
    addgroup root $GROUP_NAME; \
    adduser --uid ${USER_UID:-1000} -h /home/$USER_NAME -s /bin/bash -D -G $GROUP_NAME $USER_NAME; \
    echo "$USER_NAME ALL = (ALL) NOPASSWD: ALL" >> /etc/sudoers

RUN set -xe; \
    mkdir -p /var/cache/nginx/app; \
    touch /var/run/nginx.pid;

ARG TZ=America/Fortaleza

RUN set -xe \
    && ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone \
    && ln -sf /dev/stdout /var/log/nginx/${SITE_DOMAIN}.access.log \
    && ln -sf /dev/stderr /var/log/nginx/${SITE_DOMAIN}.error.log \
    && ln -sf /dev/stdout /var/log/nginx/${ADMIN_DOMAIN}.access.log \
    && ln -sf /dev/stderr /var/log/nginx/${ADMIN_DOMAIN}.error.log

COPY --from=SITE_IMAGE --chown=nginx:nginx $SITE_SRC/public $SITE_SRC/public
COPY --from=SITE_IMAGE --chown=nginx:nginx $SITE_SRC/storage $SITE_SRC/storage

COPY --from=ADMIN_IMAGE --chown=nginx:nginx $ADMIN_SRC/public $ADMIN_SRC/public
COPY --from=ADMIN_IMAGE --chown=nginx:nginx $ADMIN_SRC/storage $ADMIN_SRC/storage

RUN set -xe \
    && cd $SITE_SRC/storage \
    && ls --hide=app | xargs rm -rf \
    && cd $ADMIN_SRC/storage \
    && ls --hide=app | xargs rm -rf

COPY ./certs/ /etc/nginx/certs
COPY ./configs/ /etc/nginx/

RUN set -xe; \
    chown -R ${USER_NAME}:${GROUP_NAME} $SITE_SRC $ADMIN_SRC; \
    chown -R ${USER_NAME}:${GROUP_NAME} /etc/nginx /var/log /var/cache/nginx/app; \
    chown ${USER_NAME}:${GROUP_NAME} /var/run/nginx.pid

# Expose webserver port
EXPOSE 80 443

COPY ./docker-entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

WORKDIR /etc/nginx/

ENTRYPOINT ["/entrypoint.sh"]

# @see https://ubuntu.com/blog/avoiding-dropped-connections-in-nginx-containers-with-stopsignal-sigquit
STOPSIGNAL SIGQUIT

CMD ["nginx", "-g", "daemon off;"]

# vim:set ft=dockerfile:
