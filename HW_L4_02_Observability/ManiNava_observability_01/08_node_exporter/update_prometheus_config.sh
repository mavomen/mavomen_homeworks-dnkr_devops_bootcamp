#!/bin/bash
sudo cp prometheus.yml /etc/prometheus/prometheus.yml
sudo chown prometheus:prometheus /etc/prometheus/prometheus.yml
sudo systemctl restart prometheus
