#!/bin/bash

# ============================================================
# 2.1 - Run a simple container & check its status
# ============================================================

SCEN_DIR="$(dirname "$(readlink -f "$0")")"

# clean up if a previous container exists
docker rm -f test-nginx >/dev/null 2>&1 || true

# run a simple container
docker run -d --name test-nginx nginx:alpine

sleep 2
docker ps | grep test-nginx
docker logs test-nginx | head -n 10 > "$SCEN_DIR/nginx_logs.txt"

docker stop test-nginx
docker ps -a | grep test-nginx

# container state
docker inspect test-nginx | grep -A 3 "State" > "$SCEN_DIR/container_state.txt"

echo "Container basics completed."
echo "  -> nginx_logs.txt"
echo "  -> container_state.txt"