ARG LOCAL_APP_PATH=./src
ARG LOCAL_DOCKER_PATH=./docker
ARG PHP_BASE_IMAGE_VERSION=7.4-fpm-alpine

#####
## COMPOSER
#####

FROM composer:1.9 as vendor

WORKDIR /app

# https://getcomposer.org/doc/03-cli.md#composer-home
ENV COMPOSER_HOME /composer

ARG LOCAL_APP_PATH

# Copy only the files needed to download dependencies to avoid redownloading them when our code changes
COPY $LOCAL_APP_PATH/composer.json composer.json
COPY $LOCAL_APP_PATH/composer.lock composer.lock

RUN set -xe \
    && composer global require --prefer-dist --no-suggest --ansi hirak/prestissimo:"^0.3" \
    && composer global dumpautoload --optimize --ansi \
    && composer config --list --global

# We need to copy our whole application so that we can generate the autoload file inside the vendor folder
# No copy unnecessary files
COPY $LOCAL_APP_PATH/app/ app/
COPY $LOCAL_APP_PATH/bootstrap/ bootstrap/
COPY $LOCAL_APP_PATH/config/ config/
COPY $LOCAL_APP_PATH/database/ database/
COPY $LOCAL_APP_PATH/routes/ routes/
COPY $LOCAL_APP_PATH/storage/framework storage/framework
COPY $LOCAL_APP_PATH/artisan artisan
COPY $LOCAL_APP_PATH/.env.example .env.example

RUN set -xe \
    &&  composer install \
            --optimize-autoloader \
            --ignore-platform-reqs \
            --prefer-dist \
            --ansi \
            --no-dev \
            --no-interaction

#####
## FRONTEND
#####

FROM node:13-alpine as frontend

WORKDIR /app

ARG LOCAL_APP_PATH

# COPY package-lock.json package-lock.json
COPY $LOCAL_APP_PATH/package.json $LOCAL_APP_PATH/webpack.mix.js ./
COPY $LOCAL_APP_PATH/resources/ resources/
COPY $LOCAL_APP_PATH/public/ public/

RUN set -xe \
    && npm install && npm run production

#####
## APP CONTAINER
#####

FROM php:$PHP_BASE_IMAGE_VERSION

ARG LOCAL_APP_PATH
ARG LOCAL_DOCKER_PATH

LABEL maintainer="Allyson Silva <support@allyson.tech>" \
      description="Image for use in LARAVEL applications" \
      version="1.0"

# = /usr/local/etc/php
ENV PHP_INI_DIR ${PHP_INI_DIR:-/usr/local/etc/php}
# = /usr/local/etc/php/conf.d
ENV PHP_INI_SCAN_DIR ${PHP_INI_DIR}/conf.d
# = /usr/local/etc/php-fpm.d
ENV PHP_FPM_POOL_DIR ${PHP_INI_DIR}-fpm.d
# Default PATH LOG
ENV LOG_PATH=/usr/local/var/log
# Path logs PHP/PHP-FPM
ENV PHP_LOG_PATH=$LOG_PATH/php

# Default directory for application deployment
# Location of the folder in the container, path of the folder inside the container
ARG REMOTE_SRC=/var/www/app
ENV REMOTE_SRC $REMOTE_SRC

# Image user
ARG USER_NAME=app
ENV USER_NAME $USER_NAME

# Path docker PHP/APP folder
# Path Config/Dockerfile PHP/APP
ARG LOCAL_DOCKER_PHP_PATH=$LOCAL_DOCKER_PATH/php
ENV LOCAL_DOCKER_PHP_PATH $LOCAL_DOCKER_PHP_PATH

ARG LOCAL_APP_PATH
ENV LOCAL_APP_PATH $LOCAL_APP_PATH

# app || queue || scheduler
ARG CONTAINER_ROLE=app
ENV CONTAINER_ROLE $CONTAINER_ROLE

