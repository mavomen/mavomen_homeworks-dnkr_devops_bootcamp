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
