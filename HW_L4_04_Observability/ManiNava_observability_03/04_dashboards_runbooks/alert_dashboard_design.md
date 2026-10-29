# Alert Dashboard Design (04_dashboards_runbooks)

## 0. Why every alert needs a dashboard

An alert answers "is something wrong right now?" - a dashboard answers
"what exactly is wrong, since when, and how bad?". An alert without a matching
dashboard leaves the on-call blind during triage; a dashboard without alerts is only
found when someone is already looking. Design rule: for every alert, the dashboard
must contain the panels that prove the alert's expression plus the panels that
localize the cause.

The reference stack is the one built in the previous homework
(`HW_L4_03_Observability/.../03_monitoring_install_docker_2`): Grafana 11.5.0 at
http://localhost:3000 (admin/admin) with Prometheus as data source - see the
"Reference dashboard" section at the bottom for the concrete panel/queries layout.

---

## 1. InstanceDown (expr: `up == 0`, critical)

Meaning: Prometheus cannot scrape a target - the instance is unreachable, the
exporter died, or the network path broke. It is a *detection* alert; the dashboard
must answer "is it really down, and is everything on that host down or only the
exporter?"

### Panels

| Panel | Query / content | Purpose |
|---|---|---|
| Target status (stat panel) | `up{instance=~"$instance"}` with thresholds red < 1 | Instant confirmation of the alert's own expression |
| Last scrape age / scrape health (stat) | `time() - max(timestamp(up{instance=~"$instance"}))` | Shows when data was last seen - distinguishes "down now" from "down since 20 min ago" |
| Exporter/process metrics now (stat) | `node_exporter_build_info` presence, `process_start_time_seconds` | If the exporter still answers, the instance is *not* down - the alert is a scrape-path problem |
| Host vitals (timeseries) | `100 - avg by (instance)(rate(node_cpu_seconds_total{mode="idle"}[5m]))*100`, `node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes * 100` | Dead host → series go stale; alive host → series continue |
| Scrape failures over time (timeseries) | `increase(prometheus_target_scrapes_exceeded_body_size_limit_total[1h])` or `up` as a step graph over 6h | Was the target flapping all day or did it fall off a cliff? |
| All targets overview (table) | `up` by instance/job | Is this one instance or a whole class (network/DC event)? |

### 3 key metrics for the on-call

1. `up{instance="..."}` - the alert's own expression; confirm current state and
   `scrape_duration_seconds` for how it failed (timeout vs connection refused).
2. `node_load1` / `100 - rate(node_cpu_seconds_total{mode="idle"}[5m])*100` - if
   these still update, the host is alive and the problem is the exporter/service.
3. `count by (job) (up == 0)` - blast radius: one instance or many?
   (`prometheus_target_interval_length_seconds` / `scrape_samples_scraped` help
   distinguish "never came back" from "slow but alive".)

---

## 2. HighCPUUsage (expr: idle-rate → > 80 %, warning)

Meaning: sustained saturation on one host. The dashboard must show *what* is
consuming CPU and whether it is user code, system/kernel time, or IO wait.

### Panels

| Panel | Query / content | Purpose |
|---|---|---|
| CPU utilization per mode (timeseries, stacked) | `rate(node_cpu_seconds_total[5m])` by `mode` (iowait, system, user, steal) | The classic "what kind of busy" graph: iowait → disk, steal → noisy neighbor, user → app |
| CPU% vs threshold (timeseries + threshold line) | `100 - avg by (instance)(rate(node_cpu_seconds_total{mode="idle"}[5m]))*100` with a line at 80 | Visualizes exactly what the alert sees |
| Load average (timeseries) | `node_load1`, `node_load5`, `node_load15` | Saturation trend vs. core count; long load > short load = recovering |
| Top processes (table, if process exporter available) | `topk(5, rate(process_cpu_seconds_total[5m]))` | Names the culprit process |
| Run queue / scheduling (stat) | `node_procs_running`, `node_procs_blocked` | Saturation confirmation beyond CPU% |

### 3 key metrics for the on-call

1. `rate(node_cpu_seconds_total{mode="iowait"}[5m])` - high iowait redirects the
   investigation from CPU to disk/network (see DiskIO panels).
2. `node_memory_MemAvailable_bytes` - memory pressure causing swap/thrash often
   masquerades as CPU load.
3. `node_disk_io_time_seconds_total` rate / `node_disk_io_now` - disk saturation
   as the most common hidden cause of "high CPU".

---

## 3. HighErrorRate (expr: 5xx ratio > 2 %, critical, SLO-guard)

Meaning: users are getting failures. The dashboard must show *which endpoints*,
*which error codes*, *since when*, and what changed at that time.

### Panels

| Panel | Query / content | Purpose |
|---|---|---|
| Error ratio vs SLO (timeseries + threshold) | `sum(rate(http_requests_total{status=~"5.."}[5m])) / sum(rate(http_requests_total[5m])) * 100` with line at 2 | The alert's own expression, visualized |
| Requests by status code (timeseries, stacked) | `sum by (status)(rate(http_requests_total[5m]))` | 500 vs 502 vs 503 → app bug vs upstream vs overload |
| Request rate + latency p50/p95/p99 (timeseries) | `sum(rate(http_requests_total[5m]))`; `histogram_quantile(0.95, sum by (le)(rate(http_request_duration_seconds_bucket[5m])))` | Error/latency/traffic correlation - the RED triple next to each other |
| Errors by endpoint/handler (table, topk) | `topk(10, sum by (handler, status)(rate(http_requests_total{status=~"5.."}[5m])))` | Localizes the failing route |
| Deploy markers (annotations) | annotation from CI webhook | Did the errors start with the last deploy? |
| Dependencies health (stat row) | `up{job=~"db\|cache\|payments"}` | Ruling dependency outages in/out quickly |

### 3 key metrics for the on-call

1. Error ratio split by `status` label - 5xx *types* decide the first move
   (502/503 = upstream/infra, 500 = code, 429 = throttling).
2. `histogram_quantile(0.95, ...)` latency - rising latency *before* errors
   suggests saturation/timeout cascade rather than a code regression.
3. Request rate at error onset - errors starting exactly with a traffic spike
   point at capacity, not correctness (and vice versa).

---

## Reference dashboard (previous exercise)

The Grafana instance from the previous homework is the base to extend
(dashboard name suggestion: "Platform Overview - Alerts", one row per alert
class):

| Row | Panels | Queries |
|---|---|---|
| 1 - Availability | Target status (stat), `up` step graph, scrape health table | `up`, `time() - timestamp(up)` |
| 2 - Compute | CPU util by mode (stacked), load averages, memory available | `rate(node_cpu_seconds_total[5m])`, `node_load1/5/15`, `node_memory_MemAvailable_bytes` |
| 3 - Traffic/Errors | RED triple: rate, error %, latency p50/p95/p99 + top-error endpoints table | as in section 3 above |
| 4 - Scrape pipeline | scrape duration, samples scraped, target sync | `scrape_duration_seconds`, `scrape_samples_scraped`, `prometheus_target_sync_length_seconds` |

Variables: `$instance` (from `label_values(up, instance)`), `$job`,
`$__rate_interval` for all `rate()` windows. Annotations: deployments, alert firing
events (Grafana annotation query: `ALERTS{alertstate="firing"}`).
