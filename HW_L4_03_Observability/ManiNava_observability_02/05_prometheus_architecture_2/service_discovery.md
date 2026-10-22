# Service Discovery & Scrape Configuration (05_prometheus_architecture_2)

## 1. Static Configuration - what is it and when is it used?

`static_configs` is the simplest targeting method: an explicit, hand-written list of
targets in `prometheus.yml`:

```yaml
scrape_configs:
  - job_name: 'node_exporter'
    static_configs:
      - targets: ['node_exporter:9100']
```

- Used when the target set is small, stable, and slow to change: a lab/VM setup, one
  self-monitoring target, a couple of permanent DB exporters, or anything without an API
  to query.
- Downside: every add/remove/replace of an instance requires a config edit + reload.
  In dynamic environments (containers, autoscaling) this does not scale.

## 2. Service Discovery - what is it and what are its benefits?

Service discovery (SD) lets Prometheus find targets automatically by querying a
source of truth about the infrastructure instead of a hand-maintained list.

Benefits:
- No manual target churn: containers scale up/down and the scrape pool follows.
- Consistency: the same source the orchestrator uses (Kubernetes API, Consul
  catalog, DNS SRV) is used for monitoring, so monitoring cannot drift from reality.
- Rich metadata: SD attaches labels (namespace, pod, role, region...) that make
  dashboards and alerts multidimensional.
- Self-healing: a crashed replica is dropped automatically; a new one is picked up on
  the SD refresh interval.

## 3. Types of Service Discovery

### File-based Service Discovery (`file_sd_configs`)
- Prometheus watches local JSON/YAML files; each file lists groups of targets + labels.
- An external process (CI, a script, an inventory tool like Ansible/Terraform) writes
  the file; Prometheus reloads targets within `refresh_interval` (default 5m, here 30s)
  without a config reload.
- Great middle ground: dynamic for the machine, no SD infrastructure needed.

### DNS-based Service Discovery (`dns_sd_configs`)
- Prometheus periodically resolves SRV/A/AAAA records; each resolved endpoint becomes a
  target.
- Works anywhere DNS exists (often with tools like SkyDNS/Consul serving SRV records);
  naturally fits "the service is reachable at `web.service.consul`" environments.

(Others in the wild: `kubernetes_sd_configs` - the most common in production;
`consul_sd_configs`; `ec2_sd_configs`/`gce_sd_configs` for cloud instances; `http_sd_configs`.)

## 4. Relabeling - what is it and what is it used for?

Relabeling transforms labels at two moments:

- `relabel_configs` - before scraping: rewrite the target's labels, drop targets, or
  change the scrape address (it is the only place `__address__` / `__scheme__` /
  `__metrics_path__` can be modified).
- `metric_relabel_configs` - after scraping: rewrite/drop *samples' labels* before
  ingestion (e.g. drop noisy metrics, normalize instance names).

Typical uses:
- Set/override `instance`, `job`, or environment labels
  (this homework's example: `instance: node-1`, `job: infrastructure`).
- Filter targets: `action: drop` + regex on a meta-label (e.g. skip `__meta_kubernetes_...`)
- Rename incoming metric labels for consistency.

Important: relabeling happens at scrape time - it never touches already-stored data.

## 5. Scrape Intervals - how are they configured and what is their impact?

- Global default: `global: scrape_interval: 15s` - applies to every job that does
  not override it.
- Per-job override: `scrape_interval: 10s` inside the job (used here for
  `node_exporter` so infra metrics are fresher than the 15 s default).
- Evaluation interval: `evaluation_interval: 15s` - how often rule groups run
  (recording/alerting); unrelated to scraping but should be in the same order of
  magnitude.

Impact:
- Resolution vs cost: 10 s × many series × many targets = more samples, more disk,
  more CPU. Rule of thumb: `retention_days × series × 86400 / interval` ≈ sample count.
- Query/alert correctness: `rate()` windows must span ≥ 4 samples
  (e.g. `[5m]` at 15 s scrape = 20 samples ✓); too-long intervals make rate() jumpy or
  empty and delay alert detection by up to 2×interval.
- Per-job tuning: fast-changing app metrics get 5-15 s; slow movers (cloud quotas,
  config stats) can live with 30-60 s to save storage.
