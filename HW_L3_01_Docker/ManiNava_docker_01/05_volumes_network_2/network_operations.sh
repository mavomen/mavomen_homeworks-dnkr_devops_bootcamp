#!/bin/bash

# ============================================================
# 5.1 - Create a custom network & attach containers
# ============================================================

SCEN_DIR="$(dirname "$(readlink -f "$0")")"

docker network create my-network >/dev/null 2>&1 || true
docker rm -f container1 container2 >/dev/null 2>&1 || true

docker run -d --name container1 --network my-network alpine:latest sleep 3600
docker run -d --name container2 --network my-network alpine:latest sleep 3600

docker network inspect my-network > "$SCEN_DIR/network_info.txt"
docker exec container1 ping -c 3 container2 > "$SCEN_DIR/ping_test.txt"
docker exec container1 nslookup container2 >> "$SCEN_DIR/ping_test.txt"

echo "Network operations completed."
echo "  -> network_info.txt"
echo "  -> ping_test.txt"