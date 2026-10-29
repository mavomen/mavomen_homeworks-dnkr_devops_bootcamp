#!/bin/bash
# Live demos for routing + inhibition:
#  1. swap the running Alertmanager config to this folder's routing config,
#     POST synthetic critical/warning alerts, observe two different receivers;
#  2. swap to alertmanager_inhibit.yml, POST synthetic alerts, observe that
#     HighCPUUsage is suppressed only for the instance that is "down";
#  3. restore the original section-01 config afterwards.
source "$(dirname "$0")/../lib/common.sh"
cd "$SUB/03_notifications_routing" || exit 1
log "=== 03_notifications_routing start (live routing + inhibition demos) ==="

SETUP="$SUB/01_alertmanager_setup"

amtool_check() {
  run "amtool check-config (active config)" \
    "docker exec alertmanager amtool check-config /etc/alertmanager/alertmanager.yml" "$1"
}

# ---------------- Part 1: severity routing ----------------
cp "$SETUP/alertmanager.yml" "$SETUP/alertmanager.yml.orig"
cp ./alertmanager.yml "$SETUP/alertmanager.yml"
log "swap in 03_notifications_routing/alertmanager.yml"
# Fresh notification state: the nflog (notification history) lives in an
# anonymous Docker volume (the prom/alertmanager image declares VOLUME
# /alertmanager) and docker-compose up --force-recreate RE-ATTACHES the same
# volume, so a recreate does NOT reset repeat_interval (4h) history - an
# unchanged firing set from an earlier run is silently skipped by the DedupStage
# (no webhook call, no error). rm -f -s -v removes the container WITH its
# anonymous volume; the following up -d starts a truly fresh one.
(cd "$SETUP" && docker-compose rm -f -s -v alertmanager) >/dev/null 2>&1
(cd "$SETUP" && docker-compose up -d alertmanager) >/dev/null 2>&1
sleep 3

ROUTING_OUT=routing_demo_output.txt
{
  echo "### routing_demo_output.txt - captured $(date -Is)"
  echo "### config: alertmanager.yml (this folder), loaded into the section-01 stack"
  echo "### scenario: POST synthetic InstanceDown(critical) + HighCPUUsage(warning)"
  echo
  echo "## amtool validation of the active config"
} > "$ROUTING_OUT"
amtool_check "$ROUTING_OUT"

STARTS=$(date -u +%Y-%m-%dT%H:%M:%SZ)
ENDS=$(date -u -d '+3 minutes' +%Y-%m-%dT%H:%M:%SZ)
CRIT=$(jq -nc --arg s "$STARTS" --arg e "$ENDS" \
  '[{labels:{alertname:"InstanceDown",severity:"critical",instance:"node_exporter:9100",team:"platform"},annotations:{summary:"synthetic InstanceDown (routing demo)"},startsAt:$s,endsAt:$e}]')
WARN=$(jq -nc --arg s "$STARTS" --arg e "$ENDS" \
  '[{labels:{alertname:"HighCPUUsage",severity:"warning",instance:"node_exporter:9100",team:"platform"},annotations:{summary:"synthetic HighCPUUsage (routing demo)"},startsAt:$s,endsAt:$e}]')
log "POST synthetic critical + warning alerts"
curl -s -X POST -H 'Content-Type: application/json' -d "$CRIT" http://localhost:9093/api/v2/alerts >/dev/null
curl -s -X POST -H 'Content-Type: application/json' -d "$WARN" http://localhost:9093/api/v2/alerts >/dev/null

echo "Waiting 40s for group_wait (30s) and notification dispatch..." >> "$ROUTING_OUT"
sleep 40

run "alertmanager alert states" \
  "curl -s http://localhost:9093/api/v2/alerts | jq -c '.[] | {alertname: .labels.alertname, severity: .labels.severity, status: .status.state}'" "$ROUTING_OUT"
{
  echo
  echo "## webhook sink log (expect: InstanceDown -> /stdout, HighCPUUsage -> /logfile)"
  echo "### (full log: webhook_sink_log.txt)"
} >> "$ROUTING_OUT"
tail -n 4 "$SUB/03_notifications_routing/webhook_sink_log.txt" >> "$ROUTING_OUT"

