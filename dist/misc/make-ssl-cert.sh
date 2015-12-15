#!/usr/bin/env bash


gen_des() {
    root="/tmp/cert_pems"
    mkdir -p $root
    local name="$root/ssl-cert"
    # private key
    openssl genrsa -des3 -out ${name}.key 1024

    # Certificate Signing Request (CSR)
    openssl req -new -key ${name}.key -out ${name}.csr

    # clear passwd tips for nginx
    cp ${name}.key ${name}.key.orgin
    openssl rsa -in ${name}.key.orgin -out ${name}.key

    # sign key
    openssl x509 -req -days 365 -in ${name}.csr -signkey ${name}.key -out ${name}.crt
}

gen_aes() {
    root="/tmp/cert_pems_aes"
    mkdir -p $root

    # private key
    openssl genrsa -aes256 -out $root/ca-key.pem 4096

    # note "Common Name" is domain
    penssl req -new -x509 -days 365 -key $root/ca-key.pem -sha256 -out $root/ca.pem

    openssl genrsa -out $root/server-key.pem 4096
    printf "Input /CN:"
    read CN
    openssl req -subj "/CN=$CN" -sha256 -new -key $root/server-key.pem -out $root/server.csr

    echo "subjectAltName = IP:10.10.10.20,IP:127.0.0.1" > /tmp/extfile.cnf
    openssl x509 -req -days 365 -sha256 -in $root/server.csr -CA $root/ca.pem -CAkey $root/ca-key.pem \
        -CAcreateserial -out $root/server-cert.pem -extfile /tmp/extfile.cnf


    # for client
    openssl genrsa -out $root/key.pem 4096
    openssl req -subj '/CN=client' -new -key $root/key.pem -out $root/client.csr
    echo extendedKeyUsage = clientAuth > /tmp/extfile.cnf
    openssl x509 -req -days 365 -sha256 -in $root/client.csr -CA $root/ca.pem -CAkey $root/ca-key.pem \
          -CAcreateserial -out $root/cert.pem -extfile /tmp/extfile.cnf

    # post
    rm -v $root/{client.csr,server.csr}

    # umask 022
    chmod -v 0400 $root/{ca-key.pem,key.pem,server-key.pem}
    chmod -v 0444 $root/{ca.pem,server-cert.pem,cert.pem}
}

gen_des

