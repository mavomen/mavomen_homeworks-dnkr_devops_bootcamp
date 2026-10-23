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
