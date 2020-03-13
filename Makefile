# Sets the default goal to be used if no targets were specified on the command line
.DEFAULT_GOAL := help

# You can set these variables from the command line
DOCKER_COMPOSE_EXEC = docker-compose
DOCKER_COMPOSE = $(DOCKER_COMPOSE_EXEC) -f docker-compose.yml
DOCKER_COMPOSE_QUEUE_SCHEDULER = $(DOCKER_COMPOSE_EXEC) -f docker-compose.queue+scheduler.yml

# Internal variables || Optional args
APP_ENV ?= production
LOCAL_DOCKER_PATH ?= ./docker

uname_OS := $(shell uname -s)
ROOT_PATH := $(shell dirname -- `pwd`)
ifeq ($(uname_OS),Darwin)
	ROOT_PATH := $(shell echo "/System/Volumes/Data/$(shell dirname -- `pwd`)" | sed 's#//*#/#g')
endif

# Internal functions
define message_failure
	"\033[1;31m ❌$(1)\033[0m"
endef

define message_success
	"\033[1;32m ✅$(1)\033[0m"
endef

define message_info
	"\033[0;34m❕$(1)\033[0m"
endef

help:
	@echo "Please use \`make <target>' where <target> is one of"
	@echo "  config-env                        Configura as variáveis .env do docker-compose + .env.xyz dos containers"
	@echo "  docker-update                     Atualiza os containers com novas versões de imagens"
	@echo "  docker-up-prod                    Executar em ambiente de PRODUÇÃO"
	@echo "  docker-up-dev                     Executar em ambiente de DESENVOLVIMENTO"
	@echo "  docker-prune                      Limpa os volumes e networks não utilizados por nenhum container"
	@echo "  docker-clean                      Executa \`docker-prune\` e remove imagens sem nenhuma tag(imagens de construção)"
	@echo "  docker-compose-build-webserver    Construir/criar a imagem do servidor"
	@echo "  docker-compose-build-site         Construir/criar a imagem do SITE"
	@echo "  docker-compose-build-admin        Construir/criar a imagem do painel ADMIN"

build:
	@$(MAKE) config-env
	@$(MAKE) docker-clean
	@$(MAKE) docker-compose-build-webserver
	@$(MAKE) docker-compose-build-site
	@echo $(call message_success, Run \`make build\` successfully executed)

config-env:
	@cp -n .env.example .env || true
	@cp -n ./php/app.env.example site.env || true
	@cp -n ./php/app.env.example admin.env || true
	@cp -n ./php/queue.env.example queue.env || true
	@cp -n ./php/scheduler.env.example scheduler.env || true
	@sed -i "/# ROOT_PATH=.*/c\ROOT_PATH=$(ROOT_PATH)" .env
	@sed -i "/LOCAL_DOCKER_PATH=.*/c\LOCAL_DOCKER_PATH=$(LOCAL_DOCKER_PATH)" .env
	@echo $(call message_success, Run \`make config-env\` successfully executed)

docker-update:
	@echo $(call message_info, Downloading the images 🗄)
	$(DOCKER_COMPOSE) pull || true

	@echo $(call message_info, Stopping containers gracefully ⏳)
	$(DOCKER_COMPOSE) stop --timeout 20

	@echo $(call message_info, Removing containers 🧹)
	$(DOCKER_COMPOSE) rm --stop --force -v

	@$(MAKE) --no-print-directory docker-prune

	@$(MAKE) --no-print-directory docker-up-prod

docker-up-prod:
	@echo $(call message_info, Docker UP PROD 🚀)
	$(DOCKER_COMPOSE) -f docker-compose.prod.yml up --force-recreate --detach

docker-up-dev:
	@echo $(call message_info, Docker UP DEV 💣)
	$(DOCKER_COMPOSE) -f docker-compose.dev.yml up

docker-up-queue-scheduler:
	@echo $(call message_info, Docker UP QUEUE + SCHEDULER 💣)
	$(DOCKER_COMPOSE_QUEUE_SCHEDULER) up

docker-prune:
	@echo $(call message_info, Docker prune 🧹)
	@docker volume prune --force && docker network prune --force

docker-clean:
	@echo $(call message_info, Prune images + Volumes + Network 🗑)
	@docker rmi -f $(docker images | grep "<none>" | awk "{print $3}") || true
	@$(MAKE) --no-print-directory docker-prune

docker-compose-build-webserver:
	@echo $(call message_info, Build WEBSERVER 🏗)
	@$(DOCKER_COMPOSE) build webserver

docker-compose-build-site:
	@echo $(call message_info, Build SITE 🏗)
	@$(DOCKER_COMPOSE) build site

docker-compose-build-admin:
	@echo $(call message_info, Build ADMIN 🏗)
	@$(DOCKER_COMPOSE) build admin

docker-compose-build-queue:
	@echo $(call message_info, Build QUEUE 🏗)
	@$(DOCKER_COMPOSE_QUEUE_SCHEDULER) build queue

docker-compose-build-scheduler:
	@echo $(call message_info, Build SCHEDULER 🏗)
	@$(DOCKER_COMPOSE_QUEUE_SCHEDULER) build scheduler
