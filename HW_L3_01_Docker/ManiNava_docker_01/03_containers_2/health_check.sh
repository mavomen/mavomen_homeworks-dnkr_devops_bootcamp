#!/bin/bash

# ============================================================
# 3.4 - Health Checks
# ============================================================

SCEN_DIR="$(dirname "$(readlink -f "$0")")"

docker rm -f health-test >/dev/null 2>&1 || true
docker run -d --name health-test --health-cmd="curl -f http://localhost:80 || exit 1" --health-interval=5s --health-timeout=3s --health-retries=3 nginx:alpine

sleep 10
docker inspect --format='{{.State.Health.Status}}' health-test > "$SCEN_DIR/health_status.txt"
docker inspect --format='{{json .State.Health}}' health-test | python3 -m json.tool > "$SCEN_DIR/health_details.txt"
docker ps --filter "name=health-test" --format "table {{.Names}}\t{{.Status}}" >> "$SCEN_DIR/health_status.txt"

echo "Health check completed."
echo "  -> health_status.txt"
echo "  -> health_details.txt"