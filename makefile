SHELL=/bin/bash

readvar = $(shell cat .env | sed -nr 's/^$(1)=(.*)$$/\1/ p')

timestamp := $(shell date -u +"%Y-%m-%d-%H-%M")
usr := $(shell id -u):$(shell id -g)
IMAGE_NAME_PREFIX := $(call readvar,IMAGE_NAME_PREFIX)

# self documenting makefile
.DEFAULT_GOAL := help
## Print (this) short summary
help: bold = $(shell tput bold; tput setaf 3)
help: reset = $(shell tput sgr0)
help:
	@echo
	@sed -nr \
		-e '/^## /{s/^## /    /;h;:a;n;/^## /{s/^## /    /;H;ba};' \
		-e '/^[[:alnum:]_\-]+:/ {s/(.+):.*$$/$(bold)\1$(reset):/;G;p};' \
		-e 's/^[[:alnum:]_\-]+://;x}' ${MAKEFILE_LIST}
	@echo

###########
# TARGETS #
###########

## Run the Django container with the current user, in the project directory
run-as-me:
	docker-compose run --rm -u "$(usr)" -v "$(CURDIR):/gstack" -w "/gstack" django bash

## Build production docker images
build:
	docker-compose down
	mkdir -p static
	chmod 777 static
	IMAGE_TAG=latest COMPOSE_FILE="docker-compose.yml:docker-compose.dev.yml" docker-compose build
	docker-compose run -v "$(CURDIR)/static:/static" --rm django django-admin collectstatic --no-input -c
	echo "*" > static/.gitignore && echo "!.gitignore" >> static/.gitignore
	chmod 775 static
	IMAGE_TAG=latest COMPOSE_FILE="docker-compose.yml:docker-compose.dev.yml" docker-compose build
	docker-compose down

## Build the Docker image, tag it and push it to the registry
push: img = $(IMAGE_NAME_PREFIX)-main
push: build
	docker tag $(img):latest $(img):$(timestamp)
	docker push "$(img):$(timestamp)"
	docker push "$(img):latest"

.PHONY: backup
backup:
	docker-compose run --rm -v "$(CURDIR)/backup:/backup" django backup

restore:
	docker-compose run --rm -v "$(CURDIR)/backup:/backup" django restore
