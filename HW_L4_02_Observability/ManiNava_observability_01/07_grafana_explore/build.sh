#!/bin/bash
source "$(dirname "$0")/../lib/common.sh"
cd "$SUB/07_grafana_explore"
log "explore"

cat > explore_usage.md << 'MD'
# کار با Grafana Explore

## دسترسی
Grafana → Explore → انتخاب Data Source: Prometheus

## Query های اجرا شده
1. `node_cpu_seconds_total` - زمان CPU
2. `node_memory_MemTotal_bytes` - کل حافظه
3. `node_filesystem_size_bytes` - حجم فایل‌سیستم
4. `rate(node_cpu_seconds_total[5m])` - نرخ استفاده CPU در 5 دقیقه اخیر

## توضیح هر Metric
- **node_cpu_seconds_total:** Counter که زمان مصرفی هر CPU mode را نشان می‌دهد
- **node_memory_MemTotal_bytes:** Gauge برای کل حافظه سیستم
- **node_filesystem_size_bytes:** Gauge برای حجم هر پارتیشن
- **rate(...[5m]):** محاسبه نرخ تغییر در بازه 5 دقیقه‌ای (مفید برای CPU utilization)

## استفاده در Monitoring
با این Metrics می‌توانیم CPU، Memory، Disk را نظارت و Alert تنظیم کنیم.
MD
log "explore done"
