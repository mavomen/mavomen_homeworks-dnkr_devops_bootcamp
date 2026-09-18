#!/bin/bash

# ============================================================
# 3.2 - Restart Policies
# ============================================================

SCEN_DIR="$(dirname "$(readlink -f "$0")")"

docker rm -f always-restart unless-stopped no-restart >/dev/null 2>&1 || true

docker run -d --name always-restart --restart always alpine:latest sleep 5
docker run -d --name unless-stopped --restart unless-stopped alpine:latest sleep 5
docker run -d --name no-restart alpine:latest sleep 5

sleep 7
# docker ps --format '{{.RestartCount}}' was removed in Docker 29.x ->
# read RestartCount per-container via inspect instead
docker inspect -f '{{.Name}} restarts={{.RestartCount}} status={{.State.Status}}' \
  always-restart unless-stopped no-restart > "$SCEN_DIR/restart_status.txt"
docker inspect always-restart | grep -A 2 "RestartPolicy" >> "$SCEN_DIR/restart_status.txt"

echo "Restart policy test completed. Output saved to restart_status.txt"