# Makefile for Docker APP

# Optional args
app_env ?= production
local_app_path ?= ./src
app_domain ?= domain.xyz
app_image_name ?= app:latest
local_docker_path ?= ./docker
remote_src ?= /var/www/domain.xyz
webserver_image_name ?= webserver:latest

build:
	config-docker-env
	make build-app
	make build-webserver

config-docker-env:
	cp .env.example .env
	cp ./php/app.env.example app.env
	cp ./php/queue.env.example queue.env
	cp ./php/scheduler.env.example scheduler.env
	sed -i "/LOCAL_DOCKER_PATH=.*/c\LOCAL_DOCKER_PATH=${local_docker_path}" .env
	sed -i "/LOCAL_APP_PATH=.*/c\LOCAL_APP_PATH=${local_app_path}" .env
	sed -i "/APP_DOMAIN=.*/c\APP_DOMAIN=${app_domain}" .env
	sed -i "/REMOTE_SRC=.*/c\REMOTE_SRC=${remote_src}" .env
	sed -i "/APP_IMAGE=.*/c\APP_IMAGE=${app_image_name}" .env
	sed -i "/WEBSERVER_IMAGE=.*/c\WEBSERVER_IMAGE=${webserver_image_name}" .env
	sed -i "/# PWD=.*/c\PWD=\"$(shell pwd)\"" .env

# $> make build-webserver webserver_image_name=webserver:1.0 app_domain=mydomain.com remote_src=/var/www/app
build-webserver:
	@echo "Building an image WEBSERVER-NGINX"
	docker build -t ${webserver_image_name} -f ./nginx/Dockerfile \
		--build-arg APP_DOMAIN=${app_domain} \
		--build-arg REMOTE_SRC=${remote_src} \
	./nginx

# $> make run-webserver app_domain=mydomain.com remote_src=/var/www/app
run-webserver:
	@echo "Running container WEBSERVER"
	docker run \
		--rm \
		-p 80:80 \
		-p 443:443 \
	-v "$(shell pwd)/../${local_app_path}:${remote_src}" \
	-v "$(shell pwd)/nginx/docker-entrypoint.sh:/entrypoint.sh:ro" \
			--env "APP_DOMAIN=${app_domain}" \
			--env "REMOTE_SRC=${remote_src}" \
		--workdir ${remote_src} \
		--name=webserver \
		--hostname=webserver \
		-t ${webserver_image_name}

# $> make build-app app_env=production||local remote_src=/var/www/app local_app_path=./src local_docker_path=./docker
build-app:
	@echo "Building an image APP-PHP"
	docker build -t ${app_image_name} -f ./php/Dockerfile \
		--build-arg APP_ENV=${app_env} \
		--build-arg REMOTE_SRC=${remote_src} \
		--build-arg LOCAL_APP_PATH=${local_app_path} \
		--build-arg LOCAL_DOCKER_PATH=${local_docker_path} \
	./../

# $> make run-app app_domain=mydomain.com remote_src=/var/www/app
run-app:
	@echo "Running container APP"
	docker run \
		--rm \
	-v "$(shell pwd)/../${local_app_path}:${remote_src}" \
	-v "$(shell pwd)/php/docker-entrypoint.sh:/entrypoint.sh:ro" \
	-v "$(shell pwd)/php/configs/php-local.ini:/usr/local/etc/php/php.ini:ro" \
			--env "REMOTE_SRC=${remote_src}" \
			--env="XDEBUG_ENABLED=false" \
			--env="CONTAINER_ROLE=app" \
			--env="LARAVEL_QUEUE_MANAGER=worker" \
			--env "APP_ENV=${app_env}" \
			--env "APP_KEY=SomeRandomString" \
			--env "APP_DEBUG=true" \
		--workdir "${remote_src}" \
		--publish=8088:8080 \
		--publish=7000:8000 \
		--name=app-php \
		--hostname=app-php \
		-t ${app_image_name}

docker-clean:
	@docker rmi -f $(shell docker images | grep "<none>" | awk "{print \$$3}")

machine-ip:
	sed -i "/MACHINE_IP=.*/c\MACHINE_IP=$(shell ipconfig getifaddr en0)" .env
