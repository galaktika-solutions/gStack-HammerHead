#!/bin/bash

set -eo pipefail

. /utils.sh

# check if the directory is empty
if ! [ -d /project_root ]; then
  echo "Project root was not bind-mounted as /project_root. Exiting"
  exit 1
fi

if ! [ "$(ls -A1 /project_root | wc -l)" = 0 ]; then
  echo "The project root directory must be empty"
  exit 1
fi

proc_file -c 0:0:600 \
  -s "HOST_NAME:localhost" \
  -s "NETWORK_SUBNET:10.7.11.0/24" \
  -s "COMPOSE_PROJECT_NAME:gstackdemo" \
  /demo/.env /project_root/.env
proc_file -c 0:0:600 /demo/docker-compose.yml /project_root/docker-compose.yml

mkdir -m 555 \
  /project_root/.secrets \
  /project_root/.secrets/django \
  /project_root/.secrets/postgres \
  /project_root/.secrets/nginx

secret="$(</dev/urandom tr -dc '[:graph:]' | head -c 32; echo "")"
echo -n "$secret" > /project_root/.secrets/django/DB_PASSWORD
proc_file -c django:django:600 /project_root/.secrets/django/DB_PASSWORD
echo -n "$secret" > /project_root/.secrets/postgres/DB_PASSWORD
proc_file -c postgres:postgres:600 /project_root/.secrets/postgres/DB_PASSWORD

secret="$(</dev/urandom tr -dc '[:graph:]' | head -c 64; echo "")"
echo -n "$secret" > /project_root/.secrets/django/DJANGO_SECRET_KEY
proc_file -c django:django:600 /project_root/.secrets/django/DJANGO_SECRET_KEY

# certificates
cd /demo

HOST_NAME=$(cat /project_root/.env | sed -nr 's/^HOST_NAME=(.*)$/\1/ p')
COMPOSE_PROJECT_NAME=$(cat /project_root/.env | sed -nr 's/^COMPOSE_PROJECT_NAME=(.*)$/\1/ p')
COMMON_NAME="$COMPOSE_PROJECT_NAME-$(</dev/urandom tr -dc '[:digit:]' | head -c 8; echo "")"

san="DNS:$HOST_NAME, \
     IP:127.0.0.1"

# generate CA private key
openssl genrsa -out ca.key 2048

# self signed CA certificate
openssl req -x509 -new -nodes -subj "/commonName=$COMMON_NAME-ca" \
        -key ca.key -sha256 -days 1024 -out ca.crt

# generate private key
openssl genrsa -out certificate.key 2048

# certificate request
openssl req -new -sha256 -subj "/commonName=$COMMON_NAME" \
        -key certificate.key -reqexts SAN -out certificate.csr \
        -config <(cat /etc/ssl/openssl.cnf \
                  <(printf "[SAN]\nsubjectAltName=%s" "$san"))

# sign the certificate with CA
openssl x509 -req -in certificate.csr -CA ca.crt -CAkey ca.key \
        -out certificate.crt -days 500 -sha256 -extensions SAN \
        -CAcreateserial -CAserial ca.srl \
        -extfile <(cat /etc/ssl/openssl.cnf \
                   <(printf "[SAN]\nsubjectAltName=%s" "$san"))


proc_file -c 0:0:600 certificate.crt /project_root/.secrets/nginx/certificate.crt
proc_file -c 0:0:600 certificate.key /project_root/.secrets/nginx/certificate.key
proc_file -c 0:0:666 ca.crt /project_root/ca.crt
