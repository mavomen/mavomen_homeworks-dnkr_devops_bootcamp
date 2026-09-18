#!/bin/bash

# ============================================================
# 6.3 - Environment variables & .env file
# ============================================================
# Updates docker-compose.yml to read variables from .env
# (this is the HW 6.3 step: "update docker-compose.yml to use
#  environment variables"), then validates with `config`.

SCEN_DIR="$(dirname "$(readlink -f "$0")")"
cd "$SCEN_DIR" || exit 1

cat > docker-compose.yml <<'YAML'
version: '3.8'

services:
  web:
    image: nginx:alpine
    ports:
      - "${APP_PORT:-8080}:80"
    environment:
      - APP_NAME=MyApp
    volumes:
      - ./web:/usr/share/nginx/html:ro

  db:
    image: mysql:8.0
    environment:
      MYSQL_ROOT_PASSWORD: ${MYSQL_ROOT_PASSWORD}
      MYSQL_DATABASE: ${MYSQL_DATABASE}
    volumes:
      - db-data:/var/lib/mysql

volumes:
  db-data:
YAML

docker-compose config > compose_with_env.txt
docker-compose up -d
sleep 5
docker-compose exec db env | grep MYSQL > db_env_vars.txt
docker-compose down

echo "Env test completed."
echo "  -> compose_with_env.txt"
echo "  -> db_env_vars.txt"