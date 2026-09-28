#!/bin/bash
# 5.1 - Generate mTLS certificates: CA, server, client
set -e
SCEN_DIR="$(dirname "$(readlink -f "$0")")"
cd "$SCEN_DIR"

mkdir -p ca client server

# CA certificate
openssl req -x509 -new -nodes -keyout ca/rootCA.key -sha256 -days 365 \
    -out ca/rootCA.crt -subj "/C=IR/O=DevOpsClass/CN=demo-ca"

# Server certificate
openssl req -new -nodes -out server/server.csr -keyout server/server.key \
    -subj "/C=IR/O=DevOpsClass/CN=mtls.local"
openssl x509 -req -in server/server.csr -CA ca/rootCA.crt -CAkey ca/rootCA.key \
    -out server/server.crt -days 365 -sha256 -CAcreateserial

# Client certificate
openssl req -new -nodes -out client/client.csr -keyout client/client.key \
    -subj "/C=IR/O=DevOpsClass/CN=client1"
openssl x509 -req -in client/client.csr -CA ca/rootCA.crt -CAkey ca/rootCA.key \
    -out client/client.crt -days 365 -sha256 -CAcreateserial

echo "Certificates generated successfully"
ls -R . > certs_structure.txt

echo "5.1 generate_certs completed. Reports: ca/, server/, client/, certs_structure.txt"