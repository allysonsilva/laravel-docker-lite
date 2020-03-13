#!/usr/bin/env bash

set -e

if [ "$1" = '/bin/bash' ]; then

    # Default settings for PHP-FPM
    configure_php_fpm() {
        echo "Starting PHP-FPM configurations"
        echo

        sed -i "/user = .*/c\user = ${USER_NAME}" ${PHP_FPM_POOL_DIR}/www.conf
        sed -i "/^group = .*/c\group = ${USER_NAME}" ${PHP_FPM_POOL_DIR}/www.conf
        sed -i "/listen.owner = .*/c\listen.owner = ${USER_NAME}" ${PHP_FPM_POOL_DIR}/www.conf
        sed -i "/listen.group = .*/c\listen.group = ${USER_NAME}" ${PHP_FPM_POOL_DIR}/www.conf
        sed -i "/listen = .*/c\listen = 9000" ${PHP_FPM_POOL_DIR}/www.conf
        sed -i "/listen.allowed_clients = .*/c\;listen.allowed_clients =" ${PHP_FPM_POOL_DIR}/www.conf
        sed -i "/pid = .*/c\;pid = run/php-fpm.pid" ${PHP_INI_DIR}-fpm.conf
        sed -i "/daemonize = .*/c\daemonize = no" ${PHP_INI_DIR}-fpm.conf

        # sed -i "/access.log = .*/c\access.log = /proc/self/fd/2" ${PHP_FPM_POOL_DIR}/www.conf
        # sed -i "/slowlog = .*/c\slowlog = /proc/self/fd/2" ${PHP_FPM_POOL_DIR}/www.conf
        sed -i "/error_log = .*/c\error_log = /proc/self/fd/2" ${PHP_INI_DIR}-fpm.conf

        sed -i "/;clear_env = .*/c\clear_env = no" ${PHP_FPM_POOL_DIR}/www.conf
        sed -i "/;catch_workers_output = .*/c\catch_workers_output = yes" ${PHP_FPM_POOL_DIR}/www.conf
    }

    handle_composer_dependencies() {
        if [ ! -d "vendor" ]; then
            echo "Composer vendor folder was not installed. Running $> composer install --prefer-dist --no-interaction --optimize-autoloader --no-dev"
            echo

            composer install --prefer-dist --no-interaction --optimize-autoloader --no-dev

            echo "composer run-script post-root-package-install"
            echo
            composer run-script post-root-package-install

            echo "composer run-script post-autoload-dump"
            echo
            composer run-script post-autoload-dump
        fi
    }

    if [ -z "$APP_ENV" ]; then
        echo 'A $APP_ENV environment is required to run this container'
        exit 1
    fi

    # If the application key is not set, your user sessions and other encrypted data will not be secure!
    if [ -z "$APP_KEY" ]; then
        echo 'A $APP_KEY environment is required to run this container'
        exit 1
    fi

    if [ "$APP_ENV" = "production" ]
    then

        # ps -ylC php-fpm --sort:rss
        sed -i \
            -e "/pm = .*/c\pm = dynamic" \
            -e "/pm.max_children = .*/c\pm.max_children = 40" \
            -e "/pm.start_servers = .*/c\pm.start_servers = 15" \
            -e "/pm.min_spare_servers = .*/c\pm.min_spare_servers = 10" \
            -e "/pm.max_spare_servers = .*/c\pm.max_spare_servers = 25" \
            -e "/pm.max_requests = .*/c\pm.max_requests = 1024" \
            -e "/rlimit_files = .*/c\rlimit_files = 32768" \
            -e "/rlimit_core = .*/c\rlimit_core = unlimited" \
        ${PHP_FPM_POOL_DIR}/www.conf

        # Remove Xdebug in production
        if [ -f ${PHP_INI_SCAN_DIR}/xdebug.ini ]; then
            rm ${PHP_INI_SCAN_DIR}/xdebug.ini
        fi

        if [ -f ${PHP_INI_SCAN_DIR}/docker-php-ext-xdebug.ini ]; then
            rm ${PHP_INI_SCAN_DIR}/docker-php-ext-xdebug.ini
        fi

        echo "Laravel - Cache Optimization [Production]"
        echo

        if [ -d "vendor" ]; then
            # $> {config:cache} && {route:cache}
            # @see https://github.com/laravel/framework/blob/7.x/src/Illuminate/Foundation/Console/OptimizeCommand.php#L28
            php artisan optimize
            php artisan view:cache
        fi

    else

        sed -i \
            -e "/pm = .*/c\pm = dynamic" \
            -e "/pm.max_children = .*/c\pm.max_children = 12" \
            -e "/pm.start_servers = .*/c\pm.start_servers = 6" \
            -e "/pm.min_spare_servers = .*/c\pm.min_spare_servers = 4" \
            -e "/pm.max_spare_servers = .*/c\pm.max_spare_servers = 8" \
            -e "/pm.max_requests = .*/c\pm.max_requests = 500" \
            -e "/rlimit_files = .*/c\;rlimit_files = " \
            -e "/rlimit_core = .*/c\;rlimit_core = " \
        ${PHP_FPM_POOL_DIR}/www.conf

        # Remove Opcache in development
        if [ -f ${PHP_INI_SCAN_DIR}/opcache.ini ]; then
            rm ${PHP_INI_SCAN_DIR}/opcache.ini
        fi

        if [ -f ${PHP_INI_SCAN_DIR}/docker-php-ext-opcache.ini ]; then
            rm ${PHP_INI_SCAN_DIR}/docker-php-ext-opcache.ini
        fi

        if [[ ${FORCE_STORAGE_LINK:-false} == true ]]; then
            echo
            echo "Laravel - artisan storage:link"
            echo

            rm -rf ${REMOTE_SRC}/public/storage
            php artisan storage:link
        fi

        # $> {view:clear} && {cache:clear} && {route:clear} && {config:clear} && {clear-compiled}
        # @see https://github.com/laravel/framework/blob/7.x/src/Illuminate/Foundation/Console/OptimizeClearCommand.php#L28
        if [[ -d "vendor" && ${FORCE_CLEAR:-false} == true ]]; then
            echo
            echo "Laravel - Clear All [Development]"
            echo

            php artisan view:clear
            php artisan route:clear
            php artisan config:clear
            php artisan clear-compiled
        fi

    fi

    if [[ -n "$XDEBUG_ENABLED" && $XDEBUG_ENABLED == true ]]; then
        echo
        { \
            # echo '[xdebug]'; \
            # echo 'zend_extension=xdebug.so'; \
            echo; \
            echo 'xdebug.remote_enable=1'; \
            echo 'xdebug.default_enable=1'; \
            echo 'xdebug.remote_autostart=0'; \
            echo 'xdebug.remote_connect_back=0'; \
            echo 'xdebug.remote_port=9001'; \
            echo; \
            echo 'xdebug.scream=0'; \
            echo 'xdebug.cli_color=1'; \
            echo 'xdebug.show_local_vars=1'; \
            echo 'xdebug.show_error_trace=1'; \
            echo 'xdebug.show_exception_trace=1'; \
            echo 'xdebug.collect_return=1'; \
            echo 'xdebug.idekey="IDEKEYXDEBUG"'; \
            echo; \
            echo 'xdebug.collect_assignments=1'; \
            echo 'xdebug.profiler_enable_trigger=1'; \
            echo 'xdebug.profiler_enable_trigger_value="XDEBUG_PROFILE"'; \
            echo; \
            echo "xdebug.remote_host=${XDEBUG_REMOTE_HOST:-`/sbin/ip route|awk '/default/ { print $3 }'`}"
        } | tee -a ${PHP_INI_SCAN_DIR}/zz-xdebug.ini > /dev/null
    else
        rm -f ${PHP_INI_SCAN_DIR}/docker-php-ext-xdebug.ini 2> /dev/null
    fi

    echo
    handle_composer_dependencies
    echo

    if [[ $CONTAINER_ROLE == "app" ]]
    then

        echo "Running the APP/PHP-FPM Service..."

        echo
        configure_php_fpm
        echo

        php --ini
        php -v

        echo

        exec /usr/local/sbin/php-fpm -y /usr/local/etc/php-fpm.conf --nodaemonize --force-stderr

    elif [[ $CONTAINER_ROLE == "queue" ]]
    then

        if [[ $LARAVEL_QUEUE_MANAGER == "horizon" ]]; then

            echo "Running the [HORIZON] Service..."
            echo

            sudo sed -i \
                    -e "s|{{USER_NAME}}|$USER_NAME|g" \
                    -e "s|{{REMOTE_SRC}}|${REMOTE_SRC}|g" /etc/supervisor/conf.d/laravel-horizon.conf.tpl \
            \
            && sudo mv /etc/supervisor/conf.d/laravel-horizon.conf.tpl /etc/supervisor/conf.d/laravel-horizon.conf

        elif [[ $LARAVEL_QUEUE_MANAGER == "worker" ]]; then

            echo "Running the [WORKER] Service..."
            echo

            sudo sed -i \
                    -e "s|{{USER_NAME}}|$USER_NAME|g" \
                    -e "s|{{REMOTE_SRC}}|${REMOTE_SRC}|g" \
                    -e "s|{{REDIS_QUEUE}}|${REDIS_QUEUE:-default}|g" \
                    -e "s|{{QUEUE_CONNECTION}}|${QUEUE_CONNECTION:-redis}|g" \
                    -e "s|{{QUEUE_TIMEOUT}}|${QUEUE_TIMEOUT}|g" \
                    -e "s|{{QUEUE_MEMORY}}|${QUEUE_MEMORY}|g" \
                    -e "s|{{QUEUE_TRIES}}|${QUEUE_TRIES}|g" \
                    -e "s|{{QUEUE_DELAY}}|${QUEUE_DELAY}|g" \
                    -e "s|{{QUEUE_SLEEP}}|${QUEUE_SLEEP}|g" /etc/supervisor/conf.d/laravel-worker.conf.tpl \
            \
            && sudo mv /etc/supervisor/conf.d/laravel-worker.conf.tpl /etc/supervisor/conf.d/laravel-worker.conf \
            && ln -sf /dev/stdout ${REMOTE_SRC}/storage/logs/worker-queue.out.log

        else
            echo "Queue type could not be found. configure --env=\"\$CONTAINER_ROLE=worker or horizon\" in command $> docker run"
            exit 1
        fi

        echo "Starting [SUPERVISOR]"
        echo

        exec /usr/bin/supervisord --nodaemon --configuration /etc/supervisor/supervisord.conf

        # # Reload the daemon's configuration files
        # supervisorctl -c /etc/supervisor/supervisord.conf reread
        # # Reload config and add/remove as necessary
        # supervisorctl -c /etc/supervisor/supervisord.conf update
        # # Start all processes of the group "laravel-worker"
        # supervisorctl -c /etc/supervisor/supervisord.conf start laravel-worker:*

        # # After a change in php sources you have to restart the queue, since queue:work does run as daemon
        # php artisan queue:restart

    elif [[ $CONTAINER_ROLE == "scheduler" ]]
    then

        echo "Starting [CRON] Service..."
        echo

        # It must be used so that CRON can use the values of the environment variables
        # The CRON service can not retrieve all environment variables, especially those defined in the docker-compose.yml file, when the line below is not set
        printenv > /etc/environment

        sudo sed -i -e "s|{{REMOTE_SRC}}|${REMOTE_SRC}|g" /etc/crontabs/${USER_NAME}

        echo "Running the SCHEDULER"
        echo

        exec /usr/sbin/crond -l 2 -f -L /var/log/cron.log

    else

        echo "Could not match the container role \"$CONTAINER_ROLE\""
        exit 1

    fi

fi

exec "$@"
