#!/bin/bash

# ============================================================
# 3.3 - Resource Limits (memory & CPU)
# ============================================================

SCEN_DIR="$(dirname "$(readlink -f "$0")")"

docker rm -f limited-container >/dev/null 2>&1 || true
docker run -d --name limited-container --memory="128m" --cpus="0.5" alpine:latest sleep 3600

sleep 2
docker stats --no-stream limited-container > "$SCEN_DIR/resource_stats.txt"
docker inspect limited-container | grep -A 5 "Memory\|CpuShares" >> "$SCEN_DIR/resource_stats.txt"

echo "Resource check completed. Output saved to resource_stats.txt"