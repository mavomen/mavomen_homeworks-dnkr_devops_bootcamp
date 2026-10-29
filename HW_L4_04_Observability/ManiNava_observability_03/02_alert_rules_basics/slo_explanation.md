# SLO-based Alerting - HighErrorRate (alerts_slo.yml)

## 1. Which SLO does this rule approximately implement?

It approximates an availability SLO of 99 % for the `web` service: at most 1 % of
requests may fail (5xx) over the service's measurement window. The rule does not
implement the SLO by itself - it *guards* it:

- SLO (target): 99 % of requests succeed over e.g. 30 days.
- Alert threshold (2 % error rate sustained 10 min): fires long before the
  *budget* is exhausted. If 2 % of traffic fails for 10 minutes, at typical traffic
  that alone can consume a meaningful slice of a 30-day 1 % error budget - so this
  rule acts as a fast early-warning for budget burn, while the full burn-rate
  calculation (multi-window) is the rigorous version.
- The `slo: "99"` label ties the alert to the SLO it protects, so routing/runbooks/
  dashboards can group by it.

A precise implementation would use error *budget burn rates*:
`burn = error_ratio(actual window) / error_budget(1 %)` and alert on burn > 14.4 over 1 h
(+ 5 m short window) etc. This rule is the simple, still-SLO-driven approximation the
homework asks for.

## 2. Why a percentage rate instead of an absolute error count?

- Self-scaling with traffic: "500 errors/minute" means an outage at 1 000 req/s and
  nothing at all at 5 req/s. A *ratio* means the same thing ("2 % broken") regardless of
  load, so one threshold is valid at 3 a.m. and during a launch spike.
- Comparable across services/instances: error % lets you compare the API service and
  the marketing site with the same rule template; absolute counts cannot.
- Matches the SLO definition: SLOs are ratios ("99 % of requests succeed"), so the
  alert expression mirrors the SLO math directly.
- Resistant to cardinality/scrape noise: per-instance counts vary with replica
  count; after `sum(rate(...))` the ratio stays stable when the fleet scales up or down.

Absolute counts do still matter for some alerts (e.g. "more than 10 failed *payments*
per hour" for a low-traffic-but-critical path) - those combine a floor with the ratio
(`... > 2 and rate(..._total[5m]) > 0.1`), but for a web service availability SLO the
ratio is the right primary signal.

## 3. What problem does this alert cause with very low traffic, and how to improve it?

The problem - ratio instability / division noise at low request rates:

- With, say, 3 requests in 5 minutes of which 1 fails, the ratio is 33 % → the alert
  fires although the service handled ~nothing. One unlucky error trips a page that
  means little.
- At near-zero traffic, `sum(rate(...))` approaches 0; floating-point ratios become
  spiky and quantitatively meaningless (0/0 windows produce no series at all, silently
  disabling the alert exactly when there is no traffic).
- A *sustained* low error ratio (e.g. 0.1 %, under threshold) also burns budget
  silently with no alert - the simple ratio only looks at one window.

Improvements:

1. Add a traffic floor - only alert when there is enough traffic for the ratio to
   mean something:
   ```promql
   ( sum(rate(http_requests_total{job="web", status=~"5.."}[5m]))
     / sum(rate(http_requests_total{job="web"}[5m])) ) * 100 > 2
   and
   sum(rate(http_requests_total{job="web"}[5m])) > 1
   ```
   (`and on()` - below 1 req/s, rely on the `InstanceDown`-class alerts instead.)
2. Longer window + longer `for`: evaluate over `[30m]`/`[1h]` so single errors
   cannot dominate, and keep `for: 10m`.
3. Proper multi-window burn-rate alerting: page on fast burn (1 h) and ticket on
   slow burn (6 h/3 d) using precomputed recording rules - the canonical SRE answer.
4. Track the budget itself (e.g. `slo:period_error_budget:remaining` recording
   rule) and alert on remaining-budget percentage - that is the mechanism this rule
   approximates.
