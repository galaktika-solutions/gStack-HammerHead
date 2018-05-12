#!/bin/bash
set -e

. /copy/utils.sh

if [ "$1" = 'postgres' ]; then
  mkdir -p "$PGDATA"
  chown -R "postgres:postgres" "$PGDATA"
  chmod 700 "$PGDATA"

  if [ ! -s "$PGDATA/PG_VERSION" ]; then
    chroot --userspec=postgres:postgres / initdb
  fi

  proc_file -c postgres:postgres:400 /copy/postgresql.conf "$PGDATA/postgresql.conf"
  proc_file -c postgres:postgres:400 /copy/pg_hba.conf "$PGDATA/pg_hba.conf"

  chroot --userspec=postgres:postgres / pg_ctl -D "$PGDATA" \
    -o "-c listen_addresses='127.0.0.1'" \
    -o "-c log_statement=none" \
    -o "-c log_connections=off" \
    -o "-c log_disconnections=off" \
    -w start > /dev/null

  if ! (runsql '\du' | cut -d \| -f 1 | grep -qw django); then
    runsql "CREATE USER django"
  fi

  db_password="$(readvar DB_PASSWORD)"
  runsql "ALTER USER django WITH PASSWORD \$pass\$$db_password\$pass\$;"

  if ! (runsql '\l' | cut -d \| -f 1 | grep -qw django); then
    runsql "CREATE DATABASE django OWNER django"
  fi

  runsql "REVOKE CREATE ON SCHEMA public FROM PUBLIC" django
  runsql "GRANT ALL ON SCHEMA public TO django" django

  chroot --userspec=postgres:postgres / pg_ctl -D "$PGDATA" -m fast -w stop > /dev/null

  exec chroot --userspec=postgres:postgres / postgres
fi

if [ "$1" = 'django' ]; then
  DB_PASSWORD="$(readvar DB_PASSWORD)"
  PGPASSWORD="$DB_PASSWORD" wait_for_db
  # DJANGO_SECRET_KEY="$(readvar DJANGO_SECRET_KEY)"
  # export DJANGO_SECRET_KEY
  #
  # if [ "$DJANGO_AUTOMIGRATE" = 'true' ]; then
  #   su-exec django django-admin migrate
  # fi
  #
  # # create django superuser if needed
  # DJANGO_SUPERUSER_EMAIL="$(read_var DJANGO_SUPERUSER_EMAIL)"
  # if [ -n "$DJANGO_SUPERUSER_EMAIL" ]; then
  #   DJANGO_SUPERUSER_PASSWORD="$(read_var DJANGO_SUPERUSER_PASSWORD)"
  #   su-exec django python3 /docker/create_superuser.py \
  #     "$DJANGO_SUPERUSER_EMAIL" \
  #     "$DJANGO_SUPERUSER_PASSWORD"
  # fi
  #
  # if [ "$DEV" = 'true' ]; then
  #   exec su-exec django django-admin runserver 0.0.0.0:8000
  # fi
  # exec su-exec django uwsgi --ini /docker/uwsgi.conf
  export DB_PASSWORD
  exec chroot --userspec django:django / django-admin runserver 0.0.0.0:8000
fi

exec "$@"
