#!/bin/bash
# 7.1 - Traefik with the Docker provider (automatic service discovery)
#       NOTE: Docker 29 only serves API >= 1.40, traefik < v3.5 talks API 1.24
#       so its docker provider never loads. Pinned traefik:v3.6 (see README).
SCEN_DIR="$(dirname "$(readlink -f "$0")")"
cd "$SCEN_DIR"

docker-compose up -d
sleep 5

docker-compose ps > traefik_status.txt
curl http://localhost:8080/ > whoami_response.txt
curl http://localhost:8081/api/rawdata > traefik_api.txt 2>&1 || echo "API check" >> traefik_api.txt
# docker compose 5.x writes `logs` output to stderr, hence the 2>&1
docker-compose logs --no-color traefik 2>&1 | tail -n 30 > traefik_logs.txt

docker-compose down

echo "7.1 run_traefik completed. Reports: traefik_status.txt, whoami_response.txt, traefik_api.txt, traefik_logs.txt"