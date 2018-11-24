SHELL=/bin/bash

timestamp := $(shell date +"%Y-%m-%d-%H-%M")
devcompose := COMPOSE_FILE=docker-compose.yml:docker-compose.dev.yml

clean:
	docker-compose run --rm postgres find . -type d -name __pycache__ -exec rm -rf {} +

createsecret:
	docker-compose run --rm postgres createsecret_ui

readsecret:
	docker-compose run --rm postgres readsecret_ui

# collectstatic:
# 	$(devcompose) docker-compose run --rm django collectstatic

build:
	$(devcompose) docker-compose down
	$(devcompose) docker-compose build
	# $(devcompose) docker-compose run --rm django collectstatic
	# $(devcompose) docker-compose run --rm -e 'VERSION=$(timestamp)' django docs
	# $(devcompose) docker-compose build
	# $(devcompose) docker-compose down

# shell_plus:
# 	docker-compose run --rm django with_django django-admin shell_plus

bash:
	docker-compose run --rm django with_django bash

# test:
# 	docker-compose run --rm django test
#
# test_keepdb:
# 	docker-compose run --rm django test keepdb
#
# coverage:
# 	docker-compose run --rm django coverage
#
# .PHONY: docs
# docs:
# 	docker-compose run --rm django docs
#
# migrate:
# 	docker-compose run --rm django with_django django-admin migrate
#
# makemigrations:
# 	docker-compose run --rm django with_django django-admin makemigrations

.PHONY: backup
backup:
	docker-compose run --rm backup backup

restore:
	docker-compose down
	docker-compose run --rm backup restore
