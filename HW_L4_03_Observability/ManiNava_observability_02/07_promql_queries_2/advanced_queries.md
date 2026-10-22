# Advanced Queries (07_promql_queries_2)

```promql
# 1. Histogram quantile
histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))
```
1. What it does: computes the 95th percentile request duration from the histogram
   buckets, per remaining label set (typically per job/instance).
2. Each part: `0.95` = target quantile; `_bucket` series = cumulative counts ≤ each
   `le` bound; `rate(...[5m])` = makes the bucket counters a per-second distribution over
   the window (reset-safe).
3. Returns: instant vector - one p95 value per label combination.
4. Use case: latency SLO check - "is p95 under 300 ms?" on a dashboard; also the
   basis of latency alert rules.

```promql
# 2. Rate with multiple time ranges
rate(http_requests_total[5m]) / rate(http_requests_total[15m])
```
1. What it does: divides the 5-minute request rate by the 15-minute request rate -
   a short-window/long-window comparison.
2. Each part: two `rate()` calls over different windows; default one-to-one vector
   matching (identical label sets on both sides).
3. Returns: instant vector - ratio ≈ 1 when traffic is steady; > 1 = recent traffic
   spike vs the longer baseline.
4. Use case: a cheap "traffic anomaly" signal (spike detection) that does not need a
   baseline model - alert when it exceeds e.g. 3 for several minutes.

```promql
# 3. Conditional aggregation
sum(rate(http_requests_total{status=~"5.."}[5m])) /
sum(rate(http_requests_total[5m])) * 100
```
1. What it does: computes the overall 5xx error percentage across the whole fleet.
2. Each part: `{status=~"5.."}` filters to server errors; inner `rate()` per series;
   outer `sum(...)` collapses all instances; the division of two totals (one series each)
   matches trivially; `* 100` turns a fraction into a percentage.
3. Returns: instant vector with a single series, no labels - the global error %.
4. Use case: SLO-based alerting: `> 2 for 10m` = "2 % of requests failing for 10
   minutes" → page the on-call (this is exactly the HighErrorRate rule in homework 3).

```promql
# 4. Label replacement
label_replace(up, "new_label", "$1", "instance", "(.*):.*")
```
1. What it does: for each `up` series, adds/overwrites label `new_label` with the
   part of `instance` before the colon (the host part: `node_exporter:9100` →
   `node_exporter`).
2. Each part: destination label; replacement template (`$1` = first regex capture
   group); source label; regex applied to the source value. Non-matching series pass
   through unchanged.
3. Returns: instant vector - same samples as `up`, with one extra/changed label.
4. Use case: derive clean names for dashboards/alerts - e.g. strip `:9100` so
   notifications read "node_exporter is down" instead of "node_exporter:9100 is down".

```promql
# 5. Time-based functions
time() - process_start_time_seconds
```
1. What it does: computes process uptime in seconds: current epoch time minus the
   epoch timestamp at which the process started.
2. Each part: `time()` = evaluation instant as a scalar; `process_start_time_seconds`
   = gauge exported by client libraries (the process start epoch); the scalar-vector
   subtraction applies the scalar to every series.
3. Returns: instant vector - uptime per matching process/instance.
4. Use case: restart detection - `... < 60` means a process restarted within the
   last minute; `max_over_time(...)` catches restarts that happened while you were not
   looking.
