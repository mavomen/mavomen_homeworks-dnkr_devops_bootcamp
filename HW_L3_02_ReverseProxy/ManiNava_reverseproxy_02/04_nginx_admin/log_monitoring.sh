#!/bin/bash
# 4.2 - Container log monitoring: latest, errors, recent (time-filtered)
SCEN_DIR="$(dirname "$(readlink -f "$0")")"
cd "$SCEN_DIR"

docker run -d --name nginx-logs \
    -p 8091:80 \
    nginx:alpine
sleep 2

# generate traffic (including a 404)
curl http://localhost:8091/ > /dev/null
curl http://localhost:8091/nonexistent 2>&1 > /dev/null

# extract logs
docker logs nginx-logs --tail 20 > latest_logs.txt
docker logs nginx-logs 2>&1 | grep -i error > error_logs.txt || echo "No errors found" > error_logs.txt

# logs from the last minute (real-time window)
docker logs nginx-logs --since 1m > recent_logs.txt

docker stop nginx-logs
docker rm nginx-logs

echo "4.2 log_monitoring completed. Reports: latest_logs.txt, error_logs.txt, recent_logs.txt"