# Advanced PromQL (07_promql_queries_2)

## 1. Histogram Queries - how to use histogram metrics?

A Histogram metric (`http_request_duration_seconds`) exports three series per label set:

- `..._bucket{le="0.1"}` - cumulative counters of observations ≤ each bucket bound
- `..._sum` - total sum of all observed values
- `..._count` - number of observations

Usage patterns:

```promql
# cumulative bucket counts must be rate()'d first (they are counters):
rate(http_request_duration_seconds_bucket[5m])

# bucket boundaries (the le label) stay intact when aggregating:
sum by (le) (rate(http_request_duration_seconds_bucket[5m]))
```

Buckets are cumulative - `le="0.5"` already includes everything ≤ 0.5 - and the
`+Inf` bucket equals `_count`. Aggregating histograms across instances means summing
`_bucket`/`_sum`/`_count` series *by `le`*.

## 2. Quantiles - how are they calculated?

`histogram_quantile(φ, bucket_rate_vector)` interpolates the φ-quantile from the
cumulative bucket distribution:

```promql
# p95 request duration across all instances
histogram_quantile(0.95, sum by (le) (rate(http_request_duration_seconds_bucket[5m])))
```

How it works: it finds the two adjacent buckets where the cumulative fraction crosses φ
and linearly interpolates inside that bucket. Implications:

- Error is bounded by bucket width - the result lands somewhere inside a bucket, so
  define buckets around your SLO (e.g. 0.05/0.1/0.2/0.3/0.5/1 for a 300 ms SLO).
- Works only on `_bucket` series after `rate()`, and the `le` label must be preserved
  by any aggregation (`sum by (le)`).
- For Summary metrics the quantile is pre-computed by the app (no aggregation possible
  across instances).

## 3. Subqueries - what are they and when are they used?

A subquery is a range query *nested inside* another expression:

```promql
# average of the 5-minute rate, sampled every minute, over the last hour
avg_over_time(rate(http_requests_total[5m])[1h:1m])

# max p95 over the last 30 minutes (sampled every 30s)
max_over_time(
  histogram_quantile(0.95, sum by (le) (rate(http_request_duration_seconds_bucket[5m])))
  [30m:30s]
)
```

Syntax: `<instant_query>[<range>:<resolution>]` (resolution optional - defaults to the
global evaluation interval).

- Used when a function needs a range vector but the inner expression is itself a
  computation (`rate`, `histogram_quantile`, aggregations) - i.e. "rate of a rate",
  quantiles over time.
- Cost: the engine evaluates the inner query at every step - keep ranges/resolutions
  reasonable, or pre-compute with recording rules instead.

## 4. Recording Rules - what are they and what are their benefits?

Recording rules continuously evaluate an expression and store the result as a new
metric (see `recording_rules.yml`):

```yaml
groups:
  - name: example_rules
    interval: 30s
    rules:
      - record: job:http_requests:rate5m
        expr: rate(http_requests_total[5m])
```

Benefits:
- Dashboards stay fast: expensive rate/quantile math runs once per `interval`
  instead of on every panel refresh/Grafana query.
- Alerts become simple and consistent: alerts query the precomputed series, so
  alert expression == dashboard expression.
- Naming convention: `level:metric:operations`
  (`job:http_errors:rate5m`) documents the aggregation level and window.
- Reusable building blocks for SLO error-ratio math (multi-window burn rates).

Enabled by adding the file to `prometheus.yml`: `rule_files: ["/etc/prometheus/*.rules.yml"]`
and reloading.

## 5. Vector Matching - what is it and how does it work?

Binary operations between two instant vectors match series by identical label sets
by default; `on(labels)` / `ignoring(labels)` narrow or widen the matching key, and
`group_left`/`group_right` handle many-to-one cases:

```promql
# matching key: only 'job' and 'instance' labels must be equal
rate(http_requests_total{status=~"5.."}[5m])
  / on (job, instance)
rate(http_requests_total[5m])

# many-to-one: per-pod series ÷ one per-service series
pod_metric / on (service) group_left(service_total)
```

- one-to-one (default): both sides must have exactly matching label sets → per-series
  division (like the error-ratio above).
- on/ignoring: control which labels define "same series" - e.g. ignore `status` so
  the 5xx rate matches the total rate.
- group_left/group_right: one side may have *more* series than the other (e.g. join
  a per-instance series with a single per-job reference value); the "left"/"right"
  naming refers to which side has the many series.
- Unmatched series are dropped from the result (this is also a common source of
  "empty query result" bugs).
