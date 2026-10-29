#!/bin/bash
source "$(dirname "$0")/../lib/common.sh"
cd "$SUB/02_alert_rules_basics" || exit 1
log "=== 02_alert_rules_basics start ==="

STATUS=alerts_validation.txt
{
  echo "### alerts_validation.txt - promtool validation of the rule files ($(date -Is))"
} > "$STATUS"
run "promtool check rules alerts_basic.yml" \
  "promtool check rules alerts_basic.yml" "$STATUS"
run "promtool check rules alerts_slo.yml" \
  "promtool check rules alerts_slo.yml" "$STATUS"
# Live-load both rule files into the running section-01 Prometheus for an end-to-end
# check of parse + template rendering (mounted read-only via docker).
run "promtool check rules inside container (alerts.yml copy)" \
  "docker exec prometheus promtool check rules /etc/prometheus/alerts.yml" "$STATUS"

log "=== 02_alert_rules_basics done ==="
