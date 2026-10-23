#!/bin/bash
source "$(dirname "$0")/../lib/common.sh"
cd "$SUB/06_metrics_types"
log "metrics types"

cat > metrics_types_explanation.md << 'MD'
# انواع Metrics در Prometheus

| نوع | توضیح | مثال عملی |
|---|---|---|
| **Counter** | فقط افزایش پیدا می‌کند، هرگز کاهش نمی‌یابد. برای شمارش رویدادها مناسب است. | `http_requests_total` - تعداد کل درخواست‌های HTTP |
| **Gauge** | می‌تواند افزایش یا کاهش یابد. برای مقادیر لحظه‌ای مناسب است. | `node_memory_MemAvailable_bytes` - حافظه در دسترس |
| **Histogram** | نمونه‌برداری از observations و شمارش آن‌ها در buckets. امکان محاسبه quantile. | `http_request_duration_seconds_bucket` - توزیع زمان پاسخ |
| **Summary** | مشابه Histogram اما quantile‌ها مستقیماً محاسبه و ذخیره می‌شوند. | `http_request_duration_seconds{quantile="0.9"}` |

مثال عملی واقعی:
- Counter: تعداد ورود به سایت
- Gauge: دمای سرور یا تعداد کاربران آنلاین
- Histogram: زمان بارگذاری صفحات
- Summary: SLA monitoring با p99
MD

curl -s http://localhost:9090/api/v1/label/__name__/values > prometheus_metrics_analysis.txt
echo "---" >> prometheus_metrics_analysis.txt

cat > metrics_analysis.md << 'MD'
# تحلیل 5 Metric مختلف

1. **up** (Gauge) - وضعیت هر target (1 = سالم، 0 = down)
2. **prometheus_http_requests_total** (Counter) - تعداد درخواست‌های HTTP به Prometheus
3. **go_gc_duration_seconds** (Summary/Histogram) - زمان Garbage Collection در Go
4. **process_cpu_seconds_total** (Counter) - زمان CPU مصرف شده توسط فرآیند
5. **process_resident_memory_bytes** (Gauge) - حافظه RAM مصرف شده توسط فرآیند

هر کدام اطلاعات مفیدی درباره سلامت و عملکرد Prometheus ارائه می‌دهند.
MD
log "metrics done"
