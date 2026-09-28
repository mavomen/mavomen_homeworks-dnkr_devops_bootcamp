#!/bin/bash
# 6.1 - Two backend nginx containers with different content
# NOTE: like 2.3, the PDF uses the default bridge; a user-defined network
# (hb-net) is used so haproxy can resolve the backends by name.
SCEN_DIR="$(dirname "$(readlink -f "$0")")"
cd "$SCEN_DIR"

mkdir -p backend1 backend2
echo "<h1>Backend Server 1</h1>" > "$SCEN_DIR/backend1/index.html"
echo "<h1>Backend Server 2</h1>" > "$SCEN_DIR/backend2/index.html"

docker network create hb-net > /dev/null 2>&1 || true

# Backend 1
docker run -d --name backend1 \
    --network hb-net \
    -v "$SCEN_DIR/backend1:/usr/share/nginx/html:ro" \
    -p 8080:80 \
    nginx:alpine

# Backend 2
docker run -d --name backend2 \
    --network hb-net \
    -v "$SCEN_DIR/backend2:/usr/share/nginx/html:ro" \
    -p 8081:80 \
    nginx:alpine

sleep 2
curl http://localhost:8080/ > backend1_response.txt
curl http://localhost:8081/ > backend2_response.txt
docker ps | grep backend > backends_status.txt

echo "6.1 setup_backends completed. Reports: backend1_response.txt, backend2_response.txt, backends_status.txt"