# PromQL Examples (06_promql_queries_1)

```promql
# 1. Instant query
up
```
1. What it does: returns, for every scrape target, whether the last scrape
   succeeded (1) or failed (0).
2. Returns: instant vector - one sample per target series
   (`up{job="prometheus", instance="..."} 1`).
3. When used: health stat panels, `InstanceDown` alerting rules, quick CLI checks.
4. Practical example: on a fresh stack this shows `up{job="node_exporter",...} 1`
   - if it flips to `0`, that target is broken/down right now.

```promql
# 2. Range query
rate(http_requests_total[5m])
```
1. What it does: computes the per-second request rate averaged over the last
   5 minutes for each series of the counter.
2. Returns: instant vector (in an instant query) / matrix of values per step
   (in a range query) - per label-combination of `http_requests_total`.
3. When used: the "R" of RED - traffic panels and rate-based alerts; needs
   ≥ 2 samples in the window (with 15 s scrapes, `[5m]` has ~20).
4. Practical example: before vs after a marketing campaign -
   `sum(rate(http_requests_total[5m]))` jumps from e.g. 4 req/s to 40 req/s.

```promql
# 3. Selector with labels
http_requests_total{method="GET", status="200"}
```
1. What it does: selects only the raw counter series whose method is GET and
   status is 200.
2. Returns: instant vector with all labels of those series (counter values are
   cumulative since process start).
3. When used: isolating one traffic class (e.g. only 5xx, only POST) before
   aggregation or rate computation.
4. Practical example: `{status=~"5.."}` during an incident shows exactly which
   endpoints/methods are erroring.

```promql
# 4. Aggregation
sum(http_requests_total) by (method)
```
1. What it does: sums the counter across all series, keeping one output series per
   distinct `method` label (other labels - instance, status - are discarded).
2. Returns: instant vector, one series per method
   (`{method="GET"} 123456`, `{method="POST"} 8910`).
3. When used: per-class totals while hiding per-instance detail - e.g. total
   traffic per verb across all replicas.
4. Practical example: comparing `sum by (method)` before/after a caching layer:
   GET total climbs while POST stays flat.

```promql
# 5. Function
increase(http_requests_total[1h])
```
1. What it does: computes how many requests were added to the counter in the last
   hour (like `rate(...[1h]) * 3600`, extrapolation-smoothed, reset-safe).
2. Returns: instant vector - the increase per series over the window.
3. When used: "how many events in the last N" reporting - hourly/daily request
   counts, error counts for a shift report.
4. Practical example: `sum(increase(http_requests_total{status=~"5.."}[24h]))`
   ≈ "total server errors yesterday", a number a manager can read.
