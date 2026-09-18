#!/bin/bash

# ============================================================
# 6.1 - Compose: start services & check
# ============================================================

SCEN_DIR="$(dirname "$(readlink -f "$0")")"
cd "$SCEN_DIR" || exit 1

# ensure the full 3-service compose file (S6.3's env_test.sh
# later replaces this file with the .env version)
cat > docker-compose.yml <<'YAML'
version: '3.8'

services:
  web:
    image: nginx:alpine
    ports:
      - "8080:80"
    volumes:
      - ./web:/usr/share/nginx/html:ro
    depends_on:
      - app

  app:
    image: alpine:latest
    command: sh -c "apk add --no-cache python3 && python3 -m http.server 5000"
    ports:
      - "5000:5000"
    volumes:
      - ./app:/app
    working_dir: /app

  db:
    image: mysql:8.0
    environment:
      MYSQL_ROOT_PASSWORD: rootpass
      MYSQL_DATABASE: testdb
    volumes:
      - db-data:/var/lib/mysql

volumes:
  db-data:
YAML

docker-compose up -d
sleep 5
docker-compose ps > compose_status.txt
docker-compose logs web | head -n 10 > web_logs.txt
curl --retry 3 --retry-connrefused --retry-delay 1 http://localhost:8080 > web_response.html
docker-compose down

echo "Compose operations completed."
echo "  -> compose_status.txt"
echo "  -> web_logs.txt"
echo "  -> web_response.html"