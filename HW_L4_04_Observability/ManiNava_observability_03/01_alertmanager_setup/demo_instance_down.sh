#!/bin/bash
# Demonstrates the full metric -> alert -> notification path:
# stop node_exporter -> up==0 -> InstanceDown fires (for: 2m) -> Alertmanager
# groups it (group_wait 30s) -> webhook sink receives the notification.
source "$(dirname "$0")/../lib/common.sh"
cd "$SUB/01_alertmanager_setup" || exit 1
log "=== demo_instance_down start ==="

# Fresh notification state before the demo: the nflog (notification history)
# lives in an anonymous Docker volume (the prom/alertmanager image declares
# VOLUME /alertmanager) and docker-compose up --force-recreate re-attaches the
# SAME volume to the recreated container, so repeat_interval (4h) history
# survives a recreate and would silently suppress a repeated notification of the
# same alert-label set (DedupStage skip: no webhook call, no error). The only
# reliable reset is rm -f -s -v (removes the container WITH its anonymous
# volume); the following up -d starts a truly fresh one.
docker-compose rm -f -s -v alertmanager >/dev/null 2>&1
docker-compose up -d alertmanager >/dev/null 2>&1
sleep 3

OUT=instance_down_demo_output.txt
{
  echo "### instance_down_demo_output.txt - captured $(date -Is)"
  echo "### scenario: docker stop node_exporter -> InstanceDown (expr: up == 0, for: 2m)"
  echo
  echo "## before: node_exporter target health"
} > "$OUT"
run "up query before" \
  "curl -s 'http://localhost:9090/api/v1/query?query=up%7Bjob%3D%22node_exporter%22%7D' | jq -c '.data.result[] | {metric, value}'" "$OUT"

echo "Stopping node_exporter..." | tee -a "$OUT"
log "docker stop node_exporter"
docker stop node_exporter >/dev/null

# Poll Prometheus until InstanceDown is firing (for: 2m + evaluation interval margin).
echo "Waiting for InstanceDown to fire (expr up==0, for: 2m)..." | tee -a "$OUT"
fired=""
for _ in $(seq 1 28); do
  sleep 10
  state=$(curl -s http://localhost:9090/api/v1/alerts | jq -r \
    '.data.alerts[] | select(.labels.alertname=="InstanceDown") | .state' | head -1)
  echo "  $(date -Is) InstanceDown state: ${state:-none}" >> "$OUT"
  if [ "$state" = "firing" ]; then fired=yes; break; fi
done

if [ -z "$fired" ]; then
  echo "InstanceDown never reached firing state" | tee -a "$OUT"
  docker start node_exporter >/dev/null
  exit 1
fi

run "prometheus alerts after firing" \
  "curl -s http://localhost:9090/api/v1/alerts | jq -c '.data.alerts[] | {alertname: .labels.alertname, state, value: .value, activeAt: .activeAt}'" "$OUT"
run "alertmanager received the alert" \
  "curl -s http://localhost:9093/api/v2/alerts | jq -c '.[] | {labels: {alertname: .labels.alertname, severity: .labels.severity, instance: .labels.instance}, status: .status.state}'" "$OUT"

# Alertmanager group_wait (default 30s) before the notification goes out.
echo "Waiting 35s for the Alertmanager group_wait window..." | tee -a "$OUT"
sleep 35

{
  echo
  echo "## webhook sink log tail (notification actually delivered)"
  echo "### (full sink log: ../03_notifications_routing/webhook_sink_log.txt)"
} >> "$OUT"
tail -n 3 "$SUB/03_notifications_routing/webhook_sink_log.txt" >> "$OUT" 2>/dev/null

# Heal the stack: bring node_exporter back so the alert resolves.
echo "Restarting node_exporter..." | tee -a "$OUT"
log "docker compose up -d node_exporter (heal)"
docker-compose up -d node_exporter >/dev/null 2>&1
sleep 20
run "up query after restart" \
  "curl -s 'http://localhost:9090/api/v1/query?query=up%7Bjob%3D%22node_exporter%22%7D' | jq -c '.data.result[] | {metric, value}'" "$OUT"

log "=== demo_instance_down done ==="
echo "Demo complete, evidence in $OUT"
