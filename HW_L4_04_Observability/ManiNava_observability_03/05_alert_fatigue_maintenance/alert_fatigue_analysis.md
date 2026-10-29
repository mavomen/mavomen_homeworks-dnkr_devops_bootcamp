# Alert Fatigue Analysis (05_alert_fatigue_maintenance)

## 1. What is Alert Fatigue and why is it dangerous for DevOps teams?

Alert fatigue is the numbing effect of too many, too noisy, or too
low-value alerts. When pages arrive constantly - flapping alerts, alerts that
resolve themselves, duplicate alerts for one root cause - responders develop
reflexes to *ignore, bulk-acknowledge, or mute* the notification channel.

Why it is dangerous:

- Real incidents drown in noise. The pager that fires 50 times a day makes the
  51st page just another message - the on-call misses the actual outage inside the
  stream.
- Slower response (and MTTA/MTTR growth). Humans triage slower when they expect
  most alerts to be false alarms; the hesitation costs minutes exactly when minutes
  matter.
- Erosion of trust in monitoring. Teams stop treating alerts as signals and start
  treating them as background radiation; eventually someone proposes "turning it all
  off" - leaving the system unmonitored.
- Burnout and attrition. On-call rotation becomes dreaded; a tired, cynical
  on-call makes worse decisions during the real incident.
- Masking of systemic problems. Noise hides the patterns (one flaky dependency
  firing 30×/day) that would otherwise trigger a proper fix.

Rule of thumb from SRE practice: every page must be actionable, urgent, and
user-impacting - if a page could wait until morning or needs no human, it should be
a ticket/dashboard, not a page.

## 2. At least 4 common sources of noisy alerts

| # | Noise source | How it shows up |
|---|---|---|
| 1 | Thresholds set too sensitively / too low | CPU > 80 % with no headroom knowledge fires on every build/backup spike; memory > 70 % fires on hosts that simply have big caches. Pages that resolve themselves minutes later. |
| 2 | Alerting per instance instead of aggregated | A 30-replica service briefly slow → 30 separate HighLatency pages for one incident; rolling restart fires one alert per pod. |
| 3 | Alerts on unstable/derived metrics without smoothing | `rate()` over 30 s windows on spiky traffic, per-second counters, `quantile` on small samples - values jump across the threshold, causing flapping fire/resolve/fire. |
| 4 | No `for:` duration / too short | A single missed scrape (`up == 0` for one 15 s interval) pages immediately; transient blips page as if they were outages. |
| 5 | Missing inhibition / dependency logic | DB goes down → 40 "ApplicationError" alerts + 1 DBDown alert all page independently; the on-call gets 41 notifications for 1 problem. |
| 6 | Alerts without an owner or an action | "DiskIO high on db-3" - nobody knows what to do; every firing is acknowledged and forgotten, but it keeps repeating every `repeat_interval`. |
| 7 | Stale rules after system changes | Rules written for a decommissioned service keep firing on test/staging leftovers; nobody remembers who owns them. |
| 8 | Missing silences for planned maintenance | Every deploy/restart window produces a burst of InstanceDown + PodRestart alerts that everyone knows are expected. |

## 3. Practical fix for each source

| Source | Practical fix |
|---|---|
| 1 - Sensitive thresholds | Baseline the metric first (e.g. p95 over 2 weeks) and set the threshold above normal peak; use sustained conditions (`for: 10m`, `avg_over_time`) instead of instantaneous triggers; reserve pages for SLO-impacting values, move the rest to warnings. |
| 2 - Per-instance paging | Aggregate: `count by (job)(up == 0) > 2` pages only when *many* instances fail; use Alertmanager `group_by: ['alertname','severity']` so whatever remains collapses into one notification; keep a per-instance warning (non-paging) for detail. |
| 3 - Unstable metrics | Smooth the expression: longer `rate()` windows (`[10m]`+), `avg_over_time`, recording rules that precompute a stable series; alert on the recorded series. |
| 4 - No `for:` | Always set `for:` scaled to severity (critical 1-2 m, warning 5-15 m) and use multi-window confirmation for expensive alerts (`and` of 5 m and 1 h views - burn-rate style). |
| 5 - No inhibition | Add `inhibit_rules`: root-cause alerts (InstanceDown, DatabaseDown) suppress their symptoms (HighCPU/HighError) for the same `instance`/`environment` (see `03_notifications_routing/alertmanager_inhibit.yml` for the pattern). |
| 6 - Alerts without an action | Rule review gate: every alert must have a runbook (`runbook_url`) and a named owner (`team` label); alerts failing the review are demoted to dashboard panels or deleted. |
| 7 - Stale rules | Quarterly rule audit (see `alerting_maintenance_checklist.md`): map each rule to a live service; delete rules whose service is gone; tag rules with `owner`/`service` labels to make the mapping checkable. |
| 8 - No maintenance silences | Make silences part of the change process: deploys/migrations auto-create a silence (`amtool silence add ... --duration 30m`) scoped to exactly the affected selectors, and it expires automatically. |

## 4. Two alerts from our system that should be deleted or merged

Assuming the small platform from this homework (prometheus, node_exporter,
a web service with the three rules) plus typical extras teams add over time:

### 4.1 DELETE - `HostDown` (a second, older `up == 0`-style rule)

Real systems accumulate a second availability rule from an earlier iteration, e.g.:

```yaml
- alert: HostDown
  expr: probe_success == 0          # or up == 0 on a different job, older threshold
  for: 1m
```

Why delete/merge: `HostDown` and `InstanceDown` fire on the same condition, for the
same instance, at nearly the same time - two pages for one outage, split across two
routes because one uses `severity: critical` and the other `warning`. Merge into the
single canonical `InstanceDown` (`up == 0`, `for: 2m`, critical, with runbook) and
delete the duplicate. Duplicate detection is easy in review:
`promtool check rules` + a manual pass grouping rules by normalized `expr`.

### 4.2 MERGE - three per-metric disk alerts into one SLO-style alert

```yaml
- alert: DiskUsage85     # expr: used/total > 0.85, for 10m, warning
- alert: DiskUsage90     # expr: used/total > 0.90, for 5m,  critical
- alert: DiskWritesHigh  # expr: rate(node_disk_writes_completed_total[5m]) > X
```

Why merge: DiskUsage85 and DiskUsage90 are the *same* condition at two thresholds -
a host crossing 85 % pages (warning), crosses 90 % pages again (critical), then
re-notifies per `repeat_interval`: three to four messages for one slow-moving
problem, all requiring the same action (clean/extend). Replace with one rule on
the predictive metric (time-to-full) and a single warning→critical severity split via
routing, e.g.:

```yaml
- alert: DiskFillingFast
  expr: predict_linear(node_filesystem_avail_bytes{fstype!~"tmpfs|overlay"}[6h], 4*3600) < 0
  for: 30m
  labels: {severity: warning, team: platform}
```

DiskWritesHigh is a *cause* metric that rarely needs a page (high write rate alone is
not user-impacting) - demote it to a dashboard panel and let DiskFillingFast /
DiskAlmostFull page only when the *effect* is coming. Result: one actionable page
instead of three noise generators, with inhibition handling the overlap
(critical suppresses the warning for the same instance).
