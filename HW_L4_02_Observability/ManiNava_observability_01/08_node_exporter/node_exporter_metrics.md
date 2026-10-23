# Node Exporter Metrics

## توضیح هر Metric
- **node_cpu_seconds_total:** Counter زمان مصرفی CPU در هر mode (user/system/idle/iowait). با rate() قابل استفاده برای محاسبه درصد CPU
- **node_memory_MemTotal_bytes:** Gauge کل حافظه فیزیکی سیستم
- **node_filesystem_size_bytes:** Gauge حجم هر پارتیشن فایل‌سیستم
- **rate(node_cpu_seconds_total[5m]):** محاسبه نرخ تغییر، برای ترند و Alert مناسب است

## نحوه استفاده در Monitoring
با ترکیب این Metrics می‌توانیم داشبوردی برای CPU/Memory/Disk بسازیم و در صورت عبور از آستانه، Alert فعال کنیم.

## دیگر Metrics
Node Exporter با پیشوند `node_` صدها Metric ارائه می‌دهد: node_load1/5/15، node_network_*، node_disk_* و...
