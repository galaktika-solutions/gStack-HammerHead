#!/bin/bash
set -e

. /src/docker/main/utils.sh

################################################################################
if [ "$1" = 'createsecret' ] || [ "$1" = 'readsecret' ]; then
  . /src/docker/main/secrets.sh
  "wrapped_$1"
  exit 0
fi
################################################################################
if [ "$1" = 'postgres' ]; then
  mkdir -p "$PGDATA"
  chown -R "postgres:postgres" "$PGDATA"
  chmod 700 "$PGDATA"

  if [ ! -s "$PGDATA/PG_VERSION" ]; then
    docker/gprun.py -u postgres initdb
  fi

  cp conf/pg_hba.conf "$PGDATA"
  chown postgres:postgres "$PGDATA/pg_hba.conf"
  chmod 400 "$PGDATA/pg_hba.conf"

  cp conf/postgresql.conf "$PGDATA"
  chown postgres:postgres "$PGDATA/postgresql.conf"
  chmod 400 "$PGDATA/postgresql.conf"

  # put these files where they are needed
  readsecret CERTIFICATE_KEY /server.key postgres:postgres 400
  readsecret CERTIFICATE_CRT /server.crt postgres:postgres 400
  readsecret CERTIFICATE_CACERT /ca.crt postgres:postgres 400

  # read needed variables to fail early
  DB_PASSWORD="$(readsecret DB_PASSWORD)"
  MD5_DB_PASSWORD_POSTGRES=\'md5"$(echo -n "${DB_PASSWORD}postgres" | md5sum | awk '{print $1;}')"\'
  MD5_DB_PASSWORD_DJANGO=\'md5"$(echo -n "${DB_PASSWORD}django" | md5sum | awk '{print $1;}')"\'
  MD5_DB_PASSWORD_EXPLORER=\'md5"$(echo -n "${DB_PASSWORD}explorer" | md5sum | awk '{print $1;}')"\'

  # start postgres locally
  docker/gprun.py -u postgres pg_ctl -D "$PGDATA" \
    -o "-c listen_addresses='127.0.0.1'" \
    -o "-c log_statement=none" \
    -o "-c log_connections=off" \
    -o "-c log_disconnections=off" \
    -w start > /dev/null

  psql -h 127.0.0.1 -U postgres \
    -c "ALTER ROLE postgres ENCRYPTED PASSWORD $MD5_DB_PASSWORD_POSTGRES" \
    -c 'CREATE ROLE django' \
    -c "ALTER ROLE django ENCRYPTED PASSWORD $MD5_DB_PASSWORD_DJANGO LOGIN SUPERUSER" \
    -c 'CREATE ROLE explorer' \
    -c "ALTER ROLE explorer ENCRYPTED PASSWORD $MD5_DB_PASSWORD_EXPLORER LOGIN" \
    -c '\c postgres django' \
    -c 'CREATE DATABASE django' \
    -c '\c django postgres' \
    -c 'REVOKE CREATE ON SCHEMA public FROM public' \
    -c 'GRANT SELECT ON ALL TABLES IN SCHEMA public TO explorer' \
    -c 'ALTER DEFAULT PRIVILEGES FOR USER django IN SCHEMA public GRANT SELECT ON TABLES TO explorer'

  # stop the internally started postgres
  docker/gprun.py -u postgres pg_ctl stop -s -w -m fast

  exec docker/gprun.py -u postgres postgres
fi
################################################################################
if [ "$1" = 'django' ]; then
  prepare_django

  if [ "$ENV" = 'DEV' ]; then
    exec docker/gprun.py -u django -s SIGINT django-admin runserver 0.0.0.0:8000
  fi
  exec docker/gprun.py -u django -s SIGINT uwsgi --ini conf/uwsgi.conf
