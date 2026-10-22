# PromQL Basics & Aggregation (06_promql_queries_1)

## 1. Instant Queries - what are they and when are they used?

An instant query evaluates an expression at one point in time (default: now) and
returns, per series, a single sample:

```promql
up
```

- Result type: instant vector (one sample per series).
- Used for: current status (dashboards' stat panels), API checks, "what is happening
  right now" (e.g. `up`, `node_memory_MemAvailable_bytes`).
- API: `GET /api/v1/query?query=up` (optionally `&time=<rfc3339>` for a past instant).

## 2. Range Queries - what are they and how do they differ from Instant?

A range query evaluates the expression at many consecutive steps over a window and
returns a matrix:

```promql
rate(http_requests_total[5m])        # as a range query: e.g. 5m step over 1h
```

- Result type: range vector - for every series, an array of (timestamp, value) points.
- API: `GET /api/v1/query_range?query=...&start=...&end=...&step=15s`.
- Difference from instant: instant = one value per series "now"; range = the *evolution*
  over time (what line charts are drawn from). Also, sub-expressions producing a range
  vector can only be used inside functions (`rate()`, `avg_over_time()`, ...) - you
  cannot return a raw range vector from a query; functions reduce it back to an instant
  vector per step.

## 3. Selectors - how do we use labels to filter?

A selector = metric name + optional `{}` matcher list:

```promql
http_requests_total{method="GET", status="200"}    # equality match
http_requests_total{status=~"5..", method!="GET"}  # regex match / negative match
http_requests_total{status=~"5..", job!=""}        # job!="" = label exists
```

- `=` exact, `!=` not equal, `=~` regex match, `!~` regex negative match.
- An empty label matcher (`job=""`) matches series without that label;
  `job!=""` selects series that have it (common trick to drop un-labeled series).
- A bare metric name (`http_requests_total`) is itself a selector: all series of that
  metric, all labels.

## 4. Operators - types of operators in PromQL

- Arithmetic: `+ - * / % ^` - between scalars or between vectors.
- Comparison: `== != > < >= <=` - filter (`high_cpu{...} > 80`) or return
  (`bool` modifier for 0/1).
- Aggregation: `sum`, `avg`, `min`, `max`, `count`, `count_values`,
  `quantile`, `stddev`, `stdvar`, `topk`, `bottomk`, `group` - collapse many series
  into fewer: `sum by (method) (...)`.
- Set/binary vector matching: `and` (intersection), `or` (union),
  `unless` (complement); default matching is on identical label sets, changed via
  `on()/ignoring()` and `group_left/group_right` (many-to-one/one-to-many).
- Special: `atan2` between vectors; `offset`/`@` modifiers for time shifting.

## 5. Functions - important functions in PromQL

| Function | Purpose |
|---|---|
| `rate(v[5m])` | Per-second average increase of a counter over the window (reset-safe) - the default for counters |
| `irate(v[5m])` | Instantaneous per-second rate from the last 2 samples - faster reaction, noisier |
| `increase(v[5m])` | Absolute increase over the window (rate × window) |
| `histogram_quantile(q, v)` | Quantile (e.g. 0.95) from histogram `_bucket` series |
| `avg_over_time(v[1h])` / `max_over_time` / `sum_over_time` | Aggregate a range vector over time |
| `sum by (l) (...)` | Aggregation across series |
| `label_replace(v, "dst", "$1", "src", "(.*):.*")` | Rewrite/derive labels |
| `absent(v)` | Fires when a series disappears (useful alerts) |
| `time()`, `vector(1)` | Epoch time / constant vector (e.g. uptime math) |
| `clamp_min/max`, `round` | Numeric shaping |
