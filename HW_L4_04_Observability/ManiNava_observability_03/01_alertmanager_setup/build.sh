#!/bin/bash
source "$(dirname "$0")/../lib/common.sh"
cd "$SUB/01_alertmanager_setup" || exit 1
log "=== 01_alertmanager_setup start ==="

# Obs 2's section-03 stack uses the same container names and ports - take it down.
log "(cd ../HW_L4_03_Observability/.../03_monitoring_install_docker_2 && docker-compose down --remove-orphans)"
(cd "$SUB/../.." && \
  docker-compose -f HW_L4_03_Observability/ManiNava_observability_02/03_monitoring_install_docker_2/docker-compose.yml \
  -p 03_monitoring_install_docker_2 down --remove-orphans) >/dev/null 2>&1 || true

# Start the local webhook sink (receiver endpoint for alertmanager) if not running.
# stdout is discarded on purpose: the sink already appends each POST to
# webhook_sink_log.txt itself (redirecting stdout to the same file would double-log).
if ! (exec 3<>/dev/tcp/127.0.0.1/5001) 2>/dev/null; then
  log "start webhook sink on :5001"
  (cd "$SUB/03_notifications_routing" && nohup python3 webhook_sink.py 5001 \
    >/dev/null 2>>webhook_sink_log.txt &)
  sleep 1
fi

# Start the stack and capture its output exactly as the homework requires.
log "bash start_stack.sh &> start_stack_output.txt"
bash start_stack.sh &> start_stack_output.txt
log "=== 01_alertmanager_setup: stack started ==="

# Validate what Prometheus actually loaded (rules + alertmanager connection).
sleep 10
STATUS=alerts_pipeline_check.txt
{
  echo "### alerts_pipeline_check.txt - captured $(date -Is)"
} > "$STATUS"
run "loaded rules" "curl -s http://localhost:9090/api/v1/rules | jq -c '.data.groups[] | {name: .name, rules: [.rules[].name]}'" "$STATUS"
run "active alertmanager connection" \
  "curl -s http://localhost:9090/api/v1/alertmanagers | jq -c '.data.activeAlertmanagers[].url'" "$STATUS"
run "targets" "curl -s http://localhost:9090/api/v1/targets | jq '.data.activeTargets[] | {job: .labels.job, health: .health}'" "$STATUS"
run "promtool check config" \
  "docker exec prometheus promtool check config /etc/prometheus/prometheus.yml" "$STATUS"
run "amtool check alertmanager config" \
  "docker exec alertmanager amtool check-config /etc/alertmanager/alertmanager.yml" "$STATUS"

log "=== 01_alertmanager_setup done ==="
