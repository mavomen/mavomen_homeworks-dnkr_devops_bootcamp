#!/bin/bash
source "$(dirname "$0")/../lib/common.sh"
cd "$SUB/03_monitoring_install_docker_2" || exit 1
log "=== 03_monitoring_install_docker_2 start ==="

# Section 02's standalone Prometheus uses the same container name and host port 9090 -
# take it down before starting the full stack (its own named volume is preserved).
log "(cd 02_monitoring_install_docker_1 && docker-compose down --remove-orphans)"
(cd "$SUB/02_monitoring_install_docker_1" && docker-compose down --remove-orphans) >/dev/null 2>&1 || true

log "bash start_monitoring_stack.sh"
bash start_monitoring_stack.sh || true

# Give targets one scrape interval to come up before capturing their health.
sleep 15

STATUS=stack_status.txt
{
  echo "### stack_status.txt - captured $(date -Is)"
} > "$STATUS"
run "docker-compose ps" "docker-compose ps" "$STATUS"
run "docker network ls | grep monitoring" "docker network ls | grep monitoring" "$STATUS"
run "docker volume ls | grep -E 'prometheus|grafana'" \
  "docker volume ls | grep -E 'prometheus|grafana'" "$STATUS"
run "targets health via API" \
  "curl -s http://localhost:9090/api/v1/targets | jq '.data.activeTargets[] | {job: .job, health: .health}'" \
  "$STATUS"

log "=== 03_monitoring_install_docker_2 done ==="
