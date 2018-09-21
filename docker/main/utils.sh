#!/bin/bash
set -e

# ask_user "Prompt question" option1 option2 ...
ask_user() {
  local prompt="$1" i r; shift

  echo >&2; echo "$prompt" >&2; echo >&2;
  if [ "$#" = 0 ]; then
    echo "Nothing to choose from... exiting" >&2
    return 1
  fi

  i=0; for o in "$@"; do echo -e "$i\t$o" >&2; i=$((i+1)); done; echo >&2

  while true; do
    read -p "Enter a number in range 0-$(($# - 1)): " -r r
    i=0; for o in "$@"; do
      if [ "$r" = "$i" ]; then echo "$o"; return; fi; i=$((i+1))
    done
  done
}

# createsecret [-f|-r] SECRET param
#   * -f: create secret from a file; param is the filename
#   * -r: random string; param is the length
#   * no option; param should be the value
createsecret() {
  local fn='/src/.secret.env'
  local value replace

  # check if the secret exists
  while IFS= read -r p; do
    if [ "$(echo "$p" | sed -rn 's/^([^#=\s]*)=(.*)$/\1/p')" = "$1" ]; then
      if [ -n "$3" ]; then
        replace=1
      else
        echo "Secret already exists: $1" >&2; return 1
      fi
    fi
  done < "$fn"

  if [ -n "$replace" ]; then
    sed -ri "/^($1=).*$/d" "$fn"
  fi

  case "$1" in
    -f)
      shift
      value="$(base64 -w0 "$2")"
      ;;
    -r)
      shift
      value="$(</dev/urandom tr -dc '[:graph:]' | head -c "$2" | base64 -w0)"
      ;;
    *)
      value="$(echo -n "$2" | base64 -w0)"
    esac

    echo "$1=$value" >> "$fn"
}

decodeline() {
  echo "$1" | sed -rn 's/^([^#=]*)=(.*)$/\2/p' | base64 -d
}

# readsecret SECRET [filename owner:group mode]
readsecret() {
  local fn='/.secret.env'
  local value

  while IFS= read -r p; do
    if [ "$(echo "$p" | sed -rn 's/^([^#=]*)=(.*)$/\1/p')" = "$1" ]; then
      if [ -n "$2" ]; then
        decodeline "$p" > "$2"
        if [ -n "$3" ]; then
          chown "$3" "$2"
          if [ -n "$4" ]; then
            chmod "$4" "$2"
          fi
        fi
      else
        decodeline "$p"
      fi
      return 0
    fi
  done < "$fn"
  echo "Secret not found: $1" >&2; return 1
}

set_files_perms() {
  chown -R django:nginx /data/files
  find /data/files -type d -exec chmod 2750 {} +
  find /data/files -type f -exec chmod 640 {} +
}

# some common setting for django and friends to be able to run
prepare_django() {
  mkdir -p /run/secrets
  readsecret DB_PASSWORD /run/secrets/DB_PASSWORD django:django 400
  readsecret DJANGO_SECRET_KEY /run/secrets/DJANGO_SECRET_KEY django:django 400
  readsecret EMAIL_HOST_USER /run/secrets/EMAIL_HOST_USER django:django 400
  readsecret EMAIL_HOST_PASSWORD /run/secrets/EMAIL_HOST_PASSWORD django:django 400

  # the django postgres client looks for these certs in ~/.postgresql
  mkdir -p /home/django/.postgresql
  readsecret CERTIFICATE_KEY /home/django/.postgresql/postgresql.key django:django 400
  readsecret CERTIFICATE_CRT /home/django/.postgresql/postgresql.crt django:django 400
  readsecret CERTIFICATE_CACERT /home/django/.postgresql/root.crt django:django 400

  # make sure files and directories permissions are correct by setting the setgid bit
  # the other part of the story is settings.FILE_UPLOAD_DIRECTORY_PERMISSIONS
  mkdir -p /data/files
  set_files_perms

  # wait for the database to be ready
  while ! PGPASSWORD=$(readsecret DB_PASSWORD) docker/gprun.py -u django psql -h postgres -U django -d django -c 'select 1' &> /dev/null; do
    echo "postgres not ready yet..." >&2; sleep 1
  done
  echo "postgres ready" >&2; return 0
}

