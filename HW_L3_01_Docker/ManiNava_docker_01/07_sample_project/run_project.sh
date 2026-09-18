#!/bin/bash

# ============================================================
# 7.1 - Sample project: build, run & test
# ============================================================

SCEN_DIR="$(dirname "$(readlink -f "$0")")"
cd "$SCEN_DIR" || exit 1

docker-compose up -d --build
sleep 5
curl --retry 3 --retry-connrefused --retry-delay 1 http://localhost:3000 > frontend_test.html
curl --retry 3 --retry-connrefused --retry-delay 1 http://localhost:3000/api > api_test.json
docker-compose ps > project_status.txt
docker-compose logs --tail 20 > project_logs.txt

echo "Project run completed."
echo "  -> frontend_test.html"
echo "  -> api_test.json"
echo "  -> project_status.txt"
echo "  -> project_logs.txt"