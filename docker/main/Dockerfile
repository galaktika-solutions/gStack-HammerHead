FROM ubuntu:18.04

ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update

RUN apt-get install -y locales
RUN localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8
ENV LANG en_US.utf8

# postgres
ENV PG_MAJOR 10
RUN groupadd -r postgres --gid=999 && useradd -r -g postgres --uid=999 postgres
RUN apt-get install -y postgresql-common
RUN sed -ri 's/#(create_main_cluster) .*$/\1 = false/' /etc/postgresql-common/createcluster.conf
RUN apt-get install -y postgresql-$PG_MAJOR
ENV PGDATA /data/postgres
ENV PATH $PATH:/usr/lib/postgresql/$PG_MAJOR/bin

# python
RUN groupadd -r django --gid=8000 && useradd -r -g django --uid=8000 django
RUN apt-get install -y python3.6 python3-venv
RUN python3.6 -m venv /python
ENV PATH /python/bin:$PATH
ENV PYTHONUNBUFFERED 1
ENV DJANGO_SETTINGS_MODULE core.settings
ENV PYTHONPATH /django_project

RUN pip install --no-cache-dir django==2.0.5
RUN pip install --no-cache-dir psycopg2-binary==2.7.4

# nginx
RUN groupadd -r nginx --gid=4430 && useradd -r -g nginx --uid=4430 nginx
RUN apt-get install -y nginx
RUN ln -sf /dev/stdout /var/log/nginx/access.log

# uwsgi
RUN apt-get install -y build-essential
RUN apt-get install -y python3.6-dev
RUN pip install --no-cache-dir uwsgi==2.0.17

RUN pip install --no-cache-dir dumb-init==1.2.1

COPY docker/main/copy copy
COPY docker/utils.sh utils.sh
COPY --chown=django:django django_project django_project
COPY --chown=django:django static static

# Demo setup
COPY demo demo
COPY docker-compose.yml demo/docker-compose.yml

ENTRYPOINT ["/copy/entrypoint.sh"]
