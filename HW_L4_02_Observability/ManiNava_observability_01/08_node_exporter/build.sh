#!/bin/bash
source "$(dirname "$0")/../lib/common.sh"
cd "$SUB/08_node_exporter"
log "node exporter"

VER="1.8.2"
cd /tmp
[ -f node_exporter-${VER}.linux-amd64.tar.gz ] || wget -q https://github.com/prometheus/node_exporter/releases/download/v${VER}/node_exporter-${VER}.linux-amd64.tar.gz
tar xzf node_exporter-${VER}.linux-amd64.tar.gz >/dev/null 2>&1
sudo cp node_exporter-${VER}.linux-amd64/node_exporter /usr/local/bin/
sudo useradd --no-create-home --shell /bin/false node_exporter 2>/dev/null || true
sudo chown node_exporter:node_exporter /usr/local/bin/node_exporter

cat > /tmp/node_exporter.service << 'EOF'
[Unit]
Description=Node Exporter
Wants=network-online.target
After=network-online.target
[Service]
User=node_exporter
Group=node_exporter
Type=simple
ExecStart=/usr/local/bin/node_exporter
[Install]
WantedBy=multi-user.target
EOF
sudo cp /tmp/node_exporter.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now node_exporter 2>&1 | tail -1
sleep 5
systemctl status node_exporter --no-pager | head -6 > node_exporter_status.txt

# update prometheus
cat > /etc/prometheus/prometheus.yml << 'YML'
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
  - job_name: 'node_exporter'
    static_configs:
      - targets: ['localhost:9100']
YML
sudo chown prometheus:prometheus /etc/prometheus/prometheus.yml
cp /etc/prometheus/prometheus.yml prometheus.yml
cat > update_prometheus_config.sh << 'EOF'
#!/bin/bash
sudo cp prometheus.yml /etc/prometheus/prometheus.yml
sudo systemctl restart prometheus
EOF
chmod +x update_prometheus_config.sh
sudo systemctl restart prometheus
sleep 5

curl -s http://localhost:9090/api/v1/targets > /dev/null
curl -s 'http://localhost:9090/api/v1/targets?state=active' | python3 -m json.tool > prometheus_targets.txt 2>&1

cat > node_exporter_metrics.md << 'MD'
# Node Exporter Metrics

## اطلاعات هر Metric
- **node_cpu_seconds_total:** زمان CPU مصرف شده به تفکیک mode (user/system/idle/iowait) - برای محاسبه CPU utilization
- **node_memory_MemTotal_bytes:** کل RAM سیستم - برای محاسبه استفاده حافظه
- **node_filesystem_size_bytes:** حجم کل هر فایل‌سیستم - برای مانیتورینگ Disk
- **rate(node_cpu_seconds_total[5m]):** نرخ تغییر CPU در 5 دقیقه، مناسب برای ترند و Alert

## استفاده در Monitoring
با این Metrics می‌توانیم استفاده CPU، حافظه، دیسک و شبکه را رصد کرده و در صورت تجاوز از آستانه Alert بفرستیم.

## دیگر Metrics موجود در Node Exporter
node_load1, node_load5, node_load15, node_network_receive_bytes_total, node_disk_io_time_seconds_total و صدها Metric دیگر با پیشوند node_ موجود است.
MD
log "node exporter done"
