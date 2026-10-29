# HW_L4_04_Observability - Observability 3 (Alerting) - ManiNava

Delivery folder: `ManiNava_observability_03` (per panel naming style
`<Student>_observability_03`). Extends the monitoring stack of Observability 2 with
Alertmanager: alert rules, notification routing, inhibition, dashboards/runbooks,
and alert-fatigue hygiene.

## Structure

- `01_alertmanager_setup/` - alerting-flow doc, docker-compose (prometheus +
  alertmanager + node_exporter), prometheus.yml, alerts.yml (InstanceDown,
  HighCPUUsage), minimal alertmanager.yml, start script, live evidence
  (`start_stack_output.txt`, `alerts_pipeline_check.txt`) and the end-to-end
  InstanceDown demo (`instance_down_demo_output.txt`, `demo_instance_down.sh`).
- `02_alert_rules_basics/` - `alerts_basic.yml` + `alerts_slo.yml` (HighErrorRate,
  SLO 99), explanation docs, `alerts_validation.txt` (promtool).
- `03_notifications_routing/` - full routing config (`alertmanager.yml`),
  inhibition config (`alertmanager_inhibit.yml`), explanations, `webhook_sink.py`
  (local test receiver on host port 5001), and live demo evidence
  (`routing_demo_output.txt`, `inhibition_demo_output.txt`).
- `04_dashboards_runbooks/` - `alert_dashboard_design.md` (panels + 3 key metrics
  per alert) and `runbook_instance_down.md` (context, on-call steps, decision tree,
  links, `runbook_url` wiring - actually applied to the InstanceDown rule).
- `05_alert_fatigue_maintenance/` - `alert_fatigue_analysis.md` (fatigue definition,
  8 noise sources + fixes, 2 concrete delete/merge examples) and
  `alerting_maintenance_checklist.md` (monthly/quarterly tables).

## How to run

```bash
cd ManiNava_observability_03 && ./run_all.sh
```

`run_all.sh` executes, in order: start the stack (01), run the InstanceDown demo
(01, ~4 min), validate rule files (02), run the routing + inhibition demos (03).
Sections 04/05 are documentation deliverables.

The live demos follow the metric → alert → notification path end-to-end:
stopping `node_exporter` makes the real `InstanceDown` fire, and synthetic alerts
POSTed to Alertmanager's API demonstrate routing (critical→`/stdout`,
warning→`/logfile`) and inhibition (same-instance warning suppressed) via a local
webhook sink - evidence files contain the actual command outputs and the sink log.

## Live environment notes

- Host: Arch Linux, Docker 29.9.2, docker-compose 5.6.1 (compose v2).
- Images: `prom/prometheus:latest` (v3.16.0), `prom/alertmanager:latest` (v0.35.0),
  `prom/node-exporter:latest`.
- Access points while the stack is up: Prometheus http://localhost:9090,
  Alertmanager http://localhost:9093, node_exporter http://localhost:9100/metrics.
- The webhook sink (`webhook_sink.py`, HTTP/1.1, single-log) runs on the host
  :5001; Alertmanager reaches it via `host.docker.internal` (`host-gateway` extra
  host, documented in the compose file). Its log is
  `03_notifications_routing/webhook_sink_log.txt`.
- Alertmanager state note (discovered live): the nflog (notification history)
  lives in an anonymous Docker volume - the `prom/alertmanager` image declares
  `VOLUME /alertmanager` - and `docker-compose up --force-recreate` re-attaches the
  *same* volume to the recreated container. Notification state therefore survives a
  recreate: `repeat_interval: 4h` history (entries kept for `2 × repeat_interval`)
  makes Alertmanager silently skip a re-notification whose firing-alert set is
  unchanged (DedupStage: same alert-label hashes + repeat interval not elapsed -
  no webhook call, no error). The demo scripts therefore reset the state properly
  with `docker-compose rm -f -s -v alertmanager` (stops and removes the container
  *with* its anonymous volume) followed by `docker-compose up -d alertmanager`,
  which starts a genuinely fresh one; the expected notification then always
  dispatches after `group_wait: 30s`. (Verified live: after the volume reset the
  exact same synthetic alert that had been silently suppressed dispatches
  immediately.)
- Extensions beyond the PDF base (documented inline): `node_exporter` service in the
  compose stack (real target for the alert demos) and the webhook sink itself as a
  stand-in for real Slack/email receivers.
- All command history is in `commands_history.txt`.
