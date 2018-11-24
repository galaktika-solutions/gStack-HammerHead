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
# Utilities (should be started in dev or deployment)
################################################################################
usergroup="$(stat -c '%u:%g' .)"

# ################################################################################
# if [ "$1" = 'test' ]; then
#   prepare -w django
#
#   keepdb=''
#   if [ "$2" = 'keepdb' ]; then
#     keepdb='--keepdb'
#   fi
#
#   gprun -u django:django -s SIGINT coverage run django-admin test \
#     $keepdb -v 2 --noinput
#   coverage report
#   u="$(stat -c '%u' .git)"
#   gprun -u "$u:$u" coverage html
#   exit 0
# fi

# ################################################################################
# if [ "$1" = 'collectstatic' ]; then
#   prepare -w -u "$usergroup" django
#   # mkdir -p static
#   # chown -R django:django /src/static
#   gprun -u "$usergroup" django-admin collectstatic -c --noinput
#   # Django uses FILE_UPLOAD_DIRECTORY_PERMISSIONS and FILE_UPLOAD_PERMISSIONS
#   # to create these files, but it is not good for us here.
#   find /src/static -type d -exec chmod 755 {} +
#   find /src/static -type f -exec chmod 644 {} +
#   exit 0
# fi

# ################################################################################
# if [ "$1" = 'makemigrations' ]; then
#   prepare -w django
#   chown -R django:django /src/djangoproject/*/migrations
#   gprun -u django:django django-admin makemigrations
#   find /src/static -type d -exec chmod 755 {} +
#   find /src/static -type f -exec chmod 644 {} +
#   u="$(stat -c '%u' .git)"
#   chown -R "$u:$u" /src/djangoproject/*/migrations
#   exit 0
# fi

# ################################################################################
# if [ "$1" = 'docs' ]; then
#   u="$(stat -c '%u' .git)"
#   prepare -w -u "$u" django
#   cd /src/docs
#   gprun -u "$u:$u" make html
#   # gprun -u "$u:$u" make latexpdf
#   # What are these lines for?
#   # cd /src/docs/build/latex
#   # gprun -u "$u:$u" make all
#   exit 0
# fi

################################################################################
if [ "$1" = 'with_django' ]; then
  shift
  prepare -w -u "$usergroup" django
  exec gprun -u "$usergroup" "$@"
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
