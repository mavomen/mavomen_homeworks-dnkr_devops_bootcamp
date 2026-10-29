# Routing Explanation (03_notifications_routing)

`alertmanager.yml` in this folder routes by severity:
`critical → stdout-receiver`, `warning → logfile-receiver`. Both receivers are
local webhook endpoints served by `webhook_sink.py` (host, port 5001) - reachable
from the Alertmanager container via `host.docker.internal` (`host-gateway` in the
compose file). In production these two receivers would be real Slack/Email/PagerDuty
configs; the sink proves the routing logic without needing credentials.

## 1. Grouping settings in this config and why these numbers

```yaml
route:
  group_by: ['alertname', 'severity']
  group_wait: 30s
  group_interval: 5m
  repeat_interval: 4h
```

- `group_by: ['alertname','severity']` - one notification per (alertname, severity)
  combination. If 30 nodes lose CPU metrics at once, the on-call gets *one*
  HighCPUUsage warning listing all 30, not 30 messages. Splitting by severity keeps
  critical traffic (pager) separate from warning traffic (log/ticket).
- `group_wait: 30s` - how long Alertmanager waits after the *first* alert of a new
  group before notifying, to collect more members of the same group. 30 s is short
  enough not to delay real incidents meaningfully, long enough to batch bursts
  (a rolling restart that drops several targets within half a minute arrives as one
  message).
- `group_interval: 5m` - minimum time between notifications *for the same group*
  (after the first send). If more alerts join the group, they wait up to 5 min for the
  next batch instead of trickling in. 5 min matches a typical triage rhythm; anything
  shorter re-spams the channel, anything longer hides new members.
- `repeat_interval: 4h` - how often an *unresolved* alert group re-notifies.
  4 h: a critical still firing re-pages every 4 h (loud enough not to be forgotten,
  not so often that it becomes wallpaper). For a PagerDuty-style escalation you would
  lower this for `critical` (e.g. 1 h) per-sub-route.

The numbers are deliberate defaults for a small team; the important discipline is that
they are *explicit* and reviewed with the on-call process (see
`05_alert_fatigue_maintenance/alerting_maintenance_checklist.md`).

## 2. Step-by-step: what happens when `InstanceDown` with `severity=critical` fires

Scenario: node_exporter on `node-7` stops responding; Prometheus's `InstanceDown`
(`up == 0`, `for: 2m`) reaches `firing` and is POSTed to Alertmanager.

1. Ingestion: Alertmanager records the alert (labels: `alertname=InstanceDown`,
   `severity=critical`, `instance=node-7:9100`, `team=platform`); state `active`.
2. Route tree evaluation (top to bottom):
   - root route: `group_by=['alertname','severity']`, timings as above, default
     receiver `stdout-receiver`.
   - sub-route 1 `matchers: severity = "critical"` → matches → receiver
     `stdout-receiver`. Sub-route 2 (`severity = "warning"`) is never evaluated for
     this alert. Inhibition rules in `alertmanager_inhibit.yml` (if loaded) are
     consulted in the next stage.
3. Silence/inhibition check: no silence covers it; not inhibited (nothing suppresses
   a critical `InstanceDown`). Alert proceeds.
4. Grouping: group key = `('InstanceDown', 'critical')`. The group is new →
   Alertmanager holds the notification for `group_wait` = 30 s, hoping siblings
   (other down instances, which share the same group key) join.
5. Dispatch: after 30 s, Alertmanager builds the notification (all alerts currently
   in the group, including annotations like `summary`) and sends it to the receiver of
   the matched route: stdout-receiver → webhook POST to
   `http://host.docker.internal:5001/stdout`.
6. Receiver delivery: webhook_sink.py logs the POST (this is the observable proof -
   see `routing_demo_output.txt`). A real receiver (Slack/Email) would format the
   message per its template and deliver to the channel.
7. While the alert keeps firing: the group re-notifies every `repeat_interval`
   (4 h). Any *new* alert joining the group triggers a fresh notification earlier
   - at the next `group_interval` boundary (5 m).
8. Resolution: when the target recovers, Prometheus POSTs the alert with `endsAt`
   in the past → Alertmanager marks it resolved and (by default) sends a resolved
   notification to the same receiver if `send_resolved` is enabled for the webhook
   (webhook_configs defaults to `send_resolved: true`).

Demonstration: `routing_demo_output.txt` in this folder shows a synthetic
critical `InstanceDown` arriving at the `/stdout` sink and a synthetic warning
`HighCPUUsage` arriving at `/logfile` - two different receivers from one config.
