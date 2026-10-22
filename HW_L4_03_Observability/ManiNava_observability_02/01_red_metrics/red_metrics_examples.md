# RED Metrics - Worked Examples for a Web Service

Assume a web service exposing the standard metrics:

```
http_requests_total{method="GET", status="200", handler="/api/items"}   (Counter)
http_request_duration_seconds_bucket{le="..."}                          (Histogram)
```

## 1. Rate - requests per second

```promql
# Total request rate, all methods/statuses
rate(http_requests_total[5m])

# Per-method request rate
sum by (method) (rate(http_requests_total[5m]))
```

- `rate(...[5m])` turns the monotonic counter into requests/second averaged over the
  last 5 minutes (counter-reset safe).
- Wrap in `sum by (method)` when you want one series per HTTP method instead of one
  series per label combination.
- Use it for: traffic dashboards, capacity planning, "did my deploy double the traffic?"

## 2. Errors - error percentage

```promql
# 5xx errors per second
rate(http_requests_total{status=~"5.."}[5m])

# Error ratio (0..1)
rate(http_requests_total{status=~"5.."}[5m])
  /
rate(http_requests_total[5m])

# Error percentage (matches SLO-style alert rules)
sum(rate(http_requests_total{status=~"5.."}[5m]))
  /
sum(rate(http_requests_total[5m])) * 100
```

- `status=~"5.."` is a regex label matcher: any 500, 502, 503, ...
- Numerator and denominator are both rates so the ratio is an average over the
  window, independent of scrape interval.
- Use it for: the "E" panel of a RED dashboard and SLO alerts
  (e.g. `> 2 for 10m` on the percentage version).

## 3. Duration - response time

```promql
# p95 response time over 5 minutes
histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))

# p99 response time
histogram_quantile(0.99, rate(http_request_duration_seconds_bucket[5m]))

# Average response time (sum/count of the histogram)
rate(http_request_duration_seconds_sum[5m])
  /
rate(http_request_duration_seconds_count[5m])
```

- The histogram is pre-aggregated in buckets; `histogram_quantile()` interpolates the
  requested quantile from the bucket boundaries - this is why p95/p99 alerting uses
  `_bucket` series, not the raw latency of a single request.
- `rate()` on `_bucket` makes it a windowed distribution (and handles counter resets).
- Use it for: the "D" panel, latency SLOs ("99 % < 300 ms"), spotting tail latency that
  an average would hide.

## Putting it together (the classic RED panel)

| Panel | Query |
|---|---|
| Rate | `sum(rate(http_requests_total[5m]))` |
| Errors | `sum(rate(http_requests_total{status=~"5.."}[5m])) / sum(rate(http_requests_total[5m])) * 100` |
| Duration | `histogram_quantile(0.95, sum by (le) (rate(http_request_duration_seconds_bucket[5m])))` |

Note: when aggregating a histogram across series (e.g. `sum by (le)`), the `le` label must
be preserved - that is why the duration panel uses `sum by (le)`.
