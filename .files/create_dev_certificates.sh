#!/bin/bash
set -e

common_name="$COMPOSE_PROJECT_NAME"
san="DNS:$HOST_NAME,IP:$SERVER_IP"

rm -rf *.{crt,key,csr}

# generate CA private key
openssl genrsa -out ca.key 2048

# self signed CA certificate
openssl req -x509 -new -nodes -subj "/commonName=$common_name-ca" \
        -key ca.key -sha256 -days 1024 -out ca.crt

# generate private key
openssl genrsa -out certificate.key 2048

# certificate request
openssl req -new -sha256 -subj "/commonName=$common_name" \
        -key certificate.key -reqexts SAN -out certificate.csr \
        -config <(cat /etc/ssl/openssl.cnf \
                  <(printf "[SAN]\nsubjectAltName=%s" "$san"))

# sign the certificate with CA
openssl x509 -req -in certificate.csr -CA ca.crt -CAkey ca.key \
        -out certificate.crt -days 500 -sha256 -extensions SAN \
        -CAcreateserial -CAserial ca.srl \
        -extfile <(cat /etc/ssl/openssl.cnf \
                   <(printf "[SAN]\nsubjectAltName=%s" "$san"))

rm certificate.csr

# # client cert for the browser
# openssl pkcs12 -export -clcerts -in certificate.crt -inkey certificate.key \
#         -passout pass:admin -out certificate.pfx
