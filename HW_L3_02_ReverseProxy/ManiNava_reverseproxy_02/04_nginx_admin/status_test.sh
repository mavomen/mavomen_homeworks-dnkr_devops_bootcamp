#!/bin/bash
# 4.1 - Enable the nginx stub_status module and generate some traffic
SCEN_DIR="$(dirname "$(readlink -f "$0")")"
cd "$SCEN_DIR"

docker run -d --name nginx-status \
    -p 8090:80 \
    -v "$SCEN_DIR/nginx_status.conf:/etc/nginx/nginx.conf:ro" \
    nginx:alpine
sleep 2

# generate some traffic so the counters are non-zero
for i in {1..5}; do
    curl http://localhost:8090/ > /dev/null
done

curl http://localhost:8090/basic_status > status_output.txt
docker logs nginx-status | tail -n 15 > status_logs.txt

docker stop nginx-status
docker rm nginx-status

echo "4.1 status_test completed. Reports: status_output.txt, status_logs.txt"