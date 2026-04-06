# بوابة تحقق آمنة لإزالة حقول `code` (2026-04-07)

## الهدف
تأكيد أن إزالة حقول الكود في الوحدات المالية المستهدفة مطبقة فعليًا في قاعدة البيانات، بدون تنفيذ أي عملية مدمرة.

## ما تم إضافته
- سكربت تحقق في الباك إند:
  - `backend/scripts/verify-code-retirement.cjs`
- أمر تشغيل مباشر:
  - `npm run verify:code-retirement`

## الأعمدة التي يتحقق منها السكربت
- `branches.code`
- `currencies.code`
- `chart_of_accounts.account_code`
- `payment_gateways.provider_code`
- `fin_tax_codes.tax_code`
- `financial_categories.code`
- `financial_funds.code`
- `cost_centers.code`

## نتيجة التشغيل الحالية
- جميع الأعمدة المتقاعدة غير موجودة في المخطط الحالي.
- تم التحقق من أرشيف القيم في `retired_code_archive` وظهرت صفوف محفوظة لكل عمود متقاعد.

## طريقة التشغيل
من مجلد:
- `school-erp-platform/backend`

نفذ:
```bash
npm run verify:code-retirement
```

إذا فشل الفحص:
- سيطبع السكربت أسماء الأعمدة التي ما زالت موجودة.
- يجب إيقاف أي نشر حتى معالجة السبب (migrations غير مطبقة أو rollback غير مكتمل).

## بوابة الدمج/النشر (CI)
- تمت إضافة خطوة إلزامية داخل:
  - `.github/workflows/finance-quality.yml`
- اسم الخطوة:
  - `Verify retired finance code columns`
- هذا يعني أن أي `PR` أو `push` على `main/master` (ضمن نطاق ملفات المنصة) سيفشل تلقائيًا إذا عادت أعمدة الكود المتقاعدة.
