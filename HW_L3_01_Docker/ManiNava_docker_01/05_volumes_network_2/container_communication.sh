#!/bin/bash

# ============================================================
# 5.2 - Communication between containers
# ============================================================

SCEN_DIR="$(dirname "$(readlink -f "$0")")"

docker rm -f db client >/dev/null 2>&1 || true
docker run -d --name db --network my-network -e MYSQL_ROOT_PASSWORD=test123 mysql:8.0
docker run -d --name client --network my-network alpine:latest sleep 3600

sleep 10
docker exec client ping -c 2 db > "$SCEN_DIR/db_connectivity.txt"
docker exec client nslookup db >> "$SCEN_DIR/db_connectivity.txt"
docker network ls > "$SCEN_DIR/all_networks.txt"
docker network inspect bridge | grep -A 10 "Containers" >> "$SCEN_DIR/all_networks.txt"

echo "Container communication completed."
echo "  -> db_connectivity.txt"
echo "  -> all_networks.txt"