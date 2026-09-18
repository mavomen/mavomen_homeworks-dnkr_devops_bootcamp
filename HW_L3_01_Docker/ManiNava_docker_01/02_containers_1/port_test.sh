#!/bin/bash

# ============================================================
# 2.3 - Port Mapping & access to the container
# ============================================================

SCEN_DIR="$(dirname "$(readlink -f "$0")")"

docker rm -f web-server >/dev/null 2>&1 || true
docker run -d --name web-server -p 8888:80 nginx:alpine

sleep 2
curl --retry 3 --retry-connrefused --retry-delay 1 -I http://localhost:8888 > "$SCEN_DIR/port_mapping_test.txt"
docker port web-server >> "$SCEN_DIR/port_mapping_test.txt"
ss -tuln | grep 8888 >> "$SCEN_DIR/port_mapping_test.txt"

echo "Port mapping test completed. Output saved to port_mapping_test.txt"