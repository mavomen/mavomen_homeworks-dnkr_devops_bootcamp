#!/bin/bash

# ============================================================
# 4.2 - Bind Mount for development
# ============================================================

SCEN_DIR="$(dirname "$(readlink -f "$0")")"

docker rm -f bind-mount-test >/dev/null 2>&1 || true
docker run -d --name bind-mount-test -p 9000:80 -v "$SCEN_DIR/web:/usr/share/nginx/html:ro" nginx:alpine

sleep 2
curl --retry 3 --retry-connrefused --retry-delay 1 http://localhost:9000 > "$SCEN_DIR/bind_mount_output.html"
echo "File modified on host" >> "$SCEN_DIR/web/index.html"
curl --retry 3 --retry-connrefused --retry-delay 1 http://localhost:9000 > "$SCEN_DIR/bind_mount_output_modified.html"

echo "Bind mount test completed."
echo "  -> bind_mount_output.html"
echo "  -> bind_mount_output_modified.html"