set_backup_perms() {
  chown -R "$BACKUP_UID:$BACKUP_UID" /backup; chmod 755 /backup
  mkdir -p /backup/db /backup/files
  find /backup/db -type d -exec chmod 700 {} +
  find /backup/db -type f -exec chmod 600 {} +
  find /backup/files -type d -exec chmod 700 {} +
  find /backup/files -type d -exec chmod g-s {} +
  find /backup/files -type f -exec chmod 600 {} +
}

restore() {
  set_backup_perms

  if [ "$1" = 'db' ]; then
    db=1; file="$2"
  elif [ "$1" = 'files' ]; then
    files=1
  elif [ "$1" = 'both' ]; then
    db=1; files=1; file="$2"
  else
    echo "Restore type should be 'db', 'files' or 'both'." >&2; return 1
  fi

  prepare_django

  if [ -n "$db" ]; then
    # make the file readable by django
    chown django /backup/db "/backup/db/$file"

    if [[ "$file" =~ \.backup$ ]]; then
      PGPASSWORD=$(readsecret DB_PASSWORD) docker/gprun.py -u django \
      pg_restore -e -v -h postgres -U postgres -d postgres -Cc "/backup/db/$file"
    elif [[ "$file" =~ \.backup.sql$ ]]; then
      PGPASSWORD=$(readsecret DB_PASSWORD) docker/gprun.py -u django \
      psql -h postgres -U postgres -d postgres \
        -c "DROP DATABASE django" \
        -c "CREATE DATABASE django OWNER django"

      PGPASSWORD=$(readsecret DB_PASSWORD) docker/gprun.py -u django \
      psql -v ON_ERROR_STOP=1 -h postgres -d django -U postgres -f "/backup/db/$file"
    else
      echo "Invalid file format." >&2; return 1
    fi

    PGPASSWORD=$(readsecret DB_PASSWORD) docker/gprun.py -u django \
    psql -h postgres -U postgres -d django -c "ANALYZE"
  fi

  if [ -n "$files" ]; then
    rsync -a --delete --stats /backup/files/ /data/files/
    # make files correct for django
    set_files_perms
  fi

  # fake passwords for development
  if readsecret FAKE_PASSWORDS > /dev/null; then
    if ! [ "$ENV" = 'DEV' ]; then
      echo "Setting up fake passwords are forbidden" >&2
    else
      echo "Setting up fake passwords for development"
      docker/gprun.py -u django -s SIGINT django-admin set_fake_passwords --password "$(readsecret FAKE_PASSWORDS)"
    fi
  fi

  set_backup_perms
  echo "Done"
}

backup() {
  set_backup_perms

  if [ "$1" = 'db' ]; then
    db=1
    format="$2"
  elif [ "$1" = 'files' ]; then
    files=1
  elif [ "$1" = 'both' ]; then
    db=1; files=1
    format="$2"
  else
    echo "Backup type should be 'db', 'files' or 'all'." >&2; return 1
  fi

  prepare_django

  if [ -n "$db" ]; then
    timestamp=$(date -u +"%Y-%m-%d-%H-%M-%Z")
    if [ "$format" = "custom" ]; then
      filename="$HOST_NAME-db-$timestamp.backup"
    elif [ "$format" = "plain" ]; then
      filename="$HOST_NAME-db-$timestamp.backup.sql"
    else
      echo "Invalid backup format (can be 'plain' or 'custom')."; return 1
    fi

    # django should be able to write to this directory
    chown django:django /backup/db
    PGPASSWORD=$(readsecret DB_PASSWORD) docker/gprun.py -u django \
    pg_dump -h postgres -U django -d django -F "$format" -f "/backup/db/$filename"
  fi

  if [ -n "$files" ]; then
    rsync -a --delete --stats /data/files/ /backup/files/
  fi

  set_backup_perms
}
