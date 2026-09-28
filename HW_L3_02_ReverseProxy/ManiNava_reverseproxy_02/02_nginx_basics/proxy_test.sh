#!/bin/bash
# 2.3 - Reverse proxy: nginx (front) -> python backend via container name
# NOTE: the PDF runs both containers on the default `bridge` network, but
# Docker's default bridge has NO embedded DNS, so `backend-api` would not
# resolve. Using a user-defined network (rp-net) keeps the exact same
# config/file names while making name resolution work as intended.
SCEN_DIR="$(dirname "$(readlink -f "$0")")"
cd "$SCEN_DIR"

docker network create rp-net > /dev/null 2>&1 || true

docker run -d --name backend-api \
    --network rp-net \
    python:3.9-alpine \
    sh -c "python3 -m http.server 5000"

docker run -d --name nginx-proxy \
    -p 8080:80 \
    --network rp-net \
    -v "$SCEN_DIR/nginx.conf:/etc/nginx/nginx.conf:ro" \
    -v "$SCEN_DIR/web:/usr/share/nginx/html:ro" \
    nginx:alpine
sleep 3

curl http://localhost:8080/ > frontend_test.txt
curl http://localhost:8080/api > api_test.txt
docker logs nginx-proxy | tail -n 10 > proxy_logs.txt

docker stop nginx-proxy backend-api
docker rm nginx-proxy backend-api
docker network rm rp-net > /dev/null 2>&1 || true

echo "2.3 proxy_test completed. Reports: frontend_test.txt, api_test.txt, proxy_logs.txt"