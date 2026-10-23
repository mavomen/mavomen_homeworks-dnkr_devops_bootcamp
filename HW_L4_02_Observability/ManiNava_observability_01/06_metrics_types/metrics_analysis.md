# تحلیل 5 Metric مختلف

1. **up** (Gauge) - وضعیت هر target (1 = سالم، 0 = down)
2. **prometheus_http_requests_total** (Counter) - تعداد درخواست‌های HTTP به Prometheus
3. **go_gc_duration_seconds** (Summary/Histogram) - زمان Garbage Collection در Go
4. **process_cpu_seconds_total** (Counter) - زمان CPU مصرف شده توسط فرآیند
5. **process_resident_memory_bytes** (Gauge) - حافظه RAM مصرف شده توسط فرآیند

هر کدام اطلاعات مفیدی درباره سلامت و عملکرد Prometheus ارائه می‌دهند.
