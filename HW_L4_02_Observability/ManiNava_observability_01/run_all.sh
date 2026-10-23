#!/bin/bash
for d in 01_observability_concepts 02_tools_overview 03_prometheus_install 04_grafana_install 05_prometheus_grafana_connect 06_metrics_types 07_grafana_explore 08_node_exporter; do
  [ -x "$d/build.sh" ] && (cd "$d" && ./build.sh)
done
