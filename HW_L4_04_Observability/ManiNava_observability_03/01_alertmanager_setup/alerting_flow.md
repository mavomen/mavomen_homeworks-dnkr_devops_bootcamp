# Alerting Flow - metric → alert → notification → action (01_alertmanager_setup)

## 1. Alert vs Notification (Prometheus/Alertmanager context)

| | Alert | Notification |
|---|---|---|
| What it is | An internal event inside Prometheus: a rule whose `expr` stayed true for the `for` duration → the alert goes `pending` → `firing`. Exists as a label set + annotations (`alertname`, `severity`, `instance`, `summary`...). | The message that actually reaches a human/system: an email, a Slack message, a PagerDuty incident, a webhook POST. Produced *from* alerts by Alertmanager. |
| Who owns it | Prometheus (rule engine) | Alertmanager (grouping/dedup/silence/inhibit → receiver) |
| Lifecycle | pending → firing → resolved | grouped, delayed by `group_wait`, repeated per `repeat_interval` |

Key consequence: many alerts can map to one notification (grouping), and an alert can
exist without any notification (silenced, inhibited, or unrouted). Conversely you can
never get a notification for a condition Prometheus never alerted on.

## 2. Role of each component

- Prometheus - the *detection* side: scrapes metrics, evaluates alerting rules every
  `evaluation_interval`, applies `for` (to filter flapping), and POSTs firing/resolved
  alerts to Alertmanager (`/api/v2/alerts`). Prometheus decides whether something is
  wrong; it deliberately knows nothing about where messages go.
- Alertmanager - the *notification logistics* side: receives alerts from any number
  of Prometheus replicas, then handles grouping (one message for 50 instances),
  deduplication (HA replicas), silencing (maintenance windows), inhibition
  (down-instance suppresses its dependent alerts), and routing via the route tree to
  receivers. It also handles retry/backoff per receiver.
- Receivers (Slack/Email/Webhook/PagerDuty...) - the *delivery* side: named
  configurations that know a concrete channel (webhook URL, SMTP, Slack API token).
  A route maps alerts to a receiver; the receiver turns an Alertmanager notification
  into a channel-specific message and delivers it.

Pipeline summary:

```
metric  →  Prometheus rule (expr + for)  →  alert (pending→firing)
        →  POST /api/v2/alerts  →  Alertmanager (group/silence/inhibit/route)
        →  receiver  →  notification (Slack/email/webhook)  →  human acts
```

## 3. Three real-world alerts and the action each requires

### 3.1 InstanceDown
```yaml
alert: InstanceDown
expr: up == 0
for: 2m
severity: critical
```
Meaning: Prometheus cannot scrape a target at all.
Action: treat as availability incident. Check whether the process/host is really
down vs a network/firewall issue vs the exporter crashing (`docker ps`, `systemctl
status`, `curl target:9100/metrics`), restart/redeploy the service, and if it was
decommissioned on purpose, remove the stale target/silence the alert. Escalate if the
service is customer-facing.

### 3.2 HighErrorRate
```yaml
alert: HighErrorRate
expr: sum(rate(http_requests_total{status=~"5.."}[5m]))
    / sum(rate(http_requests_total[5m])) * 100 > 2
for: 10m
severity: critical
```
Meaning: more than 2 % of requests are failing (5xx) for 10 minutes - user-visible
damage regardless of whether processes are "up".
Action: on-call opens the service dashboard, correlates the start time with recent
deploys/config changes, checks logs for the failing endpoints (`status=~"5.."`), and
rolls back the last deploy if correlated; if not deploy-related, look at dependency
health (DB, cache, upstreams) and error logs.

### 3.3 DiskAlmostFull
```yaml
alert: DiskAlmostFull
expr: (node_filesystem_avail_bytes{fstype!~"tmpfs|overlay"} /
       node_filesystem_size_bytes{fstype!~"tmpfs|overlay"}) * 100 < 10
for: 30m
severity: warning
```
Meaning: a filesystem has < 10 % free space (30 min headroom before it bites).
Action: find the growth source (`du -xsh /*` on the affected node, `docker system
df`, log rotation state), clean up (old images/logs/temp files) or extend the volume,
and verify the trend reversed. If it is a known-append-only data disk, plan a resize
instead of deleting.