fi
################################################################################
if [ "$1" = 'nginx' ]; then
  readsecret CERTIFICATE_KEY /certificate.key 0:0 400
  readsecret CERTIFICATE_CRT /certificate.crt 0:0 400

  if [ "$ENV" = 'DEV' ]; then
    conf=/src/conf/nginx.dev.conf
  else
    conf=/src/conf/nginx.conf
  fi
  exec nginx -c "$conf"
fi

################################################################################
if [ "$1" = 'test' ]; then
  prepare_django

  keepdb=''
  if [ "$2" = 'keepdb' ]; then
    keepdb='--keepdb'
  fi
  docker/gprun.py -u django -s SIGINT coverage run --rcfile /src/.coveragerc /src/django_project/manage.py test $keepdb -v 2 --noinput
  coverage report

  chown -R django:django /src/static
  coverage html
  chown -R "$(stat -c %u:%g .git)" /src/static
  exit 0
fi

################################################################################
if [ "$1" = 'collectstatic' ]; then
  prepare_django

  mkdir -p /src/static
  chown -R django:django /src/static
  docker/gprun.py -u django django-admin collectstatic -c --noinput
  # ENV=PROD docker/gprun.py -u django django-admin compress --force
  # ENV=TEST docker/gprun.py -u django django-admin compress --force
  chown -R "$(stat -c %u:%g .git)" /src/static
  find /src/static -type d -exec chmod 755 {} +
  find /src/static -type f -exec chmod 644 {} +
  exit 0
fi

################################################################################
if [ "$1" = 'coverage' ]; then
  prepare_django
  mkdir -p /src/static
  chown -R django:django /src/static
  docker/gprun.py -u django coverage run --rcfile /src/.coveragerc django_project/manage.py test
  docker/gprun.py -u django coverage html --rcfile /src/.coveragerc
  docker/gprun.py -u django coverage report
  chown -R "$(stat -c %u:%g .git)" /src/static
  find /src/static -type d -exec chmod 755 {} +
  find /src/static -type f -exec chmod 644 {} +
  exit 0
fi

################################################################################
if [ "$1" = 'docs' ]; then
  prepare_django

  usr="$(stat -c %u:%g .git)"
  mkdir -p /src/docs/build && chown -R django:django /src/docs/build
  cd /src/docs
  /src/docker/gprun.py -u django make html
  /src/docker/gprun.py -u django make latexpdf
  chown -R "$usr" /src/docs/build
  cd /src/docs/build/latex
  /src/docker/gprun.py -u django make all
  exit 0
fi

################################################################################
if [ "$1" = 'with_django' ]; then
  shift
  prepare_django
  exec docker/gprun.py -u django -s SIGINT "$@"
fi

################################################################################
if [ "$1" = 'backup' ]; then
  typ="$(ask_user "What do you want to backup?" db files both)"
  if [ "$typ" = 'db' ] || [ "$typ" = 'both' ]; then
    format="$(ask_user "What db backup format do you want to use?" custom plain)"
    backup "$typ" "$format"
  else
    backup "$typ"
  fi
  exit 0
fi

################################################################################
if [ "$1" = 'backup_daemon' ]; then
  exit 0
fi

################################################################################
if [ "$1" = 'restore' ]; then
  if ! [ "$ENV" = 'DEV' ]; then
    read -p "Enter hostname: " -r host
    if ! [ "$host" = "$HOST_NAME" ]; then
      echo "Hostname mismatch."; exit 1
    fi
  fi

  typ="$(ask_user "What do you want to restore?" db files both)"

  if [ "$typ" = 'db' ] || [ "$typ" = 'both' ]; then
    array=()
    while IFS=  read -r -d $'\0'; do
      array+=("$REPLY")
    done < <(find /backup/db -type f -printf "%f\0")

    filename="$(ask_user "Which db backup would you like to use?" "${array[@]}")"
    restore "$typ" "$filename"
  else
    restore "$typ"
  fi
  exit 0
fi

################################################################################
exec "$@"
