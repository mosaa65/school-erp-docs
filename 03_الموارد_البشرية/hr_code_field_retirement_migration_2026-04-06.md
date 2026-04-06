# تقرير تنفيذ إيقاف حقل `code` (Frontend + Backend + DB)

تاريخ التحديث: 2026-04-06

## الهدف

تنفيذ خطة آمنة من 3 إصدارات لإلغاء إدخال حقل `code` يدويًا، ثم نقل النظام للاعتماد على معرفات بديلة، ثم تجهيز قاعدة البيانات للإسقاط النهائي للأعمدة دون فقدان بيانات.

## الإصدار 1 - إيقاف إدخال الكود من الواجهة (مكتمل)

تم حذف إدخال `code` من نماذج الإنشاء/التعديل في الوحدات التي كانت تعتمد عليه مباشرة في العمل اليومي (أكاديمي/موارد بشرية/مالية/Lookups ضمن نطاق التنفيذ الحالي)، مع الإبقاء على الاستخدام الداخلي عند الحاجة للتوافق.

أمثلة من الواجهة التي تم تحديثها:

- `academic-years`, `academic-terms`, `academic-months`
- `grade-levels`, `subjects`, `sections`, `classrooms`
- `employee-departments`, `talents`
- `branches`, `currencies`, `chart-of-accounts`
- مجموعة `lookup-*` و`promotion-decisions` و`annual-statuses` و`homework-types` و`grading-policy-components`

النتيجة:

- المستخدم لم يعد مطالبًا بكتابة `code` في النماذج.
- تقليل أخطاء الإدخال اليدوي.

## الإصدار 2 - تحويل منطق الباك إند (مكتمل)

تم نقل الباك إند للتعامل مع غياب `code` عبر معرفات بديلة (الاسم/المعرّف/النوع) بدل الاعتماد على `accountCode/providerCode/taxCode` في مسارات المالية المستهدفة.

ما تم تنفيذه:

- إضافة أداة توليد أكواد:
  - `backend/src/common/utils/auto-code.ts`
- إضافة fallback مركزي في:
  - `backend/src/main.ts`
- تحديث DTOs وServices في الوحدات المستهدفة لقبول إنشاء السجل بدون `code` يدوي.

النتيجة:

- العمليات لا تنكسر عند حذف خانة `code` من الواجهة.
- السلوك متوافق مع البيانات الحالية.

## الإصدار 3 - ترحيل قاعدة البيانات بشكل آمن (مكتمل نهائيًا)

تم تنفيذ الترحيل على مرحلتين:

- Migration أرشفة القيم:
  - `backend/prisma/migrations/20260406120000_retire_finance_code_columns/migration.sql`
- Migration الإسقاط النهائي:
  - `backend/prisma/migrations/20260406183000_drop_finance_code_columns/migration.sql`
- إنشاء جدول أرشفة:
  - `retired_code_archive`
- نسخ القيم من الجداول المالية المستهدفة إلى جدول الأرشفة.
- ثم إسقاط الأعمدة نهائيًا بعد فك الارتباط التطبيقي.

الأعمدة التي تم إسقاطها:

- `branches.code`
- `currencies.code`
- `chart_of_accounts.account_code`
- `payment_gateways.provider_code`
- `fin_tax_codes.tax_code`
- `financial_categories.code`
- `financial_funds.code`
- `cost_centers.code`

## كيف تختبر الآن

## 1) Frontend

1. شغّل الواجهة:
   - `cd school-erp-platform/frontend`
   - `npm run start`
2. افتح شاشات الوحدات المحددة أعلاه.
3. تأكد أن نماذج الإنشاء/التعديل لا تطلب إدخال `code` يدويًا.
4. أنشئ سجلًا جديدًا وتأكد أن العملية تنجح.

## 2) Backend

1. شغّل الباك إند:
   - `cd school-erp-platform/backend`
   - `npm run start:dev`
2. اختبر إنشاء سجل (من Swagger أو الواجهة) بدون `code`.
3. تأكد أن السجل يُنشأ بنجاح بالاعتماد على الاسم/المعرّف (بدون حقول code مالية).

## 3) Database

1. نفّذ الترحيل:
   - `cd school-erp-platform/backend`
   - `npx prisma migrate deploy`
2. تحقق من وجود جدول:
   - `retired_code_archive`
3. تحقق من وجود بيانات مؤرشفة بداخله.

## حالة التحقق الفني الحالية (بعد الإغلاق النهائي)

- Frontend Typecheck: ناجح.
- Backend Build/Typecheck: ناجح.
- Prisma Generate: ناجح.

## ملاحظة تنفيذية

- تم أيضًا تصحيح SQL الأرشفة ليكون متوافقًا مع MySQL (`INSERT IGNORE` بدل `ON CONFLICT`).
- تم تحديث seed scripts وخدمات مالية/موارد بشرية مرتبطة كي لا تعتمد على الحقول المسقطة.
