# Recording Rules Explanation (07_promql_queries_2)

## 1. What are Recording Rules?

Recording rules are periodic evaluations, defined in `rule_files`, that run a PromQL
expression on a schedule (group `interval`) and store the result as a new time series
in Prometheus's own TSDB - under a name you choose.

```yaml
groups:
  - name: example_rules
    interval: 30s
    rules:
      - record: job:http_requests:rate5m      # new metric name
        expr: rate(http_requests_total[5m])   # expression evaluated every 30s
```

After evaluation, `job:http_requests:rate5m` behaves like any scraped metric: queryable,
dashboards-able, alert-able.

## 2. Why do we use Recording Rules?

- Performance: heavy expressions (rate over long windows, histogram quantiles)
  are computed once per interval - not once per dashboard refresh, not once per
  Grafana panel, not duplicated across 20 alerts.
- Simplicity & consistency: alerts and dashboards query the same short,
  pre-aggregated series (e.g. `job:http_errors:rate5m`), so the dashboard and the page
  can never disagree.
- Multi-step pipelines: SLO burn-rate math chains several recorded series
  (error ratio 5m, error ratio 1h) - impossible to express cleanly inline.
- Standard names: the `level:metric:operations` convention
  (`job:http_request_duration:quantile95`) makes the aggregation level and window
  obvious at a glance.

## 3. How do we enable Recording Rules in Prometheus?

1. Write the rules file (e.g. `recording_rules.yml` with `groups:`/`rules:` as above).
2. Reference it in `prometheus.yml`:
   ```yaml
   rule_files:
     - /etc/prometheus/recording_rules.yml
   ```
3. Load/reload: restart Prometheus, or (with `--web.enable-lifecycle`)
   `curl -X POST http://localhost:9090/-/reload`.
4. Validate first: `promtool check rules recording_rules.yml`.
   Active groups/rules are visible at `http://localhost:9090/rules` and in
   `prometheus_rule_group_iterations_*` metrics.

## 4. What is the difference between Recording Rules and Alerting Rules?

| | Recording rule | Alerting rule |
|---|---|---|
| `record:` vs `alert:` | `record: name` - stores a series | `alert: Name` - emits an alert |
| `expr` result stored as | a new time series in the TSDB | an alert state (pending → firing) |
| Needs `for:`/labels/annotations | no | typically yes (`for`, `severity`, `summary`...) |
| Goes to Alertmanager | never | yes, when firing |
| Purpose | precompute/reuse expensive queries | detect bad conditions and notify humans |

They usually live in the same rule group file and are evaluated by the same rules
engine; a typical pipeline is: *recording rule* computes `job:http_errors:rate5m` →
*alerting rule* fires `HighErrorRate` when the recorded series crosses a threshold.
