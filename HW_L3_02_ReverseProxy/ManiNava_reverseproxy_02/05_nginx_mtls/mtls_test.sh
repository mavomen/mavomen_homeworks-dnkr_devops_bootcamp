#!/bin/bash
# 5.2 - mTLS nginx container: request without client cert must fail,
#       request with client cert must succeed.
# Appends the 5.3 chain-verification output to mtls_explanation.txt.
SCEN_DIR="$(dirname "$(readlink -f "$0")")"
cd "$SCEN_DIR"

docker run -d --name nginx-mtls \
    -p 9443:9443 \
    -v "$SCEN_DIR/nginx_mtls.conf:/etc/nginx/nginx.conf:ro" \
    -v "$SCEN_DIR:/etc/nginx/mtls:ro" \
    nginx:alpine
sleep 2

# Test without client certificate (should fail)
{
    echo "=== Test without client certificate ==="
    curl -k https://localhost:9443/ -v 2>&1 | grep -E 'HTTP|SSL|certificate'
} > mtls_test.txt

# Test with client certificate (should succeed)
{
    echo -e "\n=== Test with client certificate ==="
    curl -k https://localhost:9443/ \
        --cert client/client.crt \
        --key client/client.key \
        -v 2>&1 | grep -E 'HTTP|SSL|certificate'
} >> mtls_test.txt

docker logs nginx-mtls | tail -n 10 > mtls_logs.txt

# 5.3 - evidence: verify the client chain against our CA
{
    echo
    echo "=== openssl verify -CAfile ca/rootCA.crt client/client.crt ==="
    openssl verify -CAfile ca/rootCA.crt client/client.crt
} >> mtls_explanation.txt

docker stop nginx-mtls
docker rm nginx-mtls

echo "5.2 mtls_test completed. Reports: mtls_test.txt, mtls_logs.txt (5.3 verify appended to mtls_explanation.txt)"