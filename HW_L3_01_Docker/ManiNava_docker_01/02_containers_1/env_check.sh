#!/bin/bash

# ============================================================
# 2.2 - Working with environment variables
# ============================================================

SCEN_DIR="$(dirname "$(readlink -f "$0")")"

docker rm -f env-test >/dev/null 2>&1 || true
docker run -d --name env-test -e MY_VAR="Hello Docker" -e PORT=8080 alpine:latest sleep 3600

docker exec env-test env | grep -E 'MY_VAR|PORT' > "$SCEN_DIR/env_output.txt"
docker exec env-test sh -c 'echo "MY_VAR=$MY_VAR, PORT=$PORT"' >> "$SCEN_DIR/env_output.txt"

echo "Env check completed. Output saved to env_output.txt"