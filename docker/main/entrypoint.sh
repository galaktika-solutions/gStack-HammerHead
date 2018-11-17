#!/bin/bash
set -e

################################################################################
if [ "$1" = 'postgres' ]; then
  ensure_db
  exec gprun -u postgres:postgres postgres
fi
################################################################################
if [ "$1" = 'redis' ]; then
  exec gprun -u redis:redis redis-server --bind 0.0.0.0
fi

################################################################################
if [ "$1" = 'daphne' ]; then
  if [ "$ENV" = 'DEV' ]; then
    exit 0
  fi
  prepare -w django
  exec gprun -u django:django -s SIGINT daphne -b 0.0.0.0 -p 8001 core.asgi:application
fi

################################################################################
if [ "$1" = 'django' ]; then
  prepare -w django
  if [ "$ENV" = 'DEV' ]; then
    exec gprun -u django:django -s SIGINT django-admin runserver 0.0.0.0:8000
  fi
  exec gprun -u django:django -s SIGINT uwsgi --ini conf/uwsgi.conf
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
# Utilities
################################################################################
if [ "$1" = 'test' ]; then
  prepare -w django

  keepdb=''
  if [ "$2" = 'keepdb' ]; then
    keepdb='--keepdb'
  fi

  gprun -u django:django -s SIGINT coverage run django_project/manage.py test $keepdb -v 2 --noinput
  coverage report

  u="$(stat -c '%u' .git)"
  gprun -u "$u" coverage html
  exit 0
fi

################################################################################
if [ "$1" = 'collectstatic' ]; then
  u="$(stat -c '%u' .git)"
  prepare -w -u "$u" django
  mkdir -p static
  chown -R "$u:$u" /src/static
  gprun -u "$u:$u" django-admin collectstatic -c --noinput
  # ENV=PROD docker/gprun.py -u django django-admin compress --force
  # ENV=TEST docker/gprun.py -u django django-admin compress --force
  find /src/static -type d -exec chmod 755 {} +
  find /src/static -type f -exec chmod 644 {} +
  exit 0
fi

# ################################################################################
# if [ "$1" = 'docs' ]; then
#   prepare_django
#
#   usr="$(stat -c %u:%g .git)"
#   mkdir -p /src/docs/build && chown -R django:django /src/docs/build
#   cd /src/docs
#   /src/docker/gprun.py -u django make html
#   /src/docker/gprun.py -u django make latexpdf
#   chown -R "$usr" /src/docs/build
#   cd /src/docs/build/latex
#   /src/docker/gprun.py -u django make all
#   exit 0
# fi
#
# ################################################################################
# if [ "$1" = 'with_django' ]; then
#   shift
#   prepare_django
#   exec docker/gprun.py -u django -s SIGINT "$@"
# fi
#
# ################################################################################
# if [ "$1" = 'backup' ]; then
#   typ="$(ask_user "What do you want to backup?" db files both)"
#   if [ "$typ" = 'db' ] || [ "$typ" = 'both' ]; then
#     format="$(ask_user "What db backup format do you want to use?" custom plain)"
#     backup "$typ" "$format"
#   else
#     backup "$typ"
#   fi
#   exit 0
# fi
#
# ################################################################################
# if [ "$1" = 'backup_daemon' ]; then
#   exit 0
# fi
#
# ################################################################################
# if [ "$1" = 'restore' ]; then
#   if ! [ "$ENV" = 'DEV' ]; then
#     read -p "Enter hostname: " -r host
#     if ! [ "$host" = "$HOST_NAME" ]; then
#       echo "Hostname mismatch."; exit 1
#     fi
#   fi
#
#   typ="$(ask_user "What do you want to restore?" db files both)"
#
#   if [ "$typ" = 'db' ] || [ "$typ" = 'both' ]; then
#     array=()
#     while IFS=  read -r -d $'\0'; do
#       array+=("$REPLY")
#     done < <(find /backup/db -type f -printf "%f\0")
#
#     filename="$(ask_user "Which db backup would you like to use?" "${array[@]}")"
#     restore "$typ" "$filename"
#   else
#     restore "$typ"
#   fi
#   exit 0
# fi

################################################################################
exec "$@"
