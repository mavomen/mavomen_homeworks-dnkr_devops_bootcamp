# Prometheus Architecture - Understanding (04_prometheus_architecture_1)

## 1. Pull-based vs Push-based - what is the difference and why does Prometheus use Pull?

| | Pull-based (Prometheus) | Push-based (StatsD, Graphite-style) |
|---|---|---|
| Initiation | Prometheus fetches `/metrics` from each target on a schedule | The application/agent sends metrics to the backend |
| Metric freshness | Known scrape interval; stale data is detectable (`up == 0`, staleness markers) | Data appears whenever the app pushes; silence is ambiguous |
| Target health | Built-in: a failed scrape sets `up{job}=0` - monitoring the monitorer for free | If the app stops pushing, you see a gap, not an explicit "down" |
| Load pattern | Steady, predictable | Spiky (each app pushes on its own schedule) |
| Config direction | Centralized in Prometheus (targets, intervals, labels) | Distributed across every app's push config |

Why Prometheus pulls:

1. Self-health for free: a target that cannot be scraped is itself an alert
   (`InstanceDown`) - you never "monitor the monitor" manually.
2. Simplicity on the app side: apps only need to expose `/metrics`; no fire-and-forget
   queueing code, no retry logic, no metric loss on app crash (the last state is simply
   not scraped anymore, which is visible).
3. Anti-tampering / correctness: metrics are scraped exactly when Prometheus needs
   them, with a consistent timestamp and labels; an app cannot flood or starve the
   backend by pushing at a bad moment.
4. Discovery & relabeling fit naturally: Prometheus decides *what* exists to scrape
   (service discovery) and *how* to label it (relabeling), keeping the topology in one
   place.

The push direction is not abandoned entirely: for short-lived jobs (batch/cron) that can
outlive their scrapes, Prometheus offers the Pushgateway - a middleman that the job
pushes to and Prometheus then pulls from.

## 2. Main Components - what role does each play?

- Prometheus Server - the core: fetches (scrapes) metrics from targets, stores them
  in its local TSDB, evaluates PromQL queries and rule groups (recording + alerting
  rules), and serves the HTTP API/UI.
- Exporters - small processes that translate a system's internal state into
  Prometheus format: `node_exporter` (OS/hardware), `blackbox_exporter` (probes),
  `mysqld_exporter`, app-side client libraries, etc.
- Service Discovery - the mechanism that keeps the target list current: static
  configs, file_sd, DNS_sd, Kubernetes_sd, Consul, etc. New containers/instances appear
  as scrape targets without editing prometheus.yml by hand.
- Alertmanager - receives alert events fired by Prometheus rules and handles
  *notification logistics*: deduplication, grouping, silencing, inhibition, routing to
  receivers (email, Slack, webhook, PagerDuty...), with retry/backoff.

(Also part of the ecosystem: Pushgateway for short-lived jobs, Grafana as the
dashboard layer on top of the Prometheus query API.)

## 3. Storage: how does Prometheus store data? What is TSDB?

Prometheus writes everything into its built-in Time Series Database (TSDB) on local
disk (`/prometheus`, configured by `--storage.tsdb.path`).

- Time series model: every series is uniquely identified by the metric name + label
  set: `http_requests_total{job="web", status="200"}`. Samples are
  `(timestamp, float64)` appended in order.
- Block storage: data is first written to a write-ahead log (WAL) for crash safety,
  kept in an in-memory head block, then flushed to immutable, compressed on-disk
  blocks (default: 2 h of data per block). Old blocks are compacted in the background.
- Storage format: chunked samples (gorilla-style XOR compression of floats per chunk),
  plus an inverted index mapping label pairs → postings lists, which makes label queries fast.
- No distributed storage: one Prometheus node = one local TSDB. Horizontal scale is
  done by running independent Prometheus servers (sharding by job/target, or federating
  aggregate series upward), not by clustering the TSDB.
- Retention: `--storage.tsdb.retention.time=15d` (default) controls how long blocks
  are kept before deletion.

## 4. Scraping: what is it and how does it work?

Scraping is the periodic pull of `/metrics` from each target:

1. Service discovery produces a list of targets for each scrape job.
2. Prometheus requests each target's HTTP endpoint (e.g. `http://node_exporter:9100/metrics`)
   at the configured `scrape_interval` (global or per-job).
3. The exposition format (OpenMetrics/Prometheus text or protobuf) is parsed into samples,
   relabeling rules are applied, and samples are appended to the TSDB with the scrape
   timestamp.
4. Each scrape is itself measured: `up{job=...}` (1 = success), `scrape_duration_seconds`,
   `scrape_samples_scraped`. A failed scrape keeps the last good series but marks it stale
   after ~5 min (staleness marker) and sets `up == 0`.
5. Targets can be grouped per job with different intervals, timeouts, paths, schemes
   (`https`), and basic-auth/TLS settings.

## 5. Retention policy: what is it and how is it configured?

Retention = how long samples stay queryable before TSDB deletes them.

```yaml
# via command line flags (not in prometheus.yml):
--storage.tsdb.retention.time=15d   # age-based (default 15d)
--storage.tsdb.retention.size=50GB  # size-based cap (whichever hits first)
```

- Set in the container `command:` (docker-compose) or systemd unit args.
- Choose by disk budget × scrape volume: e.g. node_exporter at 15 s over 2 weeks needs
  far less space than 1000 app series at 1 s.
- Long-term retention is done by remote-write to Thanos/VictoriaMetrics/Mimir - the
  local TSDB stays a "hot, recent" store.
- `evaluation_interval`/`scrape_interval` do not affect retention; they only affect
  resolution.

## 6. High Availability: how can Prometheus be made HA?

Prometheus does not cluster itself; HA is achieved by running independent replicas:

- Two (or more) identical Prometheus servers scrape the *same* targets, each with its
  own disk. They do not share state; both evaluate rules independently.
- Alertmanager is deduplicated: both servers send to the same Alertmanager *cluster*
  (2-3 instances); Alertmanager's gossip-based dedup ensures each alert notifies once.
- Dashboards/SLOs: query both (e.g. Thanos/VictoriaMetrics can dedup replicas at
  query time) or treat replicas as fail-over.
- Optional long-term layer: Thanos/Mimir/VictoriaMetrics receive remote-writes from
  all replicas, dedup, and provide one global view + object-storage retention.
- Partition instead of over-replicate: at scale, split servers by function
  (infra vs app metrics) rather than running 3 copies of everything.

Takeaway: HA Prometheus = N identical pullers + Alertmanager cluster + (optional)
global view layer; consistency is eventually per-replica, but alerting is exactly-once
via Alertmanager dedup.
