#!/bin/bash

# ============================================================
# 5.3 - Network isolation
# ============================================================

SCEN_DIR="$(dirname "$(readlink -f "$0")")"

docker network create network-a >/dev/null 2>&1 || true
docker network create network-b >/dev/null 2>&1 || true
docker rm -f container-a container-b >/dev/null 2>&1 || true

docker run -d --name container-a --network network-a alpine:latest sleep 3600
docker run -d --name container-b --network network-b alpine:latest sleep 3600

# ping must fail: different networks
docker exec container-a ping -c 2 container-b 2>&1 > "$SCEN_DIR/isolation_test.txt" || echo "Ping failed as expected" >> "$SCEN_DIR/isolation_test.txt"

# connect container-b to network-a -> now reachable
docker network connect network-a container-b
docker exec container-a ping -c 2 container-b >> "$SCEN_DIR/isolation_test.txt"

docker network inspect network-a | grep -A 5 "Containers" > "$SCEN_DIR/network_a_containers.txt"
docker network inspect bridge | grep -A 10 "IPAM" > "$SCEN_DIR/bridge_network_info.txt"

echo "Network isolation completed."
echo "  -> isolation_test.txt"
echo "  -> network_a_containers.txt"
echo "  -> bridge_network_info.txt"