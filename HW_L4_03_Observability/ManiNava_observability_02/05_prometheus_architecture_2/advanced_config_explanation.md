# Advanced Configuration Explanation (05_prometheus_architecture_2)

## 1. What role do `external_labels` play?

`external_labels` (under `global:`) attach labels that identify *the Prometheus server
itself* - not its targets:

```yaml
external_labels:
  cluster: 'production'
  environment: 'dev'
```

- They are added to every series and, importantly, to alerts sent to
  Alertmanager - so downstream systems can tell which Prometheus (cluster/env) an alert
  came from.
- They are essential when multiple Prometheus servers exist (HA replicas, per-DC
  servers) and results are merged (federation, remote-write, Thanos): the external
  labels disambiguate identical series names coming from different servers.
- They differ from `static_configs.labels` (labels for *targets*) and from relabeling
  (labels for *samples/targets* at scrape time).

## 2. How do `relabel_configs` work?

For every discovered target, Prometheus runs the list of relabeling steps in order. Each
step can match source labels by regex, transform them, and write them into target labels:

```yaml
relabel_configs:
  - source_labels: [__address__]     # input: internal target address 'node_exporter:9100'
    target_label: instance           # output: user-visible label
    replacement: 'node-1'            # static value here (no regex → whole source unused)
  - source_labels: [__address__]
    target_label: job
    replacement: 'infrastructure'
```

- Without a `regex`, the implicit `(.*)` matches the entire concatenation of
  `source_labels`; without `replacement`, the default `$1` copies the match.
- The double-underscore labels (`__address__`, `__scheme__`, `__metrics_path__`,
  `__param_*`) are internal: they drive *how* to scrape, and any label starting with
  `__` is removed from the final series (that is why we copy them into normal labels).
- `action` defaults to `replace`; also `keep`/`drop` (filter targets), `labelmap`,
  `hashmod` (sharding).
- Order matters: each step sees the output of the previous one.

## 3. How is `file_sd_configs` used for Service Discovery?

```yaml
  - job_name: 'file_sd'
    file_sd_configs:
      - files:
          - '/etc/prometheus/targets/*.json'
        refresh_interval: 30s
```

- Prometheus watches all matching files (JSON or YAML); each contains target groups:
  `{"targets": [...], "labels": {...}}` (see `targets.json` in this folder).
- Every `refresh_interval` (or on file-change notification via inotify) it re-reads the
  files and rebuilds the target list - no Prometheus restart or reload needed.
- Who writes the files? Any external tool: an Ansible playbook, Terraform output, a CI
  job, a cron script - this decouples "where targets come from" from Prometheus config.
- Failure mode: a malformed file is reported in the Prometheus UI/logs (check
  `/targets`); the previous good list keeps being scraped until the file is fixed.

## 4. What is the difference between `scrape_interval` in `global` vs in a `job`?

- `global: scrape_interval: 15s` = default for all jobs; a per-job value overrides
  it for that job only (here `node_exporter` scrapes every 10 s, everything else 15 s).
- Reasoning to choose: per-job lets you tune resolution vs storage cost per metric
  class - high-value fast-moving metrics (CPU, request rate) get shorter intervals;
  slow/cheap metrics get longer.
- Gotcha: per-job intervals shorter than the evaluation_interval do not speed up rule
  evaluation; and `rate()` window lengths in queries should be chosen relative to the
  *effective* (job-level) interval, not the global one.
