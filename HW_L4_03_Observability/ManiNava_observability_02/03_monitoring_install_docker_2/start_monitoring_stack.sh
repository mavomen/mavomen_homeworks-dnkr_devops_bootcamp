#!/bin/bash
set -e

echo "Starting monitoring stack..."
docker-compose up -d

echo "Waiting for services to be ready..."
sleep 10

echo "Checking services status..."
docker-compose ps

echo "Testing Prometheus..."
curl -s http://localhost:9090/api/v1/status/config | jq '.status' || echo "Prometheus not ready"

echo "Testing Grafana..."
curl -s http://localhost:3000/api/health | jq || echo "Grafana not ready"

echo "Testing Node Exporter..."
curl -s http://localhost:9100/metrics | head -20
