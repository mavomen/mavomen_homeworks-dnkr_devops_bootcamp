# Alert Rules Basics (02_alert_rules_basics)

Covers `alerts_basic.yml` (InstanceDown, HighCPUUsage) and `alerts_slo.yml`
(HighErrorRate). Both files are validated with
`promtool check rules` (see `build.sh` / `commands_history.txt`).

## 1. Why `for: 2m` for InstanceDown? What can go wrong with `for: 0`?

`for: 2m` requires the condition (`up == 0`) to stay continuously true for two
minutes before the alert fires. This filters transient scrape failures:

- A single missed scrape (network blip, host briefly busy, exporter restarting after a
  deploy) sets `up == 0` for one evaluation cycle. With `for: 2m` that blip never
  pages anyone; without it, it does.

What goes wrong with `for: 0`:

- Pager noise: every hiccup - a container restarting during deployment, a 1-second
  network partition, a target mid-provision - fires immediately. The on-call learns to
  ignore the channel, and real outages hide in the noise (alert fatigue).
- Alert flapping: with no persistence requirement, alerts fire/resolve in quick
  succession, each producing separate notifications (grouping helps, but the noise
  remains).
- No triage value: an alert that self-resolves in 20 seconds almost never required
  a human; it only burns attention.

The trade-off is detection latency (a real outage is reported ~2 min later) - an
acceptable price for a stable pager. Severity-critical alerts typically use
short `for` values (1-2 min); less urgent conditions use longer ones (5-15 min).

## 2. Why `rate()` and `avg by (instance)` in the HighCPU `expr`?

```promql
100 - (avg by (instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 80
```

- `rate(...[5m])`: `node_cpu_seconds_total` is a counter - a cumulative number
  of CPU-seconds spent in each mode since boot. Raw counter values are meaningless for
  "how busy is the CPU now"; `rate()` converts them to CPU-*seconds used per second*
  over the window (and handles counter resets when a host reboots). The idle-mode rate
  is the fraction of each core that was doing nothing.
- `avg by (instance)`: after `rate()`, there is one series per (core, mode, instance)
  - e.g. 16 idle-rate series on a 16-core host. `avg by (instance)` collapses the cores
  into one average idle fraction per machine, giving a machine-level CPU utilization
  in 0..1. `* 100` makes it percent, and `100 - x` flips idle% into used%.
  (Alternatives: `sum by (instance) / count by (instance)` for exact per-core mean;
  `max by (instance)` to alert if *any* core saturates - a stricter, noisier variant.)
- The combination is the standard node CPU utilization formula and keeps the alert
  per-instance so the notification says *which* machine.

## 3. Three best practices in alert rule design

1. Always use `for` (and reasonable windows) - never alert on raw instantaneous
   metrics. Transient states are not incidents; `for` + windowed functions
   (`rate`, `avg_over_time`) separate sustained problems from blips and directly reduce
   alert fatigue.
2. Alert on symptoms the user feels, not on every internal cause. Page on
   "error rate > 2 % for 10 min" (SLO burn), not on "CPU > 80 %" for every CPU metric of
   every container; keep cause-based checks (CPU, memory, disk) as warnings, and let
   saturation alerts cover the aggregate. An alert should be actionable and have a
   runbook; if nobody would act, delete it.
3. Make rules self-explanatory: clear `summary`/`description`, meaningful labels,
   consistent severities. Include `{{ $labels.instance }}`, `{{ $value }}` in
   annotations, tag with `team` for routing, and use `severity` strictly (critical =
   page now, warning = ticket). Recording rules for the heavy math keep the `expr`
   readable and identical between dashboards and alerts.

(Bonus practice: every alert carries a `runbook_url` annotation - see
`04_dashboards_runbooks/runbook_instance_down.md`.)
