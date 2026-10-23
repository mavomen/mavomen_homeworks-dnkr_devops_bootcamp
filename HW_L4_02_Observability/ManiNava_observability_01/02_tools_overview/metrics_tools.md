# بررسی ابزارهای Metrics

## 1. Prometheus
- **چیست:** یک ابزار متن‌باز برای Monitoring و Alerting با Time-Series Database
- **ویژگی‌ها:** Pull-based، PromQL، Service Discovery، Alertmanager
- **زمان استفاده:** برای نظارت بر سیستم‌ها، اپلیکیشن‌ها و میکروسرویس‌ها
- **Use Case واقعی:** نظارت بر Kubernetes Cluster و ایجاد Alert برای high CPU

## 2. InfluxDB
- **تفاوت با Prometheus:** InfluxDB بیشتر Push-based است، در حالی که Prometheus عمدتاً Pull-based عمل می‌کند. InfluxDB برای IoT و داده‌های پرسرعت عالی است.
- **Use Case واقعی:** جمع‌آوری داده‌های سنسورهای IoT

## 3. Datadog
- **نوع سرویس:** SaaS (Cloud-based)
- **مزایا:** داشبوردهای آماده، یکپارچه‌سازی زیاد، APM، Log، Metrics یکجا
- **Use Case واقعی:** شرکت‌هایی که نمی‌خواهند زیرساخت Monitoring را مدیریت کنند

## 4. Amazon CloudWatch
- **مناسب برای:** محیط‌های AWS
- **ویژگی‌ها:** یکپارچه با EC2, Lambda, RDS
- **Use Case واقعی:** مانیتورینگ منابع AWS و تنظیم Alarms
