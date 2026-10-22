#!/bin/bash
set -e

echo "Starting Prometheus with Docker..."
docker-compose up -d

echo "Waiting for Prometheus to be ready..."
sleep 5

echo "Checking Prometheus status..."
docker ps | grep prometheus || echo "prometheus container not running!"

echo "Testing Prometheus endpoint..."
curl -s http://localhost:9090/api/v1/status/config | head -10
