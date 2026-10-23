#!/bin/bash
source "$(dirname "$0")/../lib/common.sh"
cd "$SUB/01_observability_concepts"

cat > importance_of_observability.md << 'MD'
# اهمیت Observability در DevOps

## 1.1 تفاوت Observability با Monitoring
- **Monitoring:** واکنشی است. با هشدارهای از پیش تعریف شده به ما می‌گوید چه چیزی خراب شده است.
- **Observability:** پیشگیرانه و کاوشگر است. به ما اجازه می‌دهد بدون دانستن دقیق مشکل، ریشه آن را پیدا کنیم.

## 2. چرا Observability در DevOps اهمیت دارد؟
1. **کاهش زمان تشخیص و رفع مشکل (MTTR):** با استفاده از logs، metrics و traces سریع‌تر می‌توان علت را یافت.
2. **بهبود کیفیت تحویل:** در CI/CD با دید بهتر می‌توان ریسک انتشار را کاهش داد.
3. **اعتماد به سیستم‌های توزیع‌شده:** در میکروسرویس‌ها نیاز به دید یکپارچه داریم.

## 3. سه ستون Observability (Three Pillars)
- **Metrics:** داده‌های عددی در طول زمان (CPU، Memory، Request Count)
- **Logs:** رویدادهای گسسته با جزئیات (خطاها، لاگ‌های اپلیکیشن)
- **Traces:** مسیر یک Request در سراسر سرویس‌های مختلف

## 4. سناریو عملی: وبسایت کند شده
فرض کنید وبسایت کند شده است:
- **Metrics:** با Prometheus متوجه می‌شویم CPU یا Latency افزایش یافته
- **Logs:** لاگ‌های اپلیکیشن یا سرور خطاهای مرتبط را نشان می‌دهد
- **Traces:** با Jaeger/Tracing می‌توان مسیر Request را دنبال کرد و گلوگاه را پیدا کرد
MD

cat > key_concepts.md << 'MD'
# مفاهیم کلیدی Observability

## 1. Metrics و انواع آن
Metrics داده‌های عددی هستند که در بازه‌های زمانی ثبت می‌شوند.

| نوع | توضیح | مثال |
|---|---|---|
| **Counter** | تنها افزایش می‌یابد (ریست در restart) | تعداد کل درخواست‌های HTTP |
| **Gauge** | می‌تواند بالا و پایین برود | استفاده CPU، حافظه مصرفی |
| **Histogram** | توزیع مقادیر را در buckets نشان می‌دهد | مدت زمان پاسخ درخواست‌ها |
| **Summary** | مشابه Histogram ولی با quantile محاسبه شده | p50، p90، p99 زمان پاسخ |

## 2. تفاوت Logs (Structured vs Unstructured)
- **Unstructured Logs:** متن آزاد، سخت برای جستجو و تحلیل (مثال: `Error occurred at ...`)
- **Structured Logs:** قالب مشخص JSON، قابل فیلتر و تجزیه (مثال: `{"level":"error","service":"api","msg":"timeout"}`)

## 3. Traces و Distributed Tracing
**Tracing** مسیر کامل یک درخواست از ورود تا خروج را در سیستم توزیع‌شده دنبال می‌کند. هر گام با **Span** مشخص شده و با **Trace ID** به هم متصل می‌شوند. برای یافتن گلوگاه در معماری میکروسرویس کاربرد دارد.

## 4. تفاوت Alert و Notification
- **Alert:** شرط تعریف شده‌ای است که هنگام برآورده شدن، سیستم را آگاه می‌کند (مثال: CPU > 80% برای 5 دقیقه)
- **Notification:** اقدام بعدی برای اطلاع‌رسانی (Email، Slack، PagerDuty) پس از فعال شدن Alert

## 5. SLO / SLI / SLA
| مفهوم | توضیح | مثال عملی |
|---|---|---|
| **SLI (Service Level Indicator)** | معیار قابل اندازه‌گیری | درصد درخواست‌های موفق با زمان < 200ms |
| **SLO (Service Level Objective)** | هدف داخلی برای SLI | 99.9% درخواست‌ها کمتر از 200ms پاسخ می‌دهند |
| **SLA (Service Level Agreement)** | توافق قراردادی با مشتری با جریمه | اگر SLO زیر 99.9% برود، تخفیف لحاظ می‌شود |

**ارتباط:** SLI را اندازه می‌گیریم → سعی می‌کنیم به SLO برسیم → SLA الزام قراردادی است.
MD
echo "---"
log "created 01_observability_concepts/importance_of_observability.md and key_concepts.md"
