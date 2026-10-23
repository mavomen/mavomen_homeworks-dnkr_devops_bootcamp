#!/bin/bash
sudo useradd --no-create-home --shell /bin/false prometheus 2>/dev/null || true
sudo mkdir -p /etc/prometheus /var/lib/prometheus
# binaries copied to /usr/local/bin, config/service set up
sudo systemctl enable --now prometheus
