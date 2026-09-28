#!/bin/bash
# 6.2 - HAProxy load balancer (roundrobin) in front of the two backends
# NOTE: the PDF config keeps `daemon`, but the official haproxy image starts
# without -db, so daemon would fork and the container would stop instantly.
# We pass -db (foreground) at runtime; haproxy.cfg itself is unchanged.
SCEN_DIR="$(dirname "$(readlink -f "$0")")"
cd "$SCEN_DIR"

docker run -d --name haproxy-lb \
    -p 9000:9000 \
    --network hb-net \
    -v "$SCEN_DIR/haproxy.cfg:/usr/local/etc/haproxy/haproxy.cfg:ro" \
    haproxy:alpine \
    haproxy -f /usr/local/etc/haproxy/haproxy.cfg -db
sleep 3

# Load balancing test - 6 requests, expect roundrobin split
{
    echo "=== Load Balancing Test ==="
    for i in {1..6}; do
        echo "Request $i:"
        curl http://localhost:9000/
        echo ""
    done
} > haproxy_test.log

docker logs haproxy-lb | tail -n 20 > haproxy_logs.txt
docker stats --no-stream haproxy-lb backend1 backend2 > haproxy_stats.txt

docker stop haproxy-lb backend1 backend2
docker rm haproxy-lb backend1 backend2
docker network rm hb-net > /dev/null 2>&1 || true

echo "6.2 haproxy_test completed. Reports: haproxy_test.log, haproxy_logs.txt, haproxy_stats.txt"