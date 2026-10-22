# RED Metrics - Explanation

## 1. What are RED Metrics? What does each letter mean?

RED is a monitoring methodology introduced by Tom Wilkie (Weave Works) that answers
three questions for every user-facing service: is it serving requests, how many are
failing, and how fast are they served?

| Letter | Metric | What it measures | Typical Prometheus metric |
|---|---|---|---|
| R | Rate | The number of requests per second the service receives | `http_requests_total` (a Counter, turned into a per-second rate with `rate()`/`irate()`) |
| E | Errors | The number/percentage of failing requests | Same counter filtered by status code (`status=~"5.."`) or an `error` label |
| D | Duration | How long requests take to complete | `http_request_duration_seconds` (a Histogram) or a Summary |

RED deliberately measures things from the user's point of view (requests served by
the service), unlike USE (Utilization, Saturation, Errors) which looks at resources from
the inside.

## 2. Rate: what is it and how is it calculated? Practical example.

Rate is the speed of requests per unit of time.

- Prometheus counters only ever go up and reset on restart, so the raw value
  (`http_requests_total`) is not useful by itself. To get "requests per second" we use
  the `rate()` function over a time window, e.g. `rate(http_requests_total[5m])`.
- `rate(v[5m])` = (increase over the window) / (window length in seconds). It is
  extrapolated, corrects for counter resets, and averages over the whole window, so it is
  the standard choice for dashboards. `irate()` uses only the last two samples and reacts
  faster (good for short spikes and alerting).

Practical example: a web service received 1200 requests in the last 5 minutes
(300 s). Its Prometheus counter went up by 1200 over that window:

```
rate(http_requests_total[5m])  ≈  1200 / 300  =  4 req/s
```

If between 14:00 and 14:05 the value drops to 0 while the process is still healthy, the
rate going to 0 is itself a signal (traffic loss or a silent failure).

## 3. Errors: what types of errors should be monitored? How is it measured in Prometheus?

Error types worth monitoring:

1. HTTP 5xx (server-side) - the service itself failed: unhandled exceptions, DB
   connection failures, panics, timeouts upstream. These are always real defects and must
   alert.
2. HTTP 4xx (client-side) - malformed requests, missing auth. Some 4xx are normal
   (scanners hitting endpoints), but a *spike* in 401/403 can mean a credential problem,
   and 429s mean throttling is kicking in.
3. Transport/infra-level failures - connection refused, DNS failures, TLS errors:
   often visible as the target being `down` (`up == 0`) instead of an error status code.
4. Business-logic failures - requests that return 200 but did not do their job
   (payment rejected, order not created). Usually exposed as a separate counter
   (e.g. `payments_failed_total`), because status codes alone hide them.

Measurement in Prometheus:

- Counters carry labels, so errors are counted by filtering on the `status` label and
  dividing by the total:

```promql
rate(http_requests_total{status=~"5.."}[5m])     # errors per second
rate(http_requests_total{status=~"5.."}[5m])
  /
rate(http_requests_total[5m])                   # error ratio (0..1)
```

- For services that export an `error` label or `http_errors_total`, the same rate/total
  division applies.
- Note: a rate of *counts* and a ratio of *rates* must both use `rate()` on numerator and
  denominator - never divide raw cumulative counters.

## 4. Duration: what is it and how is it different from Latency?

- Latency is the single time one request took, as experienced at one point
   (often from the client's perspective: includes network travel, DNS, TLS, queueing).
- Duration (the "D" in RED) is the *distribution of request handling times* measured
  by the service itself - how long the server took to process each request, aggregated
  across all requests. In practice the two words are often used interchangeably, but in
  RED "Duration" specifically means the measured distribution (min/avg/p95/p99), not
  one sample.

A single request can be "slow" by chance; what matters operationally is the distribution:
if p95 is fine but p99 is 8 s, 1 request in 100 is having a terrible experience - that is
invisible in an average but obvious in a quantile.

How it is measured: instrument code with a Histogram (`http_request_duration_seconds`)
whose `_bucket`, `_sum`, `_count` series Prometheus can aggregate:

```promql
histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))   # p95
rate(http_request_duration_seconds_sum[5m]) /
rate(http_request_duration_seconds_count[5m])                              # average
```

## 5. Why are RED Metrics important for microservices?

- Per-service health at a glance: in a microservice system a user request fans out to
  many services. RED gives every service the same 3-line health check, so a 2 a.m. pager
  message can be answered with "which service has R/E/D broken".
- Golden signals for SLOs: error rate + duration are exactly what an SLO
  (e.g. "99% of requests succeed in < 300 ms") is written against; Rate gives the traffic
  context needed to interpret both.
- Fast localization of regressions: if the frontend's Duration is fine but the
  downstream `billing` service's error rate jumps, RED turns a vague "site is slow"
  report into a concrete service to look at.
- Uniform alerting and dashboards: because the same three metrics exist everywhere,
  dashboards, recording rules and alert templates can be reused across all services
  instead of being service-specific.

## 6. How can RED Metrics be implemented in Prometheus?

1. Instrument or expose metrics. Use a client library (Go `promhttp` middleware,
   Python `prometheus_client`, etc.) or an exporter/agent that emits:
   - `http_requests_total{method, status, handler}` (Counter) → Rate & Errors
   - `http_request_duration_seconds` (Histogram) → Duration
2. Scrape it. Prometheus pulls `/metrics` on an interval (`scrape_configs` in
   `prometheus.yml`).
3. Write the queries. Rate / error-ratio / quantile PromQL as shown above
   (see `red_metrics_examples.md`).
4. Pre-compute with recording rules for expensive queries (p95, error ratio) so
   dashboards stay fast.
5. Dashboards + alerts. Grafana panels for R/E/D per service; alerting rules such as
   "5xx ratio > 2 % for 10 min" (SLO-based alerting).
6. Optionally standardize it: Grafana/Prometheus "RED dashboards" or the
   *four golden signals* pattern so every new service gets the same treatment.
