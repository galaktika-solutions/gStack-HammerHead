#!/bin/bash
set -e

################################################################################
if [ "$1" = 'postgres' ]; then
  ensure_db
  exec gprun -u postgres postgres
fi

################################################################################
if [ "$1" = 'django' ]; then
  prepare -w django
  if [ "$ENV" = 'DEV' ]; then
    exec gprun -u django -s SIGINT django-admin runserver 0.0.0.0:8000
  fi
  exec gprun -u django -s SIGINT uwsgi --ini conf/uwsgi.conf
fi

################################################################################
if [ "$1" = 'nginx' ]; then
  prepare nginx
  if [ "$ENV" = 'DEV' ]; then
    conf=/src/conf/nginx.dev.conf
  else
    conf=/src/conf/nginx.conf
  fi
  exec nginx -c "$conf"
fi

################################################################################
# Utilities (will run as the dir owner in DEV)
################################################################################
usergroup=django
if [ "$ENV" = 'DEV' ]; then
  usergroup="$(stat -c '%u:%g' .)"
fi

################################################################################
if [ "$1" = 'collectstatic' ]; then
  prepare -w -u "$usergroup" django
  gprun -u "$usergroup" django-admin collectstatic -c --noinput
  # Django uses FILE_UPLOAD_DIRECTORY_PERMISSIONS and FILE_UPLOAD_PERMISSIONS
  # to create these files, but it is not good for us here.
  find /src/static -type d -exec chmod 755 {} +
  find /src/static -type f -exec chmod 644 {} +
  exit 0
fi

################################################################################
if [ "$1" = 'with_django' ]; then
  shift
  echo "starting with uid:gid $usergroup"
  prepare -w -u "$usergroup" django
  exec gprun -u "$usergroup" -s SIGINT "$@"
fi

################################################################################
if [ "$1" = 'backup' ]; then
  prepare -w -u 0 backup
  exec backup_ui -d
fi

################################################################################
if [ "$1" = 'restore' ]; then
  if ! [ "$ENV" = 'DEV' ]; then
    read -p "Enter hostname: " -r host
    if ! [ "$host" = "$HOST_NAME" ]; then
      echo "Hostname mismatch."; exit 1
    fi
  fi

  prepare -w -u 0 backup
  exec restore_ui -d
fi

################################################################################
exec "$@"
