# This repository is no longer maintained/updated, see new repository [https://github.com/allysonsilva/laravel-docker](https://github.com/allysonsilva/laravel-docker)

<p align="center">
    <a href="https://laravel.com/">
       <img src="https://cloud.githubusercontent.com/assets/807318/22915144/7659b1ce-f275-11e6-8821-21c89ceb30b5.png" alt="Laravel+Docker"/>
    </a>
</p>

> <h4 align="center">Use this repository to get started with developing your Laravel application in a Docker container.</h4>

This is a personal collection of Docker tools and images(**Nginx**, **PHP-FPM**, **MySQL**, **Redis**, **MongoDB**, **Queue**, **Scheduler**, and **RabbitMQ**) for applications in <a href="https://laravel.com/" target="_blank">Laravel</a>.

## Overview

1. [Project Structure/Tree](#project-structuretree)
2. [What's Inside/Softwares Included](#whats-insidesoftwares-included)
3. [Getting Started](#getting-started)
4. [Run the application](#run-the-application)

## Project Structure/Tree

```bash
tree -a  -I '.git|.DS_Store' --dirsfirst
```

```
.
├── mongodb
│   ├── ssl
│   │   ├── .gitignore
│   │   ├── ca.pem
│   │   ├── client.pem
│   │   └── server.pem
│   └── mongod.conf
├── mysql
│   ├── ssl
│   │   ├── .gitignore
│   │   ├── ca.pem
│   │   ├── client-cert.pem
│   │   ├── client-key.pem
│   │   ├── server-cert.pem
│   │   └── server-key.pem
│   ├── my.cnf
│   └── mysql.env
├── nginx
│   ├── certs
│   │   ├── .gitignore
│   │   ├── fullchain.pem
│   │   └── privkey.pem
│   ├── configs
│   │   ├── addon.d
│   │   │   └── 10-realip.conf
│   │   ├── nginx.d
│   │   │   ├── 10-headers.conf
│   │   │   ├── 20-gzip-compression.conf
│   │   │   ├── 20-open-file-descriptors.conf
│   │   │   ├── 30-buffers.conf
│   │   │   ├── 40-logs.conf
│   │   │   ├── 50-timeouts.conf
│   │   │   ├── 60-misc.conf
│   │   │   └── 70-proxy.conf
│   │   ├── servers
│   │   │   └── app.conf
│   │   ├── snippets
│   │   │   ├── cache-static.conf
│   │   │   ├── deny.conf
│   │   │   ├── php-fpm.conf
│   │   │   ├── ssl-certificates.conf
│   │   │   └── ssl.conf
│   │   ├── fastcgi.conf
│   │   ├── mime.types
│   │   └── nginx.conf
│   ├── Dockerfile
│   └── docker-entrypoint.sh
├── php
│   ├── configs
│   │   ├── conf.d
│   │   │   ├── opcache.ini
│   │   │   └── xdebug.ini
│   │   ├── fpm
│   │   │   ├── php-fpm.conf
│   │   │   └── www.conf
│   │   ├── php-local.ini
│   │   └── php-production.ini
│   ├── queue
│   │   ├── templates
│   │   │   ├── laravel-horizon.conf.tpl
│   │   │   └── laravel-worker.conf.tpl
│   │   └── supervisord.conf
│   ├── scheduler
│   │   └── artisan-schedule-run
│   ├── vscode
│   │   └── launch.json
│   ├── Dockerfile
│   ├── app.env.example
│   ├── docker-entrypoint.sh
│   ├── queue.env.example
│   └── scheduler.env.example
├── redis
│   └── redis.conf
├── .dockerignore
├── .editorconfig
├── .env.example
├── .gitignore
├── Makefile
├── README.md
├── docker-compose.override.yml
└── docker-compose.yml
```

## What's Inside/Softwares Included:

- _`PHP`_ 7.3.x
- [PHP-FPM](https://php-fpm.org/)
- [_`Nginx`_ 1.16.x](https://nginx.org/)
- [_`MySQL`_ 5.7](https://www.mysql.com/)
- [_`MongoDB`_ 4.2](https://www.mongodb.org/)
- [ _`Redis`_ 5.x](https://redis.io/)
- [ _`RabbitMQ`_ 3.8](https://www.rabbitmq.com/)

## Getting Started

### Organization

- **`docker` folder must match _current repository folder_**.
    - The folder name is configurable via the `LOCAL_DOCKER_PATH` variable of the `.env` environment file.
- **`src` folder should contain _Laravel application_.**
    - The folder name is configurable via the `LOCAL_APP_PATH` variable of the `.env` environment file.

```
.
├── docker
└── src
```

### Clone the project

```bash
$ git clone https://github.com/AllysonSilva/laravel-docker-lite docker && cd docker
```

- **Copy the `.env.example` file in the root of the project to `.env` and customize**.
- **Uncomment the `pwd` variable and fill it with result `echo $PWD`**.
- The `LOCAL_DOCKER_PATH` variable in the `.env` file *must be the folder name of the **docker** project*.
- The `LOCAL_APP_PATH` variable that is in the `.env` file *must be the folder name of the **Laravel** application project*.

**Customize Running in Development**

```bash
docker-compose -f docker-compose.yml -f docker-compose.override.yml up app webserver database redis queue scheduler
```

## Build Images

> To build the images it is necessary to configure the `.env` file with the information that will be used when the` docker-compose up` command is executed.

```bash
make config-docker-env \
    local_docker_path=./docker \
    local_app_path=./src \
    app_domain=domain.xyz \
    remote_src=/var/www/domain.xyz \
    app_image_name=app:1.0 \
    webserver_image_name=webserver:1.0
```

- `app_domain` must match the domain that will be used in the application. Used exclusively in the **webserver** container in [`server_name`](/nginx/configs/servers/app.conf#L24) *Nginx* settings.

- `remote_src` must match the same path in PHP (`app`) and Nginx (`webserver`) containers. Because the `webserver` container sends the `index.php` file path to *PHP-FPM*, so if the paths are different in both containers, a project execution error will occur.

###  Laravel/APP PHP-FPM

> - The construction/configuration of this image is used for applications in _Laravel_.
> - Used [multi-stage builds](https://docs.docker.com/develop/develop-images/multistage-build/) in your `Dockerfile`.
>     * In the first stage use the image of [Composer](https://hub.docker.com/_/composer) to manage the system dependencies (To speed up the download process [hirak/prestissimo](https://github.com/hirak/prestissimo) is used).
>     * In the second stage use the [Node.js](https://hub.docker.com/_/node) image to build the dependencies of the Front-end using the yarn manager.
>     * In the third and final stage, the results of the previous stages are used to copy the necessary files to the project image.

#### How to use

- `$APP_ENV`: Set the environment where the _Laravel_ application will be configured. This variable can be defined at the moment of image build through arguments(`--build-arg APP_ENV=production||local`), or if the image is already created, then it can be replaced by the parameter `--env "APP_ENV=production||local"` when running the container.
- `WORKDIR` corresponds to the variable `$REMOTE_SRC`.
- `php.ini`: Configured at the time of image build and is set according to the value passed to `$APP_ENV`. If the value of `$APP_ENV` is `local` then `php.ini` will match the files [`php-local.ini`](/php/configs/php-local.ini), if the value of `$APP_ENV` is `production` then the contents of `php.ini` will correspond to the file [`php-production.ini`](/php/configs/php-production.ini).
    * Can be overridden by volume pointing to the `php.ini` file path: `/usr/local/etc/php/php.ini`.
- `php-fpm.conf`: GLOBAL PHP-FPM configuration found `/usr/local/etc/php-fpm.conf`.
- `www.conf`: Specific configuration for pool `[www]` found `/usr/local/etc/php-fpm.d/www.conf`.

#### Configure/Build

Use the following command to build the image:

```bash
make build-app \
    app_env=production||local \
    remote_src=/var/www/domain.xyz \
    local_app_path=./src \
    local_docker_path=./docker \
    app_image_name=app:1.0
```

If you want to customize the image construction according to your arguments, use the `docker build` command directly:

```bash
docker build -t app:1.0 -f ./php/Dockerfile \
    --build-arg USER_NAME=app \
    --build-arg USER_UID=$UID \
    --build-arg USER_GID=$(id -g) \
    --build-arg APP_ENV=production||local \
    --build-arg REMOTE_SRC=/var/www/domain.xyz \
    --build-arg LOCAL_APP_PATH=./app \
    --build-arg LOCAL_DOCKER_PATH=./docker \
./../
```

### Nginx Webserver

> Image will be used as _REVERSE PROXY_.

Use the following command to build the image:

```bash
make build-webserver \
    app_domain=domain.xyz \
    remote_src=/var/www/domain.xyz \
    webserver_image_name=webserver:1.0
```

- `app_domain` is used for setting `server_name` in [`app.conf`](/nginx/configs/servers/app.conf#L24) file.
- `remote_src` must have the same value used in the `make build-app` command. So there is no conflict in the communication of the services of the reverse proxy (NGINX) with the service CGI (PHP-FPM).

- Use the [Let's Encrypt](https://letsencrypt.org/) to generate SSL certificates and perform the NGINX SSL configuration to use the **HTTPS** protocol.
    * Folder `nginx/certs/` should contain the files created by _Let's Encrypt_. It should contain the files: `cert.pem`, `chain.pem`, `dhparam4096.pem`, `fullchain.pem`, `privkey.pem`.

## Run the application

> Copy the files from the `php` folder to the docker root folder(`./docker/php/app.env.example` move to `./docker/app.env`): `app.env.example`, `queue.env.example`, `scheduler.env.example`, and set to the values that will be used in the environment.
> *Remove the suffix `.env.example`, leaving only `.env`*.

_`APP_KEY`: If the application key is not set, your user sessions and other encrypted data will not be secure!_

### There are three ways to execute the application container:

#### [*PHP-FPM(default)*](/php/docker-entrypoint.sh#L167)

> Runs the container with the PHP-FPM processes running.

**Set the `CONTAINER_ROLE` environment variable when running the PHP container so that its value is `app`**.

```bash
exec /usr/local/sbin/php-fpm -y /usr/local/etc/php-fpm.conf --nodaemonize --force-stderr
```

#### [_Queue_](/php/docker-entrypoint.sh#L178)

> Container/service responsible for managing _Queue_ in the application.

**Set the `CONTAINER_ROLE` environment variable when running the PHP container so that its value is `queue`**.

Container with **PID 1** executed by **supervisor** to manage processes. Can have two configurations:

- Many processes running in the Laravel [`artisan queue:work`](/php/queue/templates/laravel-worker.conf.tpl#L3) for queue management.
- Used for debugging and development, the _Horizon_ is a robust and simplistic queue management panel. A single process in a _supervisor_ configuration by running the [`artisan horizon`](/php/queue/templates/laravel-horizon.conf.tpl#L3) command.

```bash
exec /usr/bin/supervisord --nodaemon --configuration /etc/supervisor/supervisord.conf
```

**Mandatory environment variables**

- **`LARAVEL_QUEUE_MANAGER`**: This environment variable defines the container context, and can have the following values:
    * **worker**:  Configure the _supervisor_ to run many processes in the Laravel command `artisan queue:work`.
    * **horizon**: Configure the _supervisor_ to run a single Horizon process `artisan horizon`.

#### [_Scheduler_](/php/docker-entrypoint.sh#L231)

> Container/service responsible for managing _Scheduler_ in the application.

**Set the `CONTAINER_ROLE` environment variable when running the PHP container so that its value is `scheduler`**.

- Container with **PID 1** executed by **cron**.
- Environment variables `APP_KEY` and `APP_ENV` are required when executing the container.
- Environment variables available for PHP processes thanks to the `printenv > /etc/environment` script in container entrypoint.
- Container run as `root` as a _cron_ service request.

_Running a single scheduling command_

```bash
* * * * * {{USER}} /usr/local/bin/php {{REMOTE_SRC}}artisan schedule:run --no-ansi >> /usr/local/var/log/php/cron-laravel-scheduler.log 2>&1
```

```bash
exec /usr/sbin/crond -l 2 -f -L /var/log/cron.log
```

### `docker-compose up`

**Some points to consider:**

- _MongoDB_ Container Uses [_SSL/TLS_](/mongodb/mongod.conf/#L21) configuration for database connections. Before running the container you need to [create these SSL files]([https://medium.com/@rajanmaharjan/secure-your-mongodb-connections-ssl-tls-92e2addb3c89](https://medium.com/@rajanmaharjan/secure-your-mongodb-connections-ssl-tls-92e2addb3c89)), or simply remove this setting.
- _MySQL_ is also [configured to accept only SSL connections](/mysql/my.cnf#L7). You can generate SSL keys through this link [https://dev.mysql.com/doc/refman/5.7/en/creating-ssl-files-using-openssl.html](https://dev.mysql.com/doc/refman/5.7/en/creating-ssl-files-using-openssl.html).
- The _Redis_ container uses a [password(`requirepass`)](/redis/redis.conf#L507) to perform a database connection.
- The _Nginx_ container uses SSL certificates to make HTTPS connections only.

**Only port 80 and 443 are tight to the internet for security reasons.**

**Change the passwords present in the files: `mysql.env`, `redis.conf` and the `docker-compose.yml` variables which are: `RABBITMQ_USERNAME`, `RABBITMQ_PASSWORD`, `MONGO_INITDB_ROOT_USERNAME` and `MONGO_INITDB_ROOT_PASSWORD`**.

This project use the following ports:

| Server     | Port |
|------------|------|
| Nginx      | 80   |
| Nginx      | 443  |

Set the `WEBSERVER_PORT_HTTP` environment variable for HTTP connections and `WEBSERVER_PORT_HTTPS` for HTTPS connections.

## Helpers commands

#### To access the _MySQL_ via Terminal/Console:

```bash
mysql -h 127.0.0.1 -P 30062 -uapp -p'ExBkhs^NGuA6r_Fu' \
    --ssl-ca=mysql/ssl/ca.pem \
    --ssl-cert=mysql/ssl/client-cert.pem \
    --ssl-key=mysql/ssl/client-key.pem
```

#### To access the _Redis_  container database:

```bash
docker exec -it redis redis-cli -n 0 -p 6379 -a '.7HVhf(Yh+9CF-58' --no-auth-warning
```

#### To access the _MongoDB_  via Terminal/Console:

```bash
mongo --ssl \
      --sslCAFile ./mongodb/ssl/ca.pem --sslPEMKeyFile ./mongodb/ssl/client.pem \
      --host 127.0.0.1 --port 29019 -u 'root' -p 'jyA7LF_7dX7.pmH' --authenticationDatabase admin
```

#### Install PHP modules

```bash
docker exec -it app /bin/bash

# After
$ /usr/local/bin/docker-php-ext-configure xdebug
$ /usr/local/bin/docker-php-ext-install xdebug
```

#### Installing package with composer

```bash
docker run --rm -v $(pwd):/app composer require laravel/horizon
```

#### Updating PHP dependencies with composer

```bash
docker run --rm -v $(pwd):/app composer update
```

#### Testing PHP application with PHPUnit

```bash
docker-compose exec -T app ./vendor/bin/phpunit --colors=always --configuration ./app
```

#### Fixing standard code with [PSR2](https://www.php-fig.org/psr/psr-2/)

```bash
docker-compose exec -T app ./vendor/bin/phpcbf -v --standard=PSR2 ./app
```

#### Analyzing source code with [PHP Mess Detector](https://phpmd.org/)

```bash
docker-compose exec -T app ./vendor/bin/phpmd ./app text cleancode,codesize,controversial,design,naming,unusedcode
```

## Contributing

If you find an issue, or have a special wish not yet fulfilled, please [open an issue on GitHub](https://github.com/AllysonSilva/laravel-docker-lite/issues) providing as many details as you can (the more you are specific about your problem, the easier it is for us to fix it).

Pull requests are welcome, too 😁! Also, it would be nice if you could stick to the [best practices for writing Dockerfiles](https://docs.docker.com/articles/dockerfile_best-practices/).

##  License

[MIT License](https://github.com/AllysonSilva/laravel-docker-lite/blob/master/LICENSE)
