#!/bin/bash
set -e

echo "Starting Prometheus + Alertmanager stack..."
docker-compose up -d

echo "Waiting for services to be ready..."
sleep 5

echo "Checking containers:"
docker ps | grep -E 'prometheus|alertmanager' || echo "Containers not running!"

echo "Testing Prometheus endpoint..."
curl -s http://localhost:9090/-/ready || echo "Prometheus not ready"

echo "Testing Alertmanager endpoint..."
curl -s http://localhost:9093/-/ready || echo "Alertmanager not ready"
