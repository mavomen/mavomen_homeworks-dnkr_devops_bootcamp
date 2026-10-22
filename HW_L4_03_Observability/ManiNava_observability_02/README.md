# HW_L4_03_Observability - Observability 2 - ManiNava

Delivery folder: `ManiNava_observability_02` (per panel naming: `AmirMohammadMohammadi_observability_02` style).

## Structure (matches the PDF's suggested layout)

- `01_red_metrics/` - RED explanation + PromQL examples (docs)
- `02_monitoring_install_docker_1/` - Prometheus-only docker-compose, start script, live status outputs
- `03_monitoring_install_docker_2/` - full stack: Prometheus + Grafana + Node Exporter, start script, live status outputs
- `04_prometheus_architecture_1/` - architecture Q&A, components, ASCII diagram
- `05_prometheus_architecture_2/` - service discovery/relabeling config + explanations
- `06_promql_queries_1/` - PromQL basics/examples + real API query results
- `07_promql_queries_2/` - advanced PromQL, recording rules (+ `promtool check rules` clean)

## How to run

Each section has a `build.sh`; the root `run_all.sh` runs them in order:

```bash
cd ManiNava_observability_02 && ./run_all.sh
```

Sections 02/03/06 execute real Docker stacks and capture genuine command outputs
(`prometheus_docker_status.txt`, `stack_status.txt`, `query_results.txt`).
Section 02's stack is automatically taken down when section 03 starts
(same container name/port 9090).

## Live environment notes

- Host: Arch Linux, Docker 29.9.2, docker-compose 5.6.1 (compose v2).
- Images: `prom/prometheus:latest` (v3.16.0), `grafana/grafana:latest` (11.5.0,
  locally tagged due to limited network bandwidth), `prom/node-exporter:latest`.
- Access points while the section-03 stack is up:
  - Prometheus UI: http://localhost:9090
  - Grafana: http://localhost:3000 (admin/admin)
  - Node Exporter: http://localhost:9100/metrics
- `curl` gotcha documented in `06_promql_queries_1/query_results.txt`: raw `[5m]`
  in a query URL triggers curl URL-globbing (exit 3, silent under `-s`);
  `%5B5m%5D` encoding is used instead.
- All command history is in `commands_history.txt`.
