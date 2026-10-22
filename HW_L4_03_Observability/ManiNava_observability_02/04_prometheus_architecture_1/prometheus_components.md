# Prometheus Components (04_prometheus_architecture_1)

## 1. Prometheus Server

Main tasks:
- Target management: merges service-discovery results with static configs and keeps
  the active target pool per job.
- Scraping: pulls `/metrics` from every target at each `scrape_interval`, applying
  per-job TLS/auth/path settings.
- Storage: appends samples to the local TSDB (WAL → head → 2 h blocks) with
  retention handling.
- Rule evaluation: runs recording rules and alerting rules every
  `evaluation_interval`; sends firing alerts to Alertmanager.
- Query serving: evaluates PromQL (instant + range) for the UI, Grafana, and
  `/api/v1/*` clients.

How it works (lifecycle of one metric): target is discovered → scraped → samples
relabeled & appended → recording rules may fold it into new series → alerting rules may
turn it into an alert event → Grafana queries it via PromQL.

## 2. Exporters

Types:
- Host/system: `node_exporter` (CPU, memory, disk, network, filesystem of a machine).
- Middleware/DB: `mysqld_exporter`, `postgres_exporter`, `redis_exporter`,
  `haproxy_exporter`, `blackbox_exporter` (HTTP/TCP/ICMP probes).
- App-instrumentation: client libraries (Go/Java/Python/...) embedded in the app -
  the most accurate RED metrics source.
- Third-party/legacy bridges: `snmp_exporter` (network gear),
  `windows_exporter`, cloud provider exporters.

How they work: an exporter is an HTTP server exposing `/metrics` in Prometheus
format; it either reads kernel counters (node_exporter binds `/proc`, `/sys`),
queries the target system (SQL, SNMP), or *is* the application itself (embedded client
library). Prometheus treats all of them the same - just more scrape targets.

## 3. Pushgateway

When it is used: for short-lived/batch jobs that exit before Prometheus can
scrape them - cron scripts, one-off migrations, CI steps. The job pushes its final
metrics to Pushgateway; Pushgateway keeps them and Prometheus scrapes Pushgateway.

Caveats (why it is NOT the default path):
- Pushed series become "stuck": they persist until explicitly deleted (or
  `--persistence` ends), so up/down detection is lost.
- It is a single point of aggregation, not a general push pipeline.
- Rule of thumb: service metrics → pull; batch job results → Pushgateway.

## 4. Alertmanager - its role in the alerting pipeline

Position in the pipeline: Prometheus (rules fire) → POST `/api/v2/alerts` to
Alertmanager → routing tree → receivers.

Responsibilities:
- Grouping: collapse many alerts with the same `group_by` labels into one
  notification (`group_by`, `group_wait`, `group_interval`, `repeat_interval`).
- Deduplication: identical alerts from HA Prometheus replicas notify only once
  (gossip cluster).
- Silencing: time-boxed mute for specific matchers (maintenance windows).
- Inhibition: suppress dependent alerts (e.g. `InstanceDown` silences that host's
  `HighCPUUsage`).
- Routing: a tree of routes/matchers decides which receiver gets which alert
  (critical → PagerDuty, warning → Slack...), with retries and backoff per receiver.

How it works: each alert carries labels (`alertname`, `severity`, `instance`...);
Alertmanager computes the route match, applies group/silence/inhibit logic, then
notifies the receiver and re-notifies on `repeat_interval` while the alert persists.