# worker or horizon {Variables applied when $CONTAINER_ROLE=queue}
ARG LARAVEL_QUEUE_MANAGER
ENV LARAVEL_QUEUE_MANAGER ${LARAVEL_QUEUE_MANAGER:-worker}

ARG APP_ENV=production
ENV APP_ENV ${APP_ENV:-production}

RUN set -xe; \
    \
    echo "---> Installing PHP Extensions"; \
    \
    apk update; \
    \
    apk add --no-cache --virtual .build-deps \
        $PHPIZE_DEPS \
        curl-dev \
        pcre-dev \
        # Mbstring
        oniguruma-dev \
        # SQLite3
        sqlite-dev \
        # for intl extension
        icu-dev \
        libintl \
        openssl-dev \
        # for GD
        freetype-dev \
        libpng-dev \
        libjpeg-turbo-dev \
        libwebp-dev \
        # for amqp
        rabbitmq-c-dev \
        libc-dev \
        libressl-dev \
        # for zip extension
        libzip-dev \
        # for xslt
        libxslt-dev \
        # for gpm extension
        gmp-dev \
        # for soap
        libxml2-dev \
    ; \
    apk add --no-cache --virtual .persistent-deps \
        # for intl extension
        icu-libs \
        # for mongodb
        libssl1.1 \
    ; \
    docker-php-ext-configure gd \
        --enable-gd \
        --with-jpeg \
        --with-webp \
        --with-freetype \
    ; \
    docker-php-ext-configure mysqli --with-mysqli=mysqlnd && \
    docker-php-ext-configure pdo_mysql --with-pdo-mysql=mysqlnd && \
    docker-php-ext-install -j $(nproc) \
        exif \
        calendar \
        xsl \
        intl \
        gd \
        bcmath \
        mbstring \
        gmp \
        pcntl \
        mysqli \
        pdo_mysql \
        soap \
        sockets \
        opcache \
        zip \
    ; \
    pecl install -o -f \
        ds-1.2.9 \
        amqp-1.9.4 \
        mongodb-1.7.4 \
        xdebug-2.9.2 \
    ; \
    # Igbinary: Is a drop in replacement for the standard php serializer.
    # MessagePack: Is an efficient binary serialization format.
    pecl install -o -f \
        igbinary-3.1.2 \
        msgpack-2.1.0 \
    ; \
    # redis/configure \
    #       --with-php-config=/usr/local/bin/php-config \
    #       --enable-redis-igbinary=yes \
    #       --enable-redis-lzf=no \
    #       --enable-redis-zstd=no
    printf "yes \n no \n no \n" | pecl install redis-5.2.0 \
    ; \
    docker-php-ext-enable \
        ds \
        amqp \
        igbinary \
        msgpack \
        redis \
        mongodb \
        xdebug \
    ; \
    php --version \
    ; \
    runDeps="$( \
        scanelf --needed --nobanner --format '%n#p' --recursive /usr/local \
            | tr ',' '\n' \
            | sort -u \
            | awk 'system("[ -e /usr/local/lib/" $1 " ]") == 0 { next } { print "so:" $1 }' \
    )"; \
    apk add --no-cache $runDeps; \
    apk del --no-network .build-deps ; \
    rm -rf /tmp/* /var/cache/apk/*

RUN set -xe; \
    \
    echo "---> Installing Packages Dependencies"; \
    \
    apk update; \
    \
    apk add --update --no-cache \
        git \
        sudo \
        curl \
        wget \
        fcgi \
        make \
        bash \
        tini \
        supervisor \
        mysql-client \
        openssh-client \
        bash-completion \
    rm -rf /tmp/* /var/cache/apk/*

#####
## CONFIGURATIONS
#####

COPY $LOCAL_DOCKER_PHP_PATH/configs/conf.d/xdebug.ini $PHP_INI_SCAN_DIR/docker-php-ext-xdebug.ini
COPY $LOCAL_DOCKER_PHP_PATH/configs/conf.d/opcache.ini $PHP_INI_SCAN_DIR/docker-php-ext-opcache.ini

# /usr/local/etc/php/php.ini
COPY $LOCAL_DOCKER_PHP_PATH/configs/php-$APP_ENV.ini $PHP_INI_DIR/php.ini
# /usr/local/etc/php-fpm.conf
COPY $LOCAL_DOCKER_PHP_PATH/configs/fpm/php-fpm.conf $PHP_INI_DIR-fpm.conf
# /usr/local/etc/php-fpm.d/www.conf
COPY $LOCAL_DOCKER_PHP_PATH/configs/fpm/www.conf $PHP_FPM_POOL_DIR/www.conf

# SUPERVISOR CONF's
COPY $LOCAL_DOCKER_PHP_PATH/queue/supervisord.conf /etc/supervisor/supervisord.conf
COPY $LOCAL_DOCKER_PHP_PATH/queue/templates/* /etc/supervisor/conf.d/

# SCHEDULER/CRON
COPY $LOCAL_DOCKER_PHP_PATH/scheduler/artisan-schedule-run /var/spool/cron/crontabs/$USER_NAME
RUN chmod 0600 /var/spool/cron/crontabs/$USER_NAME

RUN set -xe \
    && echo "---> Forward request and error logs to docker log collector" \
    && mkdir -p $PHP_LOG_PATH $LOG_PATH/supervisor \
    \
    && touch $PHP_LOG_PATH/php-fpm.access.log \
    && touch $PHP_LOG_PATH/php-fpm.errors.log \
    && touch $PHP_LOG_PATH/php-fpm.slow.log \
    && touch $PHP_LOG_PATH/php.errors.log

RUN set -xe \
    && /usr/local/sbin/php-fpm --test \
    && PHP_ERROR="$( php -v 2>&1 1>/dev/null )" \
    && if [ -n "$PHP_ERROR" ]; then echo "$PHP_ERROR"; false; fi \
    && php -m; php -v; php --ini

RUN set -xe \
    && echo "---> Adding USER to IMAGE" \
    && addgroup -g ${USER_GID:-1000} $USER_NAME \
    && adduser -D -u ${USER_UID:-1000} -G $USER_NAME $USER_NAME \
    && echo "$USER_NAME ALL = (ALL) NOPASSWD: ALL" >> /etc/sudoers

RUN if [ ! -d "$REMOTE_SRC" ]; then \
        mkdir -p $REMOTE_SRC \
        && chown -R $USER_NAME:$USER_NAME $REMOTE_SRC /var/www \
    ;fi

RUN set -xe \
    && echo "---> Remove default files PHP-FPM" \
    # /usr/local/etc/php-fpm.conf.default
    && rm $PHP_INI_DIR-fpm.conf.default \
    # /usr/local/etc/php-fpm.d/www.conf.default
    && rm $PHP_FPM_POOL_DIR/www.conf.default \
    # /usr/local/etc/php-fpm.d/docker.conf
    && rm $PHP_FPM_POOL_DIR/docker.conf \
    # /usr/local/etc/php-fpm.d/zz-docker.conf
    && rm $PHP_FPM_POOL_DIR/zz-docker.conf \
    && rm -rf /tmp/pear ~/.pearrc

RUN set -xe \
    && echo "---> Changing Permissions" \
    && chown -R $USER_NAME:$USER_NAME /usr/local/etc /usr/local/var/run /home/${USER_NAME} $LOG_PATH

# ENTRYPOINT
COPY $LOCAL_DOCKER_PHP_PATH/docker-entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

#####
## APPLICATION
#####

# Application directory
WORKDIR $REMOTE_SRC

# Define the running USER
USER $USER_NAME

# Files APP
# Copy our application
COPY $LOCAL_APP_PATH $REMOTE_SRC

## Copy the downloaded dependencies from the {vendor} stage
COPY --from=vendor /app/vendor/ ./vendor/
COPY --from=vendor /app/composer.json ./composer.json
COPY --from=vendor /app/composer.lock ./composer.lock
COPY --from=vendor /app/bootstrap/ ./bootstrap/
COPY --from=vendor /app/config/ ./config/
COPY --from=vendor /app/routes/ ./routes/
COPY --from=vendor /app/storage/framework ./storage/framework

# Copy from {frontend} stage
COPY --from=frontend /app/public/ ./public/

# MYSQL
COPY $LOCAL_DOCKER_PATH/mysql/ssl/client-key.pem $REMOTE_SRC/database/docker/mysql/ssl/client-key.pem
COPY $LOCAL_DOCKER_PATH/mysql/ssl/client-cert.pem $REMOTE_SRC/database/docker/mysql/ssl/client-cert.pem
COPY $LOCAL_DOCKER_PATH/mysql/ssl/ca.pem $REMOTE_SRC/database/docker/mysql/ssl/ca.pem

# MONGODB
COPY $LOCAL_DOCKER_PATH/mongodb/ssl/ca.pem $REMOTE_SRC/database/docker/mongodb/ssl/ca.pem
COPY $LOCAL_DOCKER_PATH/mongodb/ssl/client.pem $REMOTE_SRC/database/docker/mongodb/ssl/client.pem

# Current Directory
RUN sudo chown -R ${USER_NAME}:${USER_NAME} $REMOTE_SRC

RUN set -xe \
    && echo "---> Installing Composer" \
    && COMPOSER_HOME="/home/${USER_NAME}/.composer/" \
    && curl -sS https://getcomposer.org/installer | sudo php -- --install-dir=/usr/local/bin --filename=composer \
    && composer global require --prefer-dist --no-progress --no-suggest --ansi "hirak/prestissimo:^0.3" \
    && composer global dumpautoload --optimize --ansi \
    && composer clear-cache

# Environment variables
# Default: /usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
ENV PATH="$PATH:/home/${USER_NAME}/.composer/vendor/bin"

RUN set -xe \
    && composer dump-autoload --optimize --classmap-authoritative --no-dev --ansi \
    && composer run-script post-root-package-install \
    && composer run-script post-autoload-dump

RUN set -xe && \
    sudo find $REMOTE_SRC -type f -exec chmod 664 {} \; && \
    sudo find $REMOTE_SRC -type d -exec chmod 775 {} \; && \
    sudo chgrp -R $USER_NAME storage bootstrap/cache && \
    sudo chmod -R ug+rwx storage bootstrap/cache && \
    sudo chown -R $USER_NAME:$USER_NAME $REMOTE_SRC && \
    php artisan view:clear && \
    php artisan route:clear && \
    php artisan config:clear && \
    php artisan storage:link && \
    php artisan clear-compiled

# Let INIT PID 1 handle all the zombies
ENTRYPOINT ["/sbin/tini", "--", "/entrypoint.sh"]
# As non daemon and single base image, it may be used as cli container
CMD ["/bin/bash"]

# Override stop signal to stop process gracefully
# https://github.com/php/php-src/blob/17baa87faddc2550def3ae7314236826bc1b1398/sapi/fpm/php-fpm.8.in#L163
STOPSIGNAL SIGQUIT

# set recommended PHP.ini settings
# see https://secure.php.net/manual/en/opcache.installation.php
RUN { \
        echo 'opcache.memory_consumption=1024'; \
        echo 'opcache.interned_strings_buffer=64'; \
        echo 'opcache.max_accelerated_files=65407'; \
        echo 'opcache.revalidate_freq=0'; \
        echo 'opcache.enable_cli=1'; \
    } > /usr/local/etc/php/conf.d/zz-opcache-recommended.ini; \
    \
    { \
        echo 'session.use_strict_mode = 1'; \
        echo 'session.use_cookies = 1'; \
        echo 'session.cookie_secure = 1'; \
        echo 'session.use_only_cookies = 1'; \
        echo 'session.cookie_httponly = 1'; \
        echo 'session.cookie_samesite = "Strict"'; \
    } > /usr/local/etc/php/conf.d/zz-session-strict.ini

# PHP-FPM
EXPOSE 9000 8080 8000 8800

# vim:set ft=dockerfile:
