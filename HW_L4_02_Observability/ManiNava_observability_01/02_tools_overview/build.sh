#!/bin/bash
source "$(dirname "$0")/../lib/common.sh"
cd "$SUB/02_tools_overview"
cat > metrics_tools.md << 'MD'
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
MD

cat > logging_tracing_tools.md << 'MD'
# بررسی ابزارهای Logging و Tracing

## Logging Tools

| ابزار | توضیح | مزایا |
|---|---|---|
| **ELK Stack (Elasticsearch, Logstash, Kibana)** | Logstash لاگ‌ها را جمع‌آوری/پردازش، Elasticsearch ذخیره و ایندکس، Kibana نمایش می‌دهد | قدرتمند، کامل، بسیار پرکاربرد |
| **Loki** | توسط Grafana Labs توسعه یافته، با Prometheus الهام گرفته و با Grafana یکپارچه است | سبک، کم‌حجم، عالی برای Kubernetes |
| **Fluentd/Fluent Bit** | Collector برای جمع‌آوری و فوروارد لاگ‌ها به مقصدهای مختلف (Elasticsearch, Loki) | انعطاف‌پذیر، سبک (Fluent Bit)، استاندارد در Observability Pipeline |

## Tracing Tools

| ابزار | توضیح | تفاوت |
|---|---|---|
| **Jaeger** | ابزار متن‌باز برای Distributed Tracing، توسعه یافته توسط Uber | ساده، پرکاربرد، مناسب برای Tracing در میکروسرویس‌ها |
| **Zipkin** | یکی از اولین ابزارهای Tracing، ساده و سبک | کمتر پیچیده ولی امکانات کمتری نسبت به Jaeger دارد |
| **OpenTelemetry** | استاندارد و مجموعه SDK برای جمع‌آوری Traces/Metrics/Logs | نقش یکپارچه‌کننده: قبل از ارسال به Jaeger/Prometheus/Loki استانداردسازی می‌کند |

## جدول مقایسه کلی
| دسته | بهترین گزینه Self-hosted | بهترین گزینه ساده با Grafana | مناسب برای |
|---|---|---|---|
| Logging | ELK | Loki | ELK برای جستجوی پیشرفته، Loki برای ادغام با Grafana |
| Tracing | Jaeger + OpenTelemetry | Jaeger | OpenTelemetry برای آینده‌نگری توصیه می‌شود |
MD
log "created 02_tools_overview/*.md"
