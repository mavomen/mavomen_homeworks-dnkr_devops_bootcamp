#!/bin/bash
source "$(dirname "$0")/../lib/common.sh"
cd "$SUB/06_promql_queries_1" || exit 1
log "=== 06_promql_queries_1 start (uses the running 03 stack) ==="

# NOTE: curl treats [5m] in the raw URL as a glob pattern and fails with exit code 3
# (silently under -s). The queries below are URL-encoded ([ -> %5B, ] -> %5D), which
# is why the URLs differ from the homework's literal form.

RESULTS=query_results.txt
{
  echo "### query_results.txt - outputs from Prometheus API (running stack from"
  echo "### 03_monitoring_install_docker_2, http://localhost:9090)"
  echo "### captured $(date -Is)"
  echo "### NOTE: 'curl -s .../query?query=rate(...[5m])' fails with curl exit code 3"
  echo "### (curl URL-globbing on []). URLs below use %5B/%5D encoding instead."
  echo
} > "$RESULTS"

run "instant query: up" \
  "curl -s 'http://localhost:9090/api/v1/query?query=up' | jq" "$RESULTS"

run "range-rate query: rate(prometheus_http_requests_total[5m])" \
  "curl -s 'http://localhost:9090/api/v1/query?query=rate(prometheus_http_requests_total%5B5m%5D)' | jq" "$RESULTS"

run "aggregation: sum(prometheus_http_requests_total) by (handler)" \
  "curl -s 'http://localhost:9090/api/v1/query?query=sum(prometheus_http_requests_total)%20by%20(handler)' | jq" "$RESULTS"

log "=== 06_promql_queries_1 done ==="
