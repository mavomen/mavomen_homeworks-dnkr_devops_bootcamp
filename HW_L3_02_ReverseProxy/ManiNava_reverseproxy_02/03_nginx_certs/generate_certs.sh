#!/bin/bash
# 3.1 - Generate a self-signed SSL certificate for demo.local
SCEN_DIR="$(dirname "$(readlink -f "$0")")"
cd "$SCEN_DIR"

mkdir -p certs

openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout certs/demo.key \
    -out certs/demo.crt \
    -subj "/C=IR/ST=Tehran/L=Tehran/O=DevOpsClass/CN=demo.local"

ls -lh certs/ > certs_info.txt

echo "3.1 generate_certs completed. Reports: certs/demo.key, certs/demo.crt, certs_info.txt"