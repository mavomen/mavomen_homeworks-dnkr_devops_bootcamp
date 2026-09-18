#!/bin/bash

# ============================================================
# 4.1 - Create & use a named volume
# ============================================================

SCEN_DIR="$(dirname "$(readlink -f "$0")")"

docker volume create my-data
docker rm -f volume-test volume-test-2 >/dev/null 2>&1 || true

docker run -d --name volume-test -v my-data:/app/data alpine:latest sleep 3600
docker exec volume-test sh -c 'echo "Hello from container" > /app/data/test.txt'
docker exec volume-test cat /app/data/test.txt > "$SCEN_DIR/volume_content.txt"
docker volume inspect my-data > "$SCEN_DIR/volume_info.txt"

# data persists even after the container is removed
docker rm -f volume-test
docker run -d --name volume-test-2 -v my-data:/app/data alpine:latest sleep 3600
docker exec volume-test-2 cat /app/data/test.txt >> "$SCEN_DIR/volume_content.txt"

echo "Volume operations completed."
echo "  -> volume_content.txt"
echo "  -> volume_info.txt"