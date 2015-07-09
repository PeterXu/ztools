#!/usr/bin/env bash

root="/tmp/cert_pems"
name="$root/ssl-cert"
mkdir -p $root


# private key
openssl genrsa -des3 -out ${name}.key 1024

# Certificate Signing Request (CSR)
openssl req -new -key ${name}.key -out ${name}.csr

# clear passwd tips for nginx
cp ${name}.key ${name}.key.orgin
openssl rsa -in ${name}.key.orgin -out ${name}.key

# sign key
openssl x509 -req -days 365 -in ${name}.csr -signkey ${name}.key -out ${name}.crt