# Clear the sink log so Part 2's evidence tail contains only inhibition-demo lines.
echo "## sink log cleared before inhibition demo ($(date -Is))" \
  > "$SUB/03_notifications_routing/webhook_sink_log.txt"

# ---------------- Part 2: inhibition ----------------
cp ./alertmanager_inhibit.yml "$SETUP/alertmanager.yml"
log "swap in 03_notifications_routing/alertmanager_inhibit.yml"
# Fresh notification state again (Part 1 already notified the same groups; the
# rm -f -s -v pattern is the only reliable reset - see the comment in Part 1).
(cd "$SETUP" && docker-compose rm -f -s -v alertmanager) >/dev/null 2>&1
(cd "$SETUP" && docker-compose up -d alertmanager) >/dev/null 2>&1
sleep 3

INHIB_OUT=inhibition_demo_output.txt
{
  echo "### inhibition_demo_output.txt - captured $(date -Is)"
  echo "### config: alertmanager_inhibit.yml (InstanceDown inhibits HighCPUUsage per instance)"
  echo "### scenario: InstanceDown{instance=node_exporter:9100} + HighCPUUsage{node_exporter:9100}"
  echo "###           + HighCPUUsage{other-node:9100} (control group)"
  echo
  echo "## amtool validation of the active config"
} > "$INHIB_OUT"
amtool_check "$INHIB_OUT"

STARTS=$(date -u +%Y-%m-%dT%H:%M:%SZ)
ENDS=$(date -u -d '+3 minutes' +%Y-%m-%dT%H:%M:%SZ)
INH=$(jq -nc --arg s "$STARTS" --arg e "$ENDS" \
  '[{labels:{alertname:"InstanceDown",severity:"critical",instance:"node_exporter:9100",team:"platform"},annotations:{summary:"synthetic InstanceDown (inhibition demo)"},startsAt:$s,endsAt:$e},
    {labels:{alertname:"HighCPUUsage",severity:"warning",instance:"node_exporter:9100",team:"platform"},annotations:{summary:"synthetic HighCPUUsage same instance (inhibition demo)"},startsAt:$s,endsAt:$e},
    {labels:{alertname:"HighCPUUsage",severity:"warning",instance:"other-node:9100",team:"platform"},annotations:{summary:"synthetic HighCPUUsage different instance (control)"},startsAt:$s,endsAt:$e}]')
log "POST synthetic alerts for inhibition demo (source + same-instance target + control)"
curl -s -X POST -H 'Content-Type: application/json' -d "$INH" http://localhost:9093/api/v2/alerts >/dev/null

echo "Waiting 40s for group_wait (30s) and the inhibition pass..." >> "$INHIB_OUT"
sleep 40

run "alertmanager alert states (suppressed vs active)" \
  "curl -s http://localhost:9093/api/v2/alerts | jq -c '.[] | {alertname: .labels.alertname, instance: .labels.instance, status: .status.state, inhibitedBy: .status.inhibitedBy}'" "$INHIB_OUT"
{
  echo
  echo "## webhook sink log (expect: InstanceDown -> /stdout, only other-node HighCPUUsage -> /logfile)"
} >> "$INHIB_OUT"
tail -n 4 "$SUB/03_notifications_routing/webhook_sink_log.txt" >> "$INHIB_OUT"

# ---------------- Part 3: restore section-01 config ----------------
mv "$SETUP/alertmanager.yml.orig" "$SETUP/alertmanager.yml"
log "restore original 01_alertmanager_setup/alertmanager.yml"
# Same proven reset pattern as Parts 1/2: stop+remove (with the anonymous
# volume), then start the container again so it loads the restored config with
# fresh notification state.
(cd "$SETUP" && docker-compose rm -f -s -v alertmanager) >/dev/null 2>&1
(cd "$SETUP" && docker-compose up -d alertmanager) >/dev/null 2>&1
sleep 3
curl -s http://localhost:9093/-/ready >/dev/null && echo "alertmanager ready (restored config)"

log "=== 03_notifications_routing done ==="
