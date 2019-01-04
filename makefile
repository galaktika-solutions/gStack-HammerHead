SHELL=/bin/bash

timestamp := $(shell date +"%Y-%m-%d-%H-%M")
dcrun := docker-compose -f docker-compose.yml -f docker-compose.dev.yml run --rm -e ENV=DEV
dc := docker-compose -f docker-compose.yml -f docker-compose.dev.yml


clean:
	$(dcrun) postgres find . -type d -name __pycache__ -exec rm -rf {} +

createsecret:
	docker-compose run --rm postgres createsecret_ui

readsecret:
	docker-compose run --rm postgres readsecret_ui

collectstatic:
	$(dcrun) django collectstatic

.PHONY: docs
docs:
	$(dcrun) -e 'VERSION=$(timestamp)' django \
	  with_django bash -c "cd docs; make html"

.PHONY: test
test:
	$(dcrun) django with_django bash -c \
	"coverage run django_project/manage.py test -v 2 && \
	 coverage report && coverage html"

imagebuild:
	$(dc) build

build:
	$(dc) down
	$(dc) build
	make collectstatic
	make test
	make docs &&	rm -rf static/docs && cp -r docs/build/html static/docs
	$(dc) build
	$(dc) down

bash:
	docker-compose run --rm django with_django bash

migrate:
	docker-compose run --rm django with_django django-admin migrate

makemigrations:
	$(dcrun) django with_django django-admin makemigrations

.PHONY: backup
backup:
	docker-compose run --rm backup backup

restore:
	docker-compose down
	docker-compose run --rm backup restore
