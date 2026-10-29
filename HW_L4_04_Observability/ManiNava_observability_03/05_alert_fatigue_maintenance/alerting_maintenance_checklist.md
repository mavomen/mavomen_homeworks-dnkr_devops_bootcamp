# Alerting Maintenance Checklist (05_alert_fatigue_maintenance)

A periodic checklist for keeping the alerting system healthy. Monthly items keep the
day-to-day signal clean; quarterly items catch drift. Each item lists what to do,
how to verify, and who does it (suggested roles: `RA` = rotation admin /
on-call lead, `SRE` = observability owner, `Team` = service teams).

## Monthly

| # | Item | How | Owner |
|---|---|---|---|
| M1 | Review alert rules; delete/update stale ones | Export rules (`amtool config show` / repo diff since last month); for each rule confirm: the service still exists, the metric still exists, someone owns it (`team` label). Rules whose service was decommissioned → delete in the same PR that decommissions the service. | SRE + Team |
| M2 | Check rule evaluation health | Prometheus UI `/rules`, `prometheus_rule_evaluation_failures_total == 0`, no rule stuck in `pending` longer than its `for`. | SRE |
| M3 | Review notification timings vs reality (`for`, `group_wait`, `group_interval`, `repeat_interval`) | Compare AM config with incident history: alerts that auto-resolved before `for` expired → threshold/`for` too strict; groups that sent >3 messages per incident → tighten `group_by`/`group_interval`; pages that were re-paged "too late" → lower `repeat_interval` for criticals. | RA + SRE |
| M4 | Review silences; delete forgotten ones | `amtool silence query` (or UI → Silences): every silence must have an owner, a comment, and an expiry < 2 weeks. Delete expired-but-listed and orphaned silences; recurring maintenance → convert to scheduled change + auto-silence in the deploy pipeline. | RA |
| M5 | End-to-end alert test: firing → notification delivered | Post a synthetic test alert to the Alertmanager API (`curl -X POST .../api/v2/alerts` with a `TestAlert`/`AlwaysOn` alert) and verify it arrives in the real Slack/Email receiver - not just in a dev sink. Automate: a small CI job (like this homework's `webhook_sink.py` demos) that fails the check if nothing arrives within `group_wait + 1m`. | SRE |
| M6 | Receiver/on-call schedule sanity | Confirm escalation receivers (PagerDuty/Slack/email) still point at the current rotation; test one real page (use the M5 test alert routed to the paging receiver). | RA |
| M7 | Alert noise report | Count notifications per alertname over the month (`webhook_sink_log` / AM `nflog` / PagerDuty API): top-5 noisiest alerts get a fix ticket (threshold, `for`, inhibition, or delete). | SRE |

## Quarterly

| # | Item | How | Owner |
|---|---|---|---|
| Q1 | Deep rule audit: noise sources & duplicates | Group rules by normalized `expr` to find duplicates (like the `HostDown` vs `InstanceDown` example in `alert_fatigue_analysis.md`); demote non-actionable alerts to dashboards; confirm every paging alert has `runbook_url` + owner. | SRE + Team |
| Q2 | SLO review; re-align alerts to new SLOs | Re-check each SLO (target, window, error budget): did the service outgrow the old target? Update burn-rate/alert thresholds to the current SLOs, update the `slo` label on alerts so routing/dashboards follow. | SRE + Team |
| Q3 | Failover / redundancy test of the alerting chain | Kill one Alertmanager instance in the cluster, stop one Prometheus replica: alerts must still dedupe and notify (AM gossip + HA Prometheus). Verify from the receiver side, not just the logs. | SRE |
| Q4 | Config backup & versioning check | `alertmanager.yml`, `prometheus.yml`, rule files all in git, no drift between repo and running containers (`docker exec alertmanager amtool check-config` + diff); restore-from-backup drill once. | SRE |
| Q5 | Documentation refresh | Runbooks still match reality (commands, dashboard links); on-call rotation docs updated; this checklist itself reviewed and adjusted. | RA + SRE |

## Standing principles (every change, not just reviews)

- Any new paging alert needs: owner, runbook link, severity discipline, and a
  demonstrated real firing (synthetic test like M5) before it goes live.
- Silences are always time-boxed and annotated with a ticket ID - "temporary"
  silences older than 2 weeks are deleted, not extended.
- Config changes go through the repo (PR + `amtool`/`promtool` validation in CI),
  never hand-edited in the UI only.
