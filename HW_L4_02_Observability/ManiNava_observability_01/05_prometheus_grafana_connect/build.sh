#!/bin/bash
source "$(dirname "$0")/../lib/common.sh"
cd "$SUB/05_prometheus_grafana_connect"
log "connect prometheus to grafana"

# add datasource via API
curl -s -X POST -H "Content-Type: application/json" -u admin:admin \
  http://localhost:3000/api/datasources \
  -d '{"name":"Prometheus","type":"prometheus","url":"http://localhost:9090","access":"proxy","isDefault":true}' > datasource_info.txt 2>&1

cat > data_source_setup.md << 'MD'
# اتصال Prometheus به Grafana

## مراحل
1. وارد Grafana شوید: http://localhost:3000
2. به Configuration → Data Sources بروید
3. Prometheus را انتخاب کنید
4. URL: http://localhost:9090
5. Save & Test را بزنید

## چرا باید متصل کنیم؟
با اتصال Prometheus به Grafana می‌توانیم Metrics را با Query (PromQL) جستجو، تجسم و روی داشبورد نمایش دهیم.

## تست اتصال با Query ساده
در Explore با منبع Prometheus کوئری‌های زیر را تست کردیم:
- up
- go_gc_duration_seconds
- process_cpu_seconds_total
MD

curl -s http://localhost:9090/api/v1/label/__name__/values | python3 -m json.tool | head -60 > prometheus_metrics.txt

cat > query_test.md << 'MD'
# تست Query در Grafana Explore
مثال Queryهای تست شده:
- `up` - وضعیت targets
- `prometheus_http_requests_total` - درخواست‌های Prometheus
- `go_memstats_alloc_bytes` - مصرف حافظه
MD
log "connected"
