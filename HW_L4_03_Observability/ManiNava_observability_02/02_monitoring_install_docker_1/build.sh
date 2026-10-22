#!/bin/bash
source "$(dirname "$0")/../lib/common.sh"
cd "$SUB/02_monitoring_install_docker_1" || exit 1
log "=== 02_monitoring_install_docker_1 start ==="

# Bring the stack up exactly as the homework start script does.
log "bash start_prometheus.sh"
bash start_prometheus.sh || true

# Required status outputs (per homework) -> prometheus_docker_status.txt
STATUS=prometheus_docker_status.txt
{
  echo "### prometheus_docker_status.txt - captured $(date -Is)"
} > "$STATUS"
run "docker ps | grep prometheus" "docker ps | grep prometheus" "$STATUS"
run "docker logs prometheus | tail -20" "docker logs prometheus | tail -20" "$STATUS"
run "active config via API" "curl -s http://localhost:9090/api/v1/status/config | jq '.data.yaml' | head -20" "$STATUS"
run "docker volume ls | grep prometheus" "docker volume ls | grep prometheus" "$STATUS"

log "=== 02_monitoring_install_docker_1 done ==="
