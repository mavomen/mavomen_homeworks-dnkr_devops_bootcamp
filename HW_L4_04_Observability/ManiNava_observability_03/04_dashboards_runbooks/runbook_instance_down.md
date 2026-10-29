# Runbook - InstanceDown (04_dashboards_runbooks)

```yaml
# summary card
alert: InstanceDown
expr: up == 0
for: 2m
severity: critical
coverage: every Prometheus scrape target (in this stack: prometheus:9090,
          node_exporter:9100 - in production: all nodes/exporters/services)
```

## 1. Context

What does this alert mean?
Prometheus failed to scrape the target's `/metrics` endpoint for every attempt in the
last 2 minutes. Prometheus does *not* know *why* - the alert only says "I cannot see
you anymore". It covers the visibility path, which is why the first job is always to
distinguish three cases:

1. The service/host is actually down (crash, OOM-kill, node reboot) - real outage.
2. The service is up but the exporter/metrics endpoint is broken - blind spot,
   host may still be serving users.
3. The path is broken (DNS, network, firewall, TLS, Prometheus itself) -
   monitoring-plane problem; users may be unaffected.

Which service/system does it cover? Any target in the `up` metric. The
`instance` label names the target (`node_exporter:9100` here), the `job` label the
scrape job. Everything downstream (dashboards, alerts from that host) is blind while
it fires - a monitoring blind spot is itself an incident even if users see nothing.

Expected impact: depends on case 1-3; treat as availability incident until proven
otherwise. It pages (critical); do not silence before triage.

## 2. On-call steps

### 2.1 In Grafana (the InstanceDown row of "Platform Overview")

- Target status panel - confirm the alert is still firing and *since when*
  (`activeAt` in the alert; Grafana annotation for the firing event).
- Blast radius table (`up` by instance) - is it one instance or many?
  Many at once → network/datacenter/Prometheus problem, not a single host.
- Last-seen panel - `time() - timestamp(up{...})`: how long has data been gone?
- Host vitals panels - if CPU/memory/disk graphs *continued* after the alert
  started, the host is alive (case 2 or 3). If all series froze at the same
  timestamp, the host/exporter really died (case 1).
- Scrape pipeline panels - `scrape_duration_seconds` and
  `prometheus_target_scrapes_*`: timeouts suggest network/overload; instant
  connection-refused suggests process down.

### 2.2 Patterns to look for

- Freeze at a single timestamp across all metrics of that host → sudden death
  (crash/power/agent stop).
- Gradual degradation before (rising iowait, memory, load) → resource exhaustion
  death, check the hours before.
- Alert started right after a deploy/restart/config change → change-induced;
  roll back first, investigate later.
- Other targets on the same host/network down too → shared-cause incident.

### 2.3 CLI commands (adjust names to the environment)

```bash
# Is the process/container actually running?
docker ps -a | grep node_exporter          # containerized envs
kubectl get pod -n monitoring -o wide      # k8s envs
systemctl status node_exporter             # systemd hosts
ps aux | grep node_exporter

# Is the endpoint locally reachable from the target host?
curl -m 3 http://localhost:9100/metrics | head
journalctl -u node_exporter --since -30m   # exporter logs
docker logs --since 30m node_exporter

# Is it reachable from the Prometheus host (path check)?
ping -c3 <target-host>                     # ICMP reachable?
traceroute <target-host>                   # where does the path break?
curl -m 3 http://<target-host>:9100/metrics | head   # from Prometheus host
dig <target-host>                          # DNS resolution

# In this homework's stack specifically:
docker inspect -f '{{.State.Status}} {{.State.StartedAt}}' node_exporter
docker logs --tail 20 node_exporter
```

## 3. Decision tree

```
InstanceDown fired
│
├─ Is anything else down too (many instances)?
│   ├─ YES → network/DC/Prometheus-wide incident → networking runbook,
│   │        page infra lead, check Prometheus itself (case 3)
│   └─ NO ↓
├─ Can you reach the target from the Prometheus host?
│   ├─ NO → network path / firewall / host down
│   │        ├─ ping fails → host down or network partition →
│   │        │                 hosting/node runbook (case 1 or 3)
│   │        └─ ping OK, port closed → exporter crashed or firewalled →
│   │                                  restart exporter (case 2)
│   └─ YES (curl works from target host) → scrape-path/config problem:
│        ├─ Was the target just decommissioned/renamed?
│        │    ├─ YES → remove stale target / update prometheus.yml,
│        │    │        silence the alert, close as planned change
│        │    └─ NO ↓
│        └─ Is the exporter process alive?
│             ├─ NO → restart it (docker start / systemctl restart),
│             │        if it crash-loops → capture logs, escalate to owner
│             └─ YES → check timeouts/TLS/target labels in prometheus.yml;
│                      if config was changed → fix + POST /-/reload
└─ After recovery: verify `up == 1`, confirm the alert resolved in
   Alertmanager (resolved notification), write a short postmortem note.
```

## 4. Links

- `/runbooks/networking.md` - traceroute/firewall/DNS triage when the path is broken
- `/runbooks/exporter_node.md` - node_exporter restart & crash-loop handling
- `/runbooks/disk_full.md` - if vitals show the host died from resource exhaustion
- `/runbooks/incident_severity.md` - when to escalate to SEV-2/SEV-1, comms channels
- Dashboard: Platform Overview - Alerts (Grafana, row 1 "Availability")
- Alert definition: `01_alertmanager_setup/alerts.yml` (this repo)
- This runbook is linked from the alert itself via `runbook_url` (see below)

## 5. Making the runbook clickable - `runbook_url` annotation

Alertmanager/Grafana render the `runbook_url` annotation as a clickable link in
the UI and include it in webhook payloads - the on-call goes from page to procedure
in one click:

```yaml
# 01_alertmanager_setup/alerts.yml - already applied in this delivery:
- alert: InstanceDown
  expr: up == 0
  for: 2m
  labels:
    severity: critical
    team: platform
  annotations:
    summary: "Instance {{ $labels.instance }} is down"
    description: "Prometheus target {{ $labels.instance }} (job={{ $labels.job }}) has been down for more than 2 minutes."
    runbook_url: "https://runbooks.example.com/runbooks/instance_down.md"
```

- Prometheus → Alertmanager: annotations travel with the alert; the webhook
  notification payload contains `annotations.runbook_url` (visible in
  `webhook_sink_log.txt` during the InstanceDown demo).
- Grafana alerting / Alertmanager UI: both render `runbook_url` as a link
  button on the alert detail page.
- Why an annotation and not a label: annotations hold longer free-form values
  (URLs, descriptions) without touching the label dimensionality - labels are for
  *routing/grouping*, annotations for *context*.
- Apply with a config reload: `curl -X POST http://localhost:9090/-/reload`
  (this delivery already reloaded; verify via
  `curl -s localhost:9090/api/v1/rules | jq '.. | .annotations?.runbook_url? // empty'`).
- Keep `runbook_url` values pointing at a versioned source (wiki permalink or the
  repo path of this file) so the link never rots.
