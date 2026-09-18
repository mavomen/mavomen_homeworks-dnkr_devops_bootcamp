#!/bin/bash

# ============================================================
# 6.2 - Compose: networks & volumes
# ============================================================

SCEN_DIR="$(dirname "$(readlink -f "$0")")"
cd "$SCEN_DIR" || exit 1

# ensure the full 3-service compose file (same as S6.1)
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
docker-compose exec web ping -c 2 app > service_communication.txt
docker network ls | grep docker_compose > compose_networks.txt
docker volume ls | grep docker_compose > compose_volumes.txt
docker-compose down -v

echo "Compose inspect completed."
echo "  -> service_communication.txt"
echo "  -> compose_networks.txt"
echo "  -> compose_volumes.txt"