#!/bin/bash
# 7.2 - Advanced Traefik: virtual hosts (web1.localhost / web2.localhost)
#       + the Traefik dashboard API.
#       NOTE: same traefik:v3.6 pin as 7.1 (Docker 29 API floor, see README).
SCEN_DIR="$(dirname "$(readlink -f "$0")")"
cd "$SCEN_DIR"

docker-compose -f docker-compose-advanced.yml up -d
sleep 5

{
    echo "=== Testing web1 ==="
    curl -H "Host: web1.localhost" http://localhost:8080/
    echo -e "\n=== Testing web2 ==="
    curl -H "Host: web2.localhost" http://localhost:8080/
    echo -e "\n=== Traefik Dashboard ==="
    curl http://localhost:8081/api/http/routers
} > advanced_test.txt

docker-compose -f docker-compose-advanced.yml down

echo "7.2 advanced_test completed. Report: advanced_test.txt"