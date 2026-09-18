#!/bin/bash

# ============================================================
# 3.1 - Working with Logs
# ============================================================

SCEN_DIR="$(dirname "$(readlink -f "$0")")"

docker rm -f log-test >/dev/null 2>&1 || true
docker run -d --name log-test alpine:latest sh -c 'for i in $(seq 1 10); do echo "Log line $i"; sleep 1; done; sleep 3600'

sleep 12
docker logs log-test > "$SCEN_DIR/all_logs.txt"
docker logs --tail 5 log-test > "$SCEN_DIR/last_5_logs.txt"
docker logs --since 5s log-test > "$SCEN_DIR/recent_logs.txt"

echo "Log operations completed."
echo "  -> all_logs.txt"
echo "  -> last_5_logs.txt"
echo "  -> recent_logs.txt"