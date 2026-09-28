#!/bin/bash
# 3.2 - HTTPS container with the self-signed certs (volume-mounted)
# Appends the 3.3 port-mapping evidence to http_vs_https.txt (docker port + ss)
SCEN_DIR="$(dirname "$(readlink -f "$0")")"
cd "$SCEN_DIR"

docker run -d --name nginx-https \
    -p 8443:443 \
    -v "$SCEN_DIR/nginx_https.conf:/etc/nginx/nginx.conf:ro" \
    -v "$SCEN_DIR/certs:/etc/nginx/certs:ro" \
    nginx:alpine
sleep 2

{
    echo "=== curl -k https://localhost:8443/status ==="
    curl -k https://localhost:8443/status
    echo
    echo "=== server certificate validity dates ==="
    openssl s_client -connect localhost:8443 -servername demo.local < /dev/null 2>&1 | \
        openssl x509 -noout -dates
} > https_response.txt

docker logs nginx-https | tail -n 10 > https_logs.txt

# 3.3 - evidence: port mapping of the https container while it is running
{
    echo
    echo "=== docker port nginx-https ==="
    docker port nginx-https
    echo
    echo "=== ss -tuln | grep ':8443' ==="
    ss -tuln | grep ':8443'
} >> http_vs_https.txt

docker stop nginx-https
docker rm nginx-https

echo "3.2 https_test completed. Reports: https_response.txt, https_logs.txt (3.3 evidence appended to http_vs_https.txt)"