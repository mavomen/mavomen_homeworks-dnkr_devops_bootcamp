#!/bin/bash
sudo cp prometheus.yml /etc/prometheus/
sudo chown prometheus:prometheus /etc/prometheus/prometheus.yml
sudo systemctl restart prometheus
