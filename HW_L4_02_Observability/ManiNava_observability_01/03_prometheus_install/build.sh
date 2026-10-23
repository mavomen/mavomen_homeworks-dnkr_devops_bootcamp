#!/bin/bash
source "$(dirname "$0")/../lib/common.sh"
cd "$SUB/03_prometheus_install"
log "prometheus install start"

sudo useradd --no-create-home --shell /bin/false prometheus 2>/dev/null || true
sudo mkdir -p /etc/prometheus /var/lib/prometheus

VER="2.55.1"
cd /tmp
[ -f prometheus-${VER}.linux-amd64.tar.gz ] || wget -q https://github.com/prometheus/prometheus/releases/download/v${VER}/prometheus-${VER}.linux-amd64.tar.gz
tar xzf prometheus-${VER}.linux-amd64.tar.gz >/dev/null 2>&1
sudo cp prometheus-${VER}.linux-amd64/prometheus /usr/local/bin/
sudo cp prometheus-${VER}.linux-amd64/promtool /usr/local/bin/
sudo cp -r prometheus-${VER}.linux-amd64/consoles /etc/prometheus/
sudo cp -r prometheus-${VER}.linux-amd64/console_libraries /etc/prometheus/
sudo chown -R prometheus:prometheus /etc/prometheus /var/lib/prometheus /usr/local/bin/prometheus /usr/local/bin/promtool

cat > prometheus.yml << 'YML'
global:
  scrape_interval: 15s
  evaluation_interval: 15s
alerting:
  alertmanagers:
    - static_configs:
        - targets: []
rule_files: []
scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']
YML
sudo cp prometheus.yml /etc/prometheus/
sudo chown prometheus:prometheus /etc/prometheus/prometheus.yml

cat > /tmp/prometheus.service << 'EOF'
[Unit]
Description=Prometheus
Wants=network-online.target
After=network-online.target
[Service]
User=prometheus
Group=prometheus
Type=simple
ExecStart=/usr/local/bin/prometheus --config.file=/etc/prometheus/prometheus.yml --storage.tsdb.path=/var/lib/prometheus/ --web.console.templates=/etc/prometheus/consoles --web.console.libraries=/etc/prometheus/console_libraries
[Install]
WantedBy=multi-user.target
EOF
sudo cp /tmp/prometheus.service /etc/systemd/system/prometheus.service
sudo systemctl daemon-reload
sudo systemctl enable --now prometheus 2>&1 | tail -1

sleep 10
systemctl status prometheus --no-pager | head -8 > prometheus_status.txt
curl -s http://localhost:9090/-/ready > prometheus_setup_output.txt
echo >> prometheus_setup_output.txt
curl -s http://localhost:9090/api/v1/status/buildinfo | grep -o '"version":"[^"]*"' >> prometheus_setup_output.txt
log "prometheus done"
