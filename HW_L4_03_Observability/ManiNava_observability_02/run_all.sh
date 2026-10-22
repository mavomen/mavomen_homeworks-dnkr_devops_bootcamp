#!/bin/bash
# Run all Observability 2 sections in order (02 → 03 share ports; handled inside).
set -e
cd "$(dirname "$0")"
for d in 01_red_metrics 02_monitoring_install_docker_1 03_monitoring_install_docker_2 \
         04_prometheus_architecture_1 05_prometheus_architecture_2 \
         06_promql_queries_1 07_promql_queries_2; do
  if [ -x "$d/build.sh" ]; then
    (cd "$d" && ./build.sh)
  fi
done
