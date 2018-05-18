#!/bin/bash
set -e

. /copy/utils.sh

if [ "$1" = 'postgres' ]; then
  check_file "postgres:postgres:600" /run/secrets/*

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

  db_password="$(read_secret DB_PASSWORD)"
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
  check_file "django:django:600" /run/secrets/*

  wait_for_db
  if [ "$DEV_MODE" = 'true' ]; then
    exec dumb-init --rewrite 15:2 chroot --userspec django:django / django-admin runserver 0.0.0.0:8000
  fi
  exec dumb-init --rewrite 15:2 chroot --userspec django:django / uwsgi --ini /copy/uwsgi.conf
fi

if [ "$1" = 'django-admin' ]; then
  wait_for_db
  shift;
  exec chroot --userspec django:django / django-admin "$@"
fi

if [ "$1" = 'nginx' ]; then
  check_file "nginx:nginx:600" /run/secrets/*

  if [ "$DEV_MODE" = 'true' ]; then
    exec nginx -c /copy/nginx.dev.conf
  fi
  exec nginx -c /copy/nginx.conf
fi

exec "$@"
