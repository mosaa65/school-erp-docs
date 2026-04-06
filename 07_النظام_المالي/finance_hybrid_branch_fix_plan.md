# خطة إصلاح نموذج تعدد الفروع الهجين — النظام المالي

## الهدف

تحويل ملاحظات المراجعة الخاصة بـ **النموذج الهجين لتعدد الفروع** إلى خطة تنفيذية عملية وقابلة للتنفيذ، بحيث يصبح السلوك الفعلي مطابقًا للتعريف التالي:

- `branch_id = NULL` يعني **سجلًا مشتركًا** يمكن استخدامه عبر الفروع.
- `branch_id = <value>` يعني **سجلًا خاصًا بفرع محدد**.
- استعلامات الفرع يجب أن ترى:
  - السجلات الخاصة بالفرع
  - والسجلات المشتركة `NULL`

## الحالة الحالية باختصار

الوضع الحالي جيد على مستوى **وجود الحقول** ودعم `branchId` في أغلب الوحدات، لكنه **غير مكتمل وظيفيًا كنموذج هجين** لسببين رئيسيين:

1. كثير من الاستعلامات تستخدم `branchId = query.branchId` بشكل حرفي، فتُخفي السجلات المشتركة.
2. بعض التقارير تعتمد على `currentBalance` في `chart_of_accounts`، وهو رصيد واحد على مستوى الحساب، وليس رصيدًا مفصولًا حسب الفرع.

### تحديث الحالة بعد التنفيذ

- تم تنفيذ helper موحدة للفلترة الهجينة داخل الـ backend.
- تم إصلاح `trial-balance`, `income-statement`, و`balance-sheet` لتُحسب من القيود المرحّلة عند الفلترة حسب الفرع.
- تم إضافة guardrails في `journal-entries` لمنع عدم الاتساق بين `entry.branchId` و`line.branchId` وفرع الحساب.
- تم توسيع السلوك الهجين إلى `budgets`, `student-invoices`, `cost-centers`, و`transport revenue report`.
- توجد الآن backend e2e تثبت:
  - ظهور السجلات المشتركة داخل استعلام الفرع
  - ورفض القيود المختلطة
- توجد الآن frontend coverage مخصصة، والحزمة المالية الأمامية تمر محليًا بالكامل.

> **الحالة النهائية داخل الريبو بتاريخ 2026-03-30:** مغلق وظيفيًا واختباريًا، والمتبقي صيانة مستقبلية فقط عند إضافة وحدات جديدة.

---

## قرار التصميم المطلوب اعتماده

قبل أي refactor واسع، يجب اعتماد القرار التالي رسميًا:

### القرار المقترح

- **المرجعيات** مثل:
  - `chart_of_accounts`
  - `document_sequences`
  - `budgets`
  - `cost_centers`
  يمكن أن تكون:
  - مشتركة (`branch_id = NULL`)
  - أو خاصة بفرع

- **العمليات التشغيلية** مثل:
  - `journal_entries`
  - `student_invoices`
  - `payment_transactions`
  يجب أن تكون:
  - إما مرتبطة بفرع واضح
  - أو يُوثق صراحة متى يسمح أن تكون عامة

- **التقارير حسب الفرع** يجب أن تُحسب من الحركة المحاسبية (`journal_entry_lines`) لا من الرصيد cache العام إذا كان الحساب مشتركًا.

---

## P0 — حرجة

### 1. توحيد semantics الاستعلام الهجين

#### المشكلة

بعض الخدمات تُطبّق فلترة الفرع بهذه الصيغة:

- `branchId: query.branchId`

وهذا يعني:

- عند اختيار فرع معيّن، يتم استبعاد السجلات المشتركة `NULL`

#### المطلوب

إضافة helper موحد لسلوك الفلترة الهجينة، مثل:

- إذا لم يُرسل `branchId`: أرجع كل السجلات
- إذا أُرسل `branchId`: أرجع
  - `branchId = requested`
  - أو `branchId IS NULL`

#### الملفات المستهدفة

- `school-erp-platform/backend/src/modules/finance/chart-of-accounts/chart-of-accounts.service.ts`
- `school-erp-platform/backend/src/modules/finance/student-invoices/student-invoices.service.ts`
- `school-erp-platform/backend/src/modules/finance/budgets/budgets.service.ts`
- `school-erp-platform/backend/src/modules/finance/financial-reports/financial-reports.service.ts`
- أي services مالية أخرى تستخدم نفس النمط مباشرة

#### معيار القبول

- استعلام الفرع يعرض السجلات الخاصة به + المشتركة
- الاستعلام العام بدون `branchId` لا ينكسر
- لا يتم إرجاع سجلات فروع أخرى

---

### 2. منع الاعتماد على `currentBalance` في التقارير الفرعية

#### المشكلة

التقارير التالية تقرأ `currentBalance` من الحساب مباشرة:

- `trial-balance`
- `income-statement` في بعض المسارات
- `balance-sheet`

وهذا خطر عندما يكون الحساب مشتركًا بين عدة فروع.

#### المطلوب

اعتماد rule واضح:

- أي تقرير **حسب الفرع** يجب أن يُحسب من `journal_entry_lines`
- `currentBalance` يبقى مفيدًا فقط:
  - في الملخص العام
  - أو عندما لا يوجد فصل فرعي مطلوب

#### الملفات المستهدفة

- `school-erp-platform/backend/src/modules/finance/financial-reports/financial-reports.service.ts`

#### معيار القبول

- `trial-balance?branchId=...` لا يعتمد على رصيد حساب عالمي
- `balance-sheet?branchId=...` لا يتأثر بحركات الفروع الأخرى
- `income-statement?branchId=...` متسق مع القيود المرحّلة لنفس الفرع فقط

---

### 3. إضافة guardrails بين فرع القيد وفرع السطور وفرع الحساب

#### المشكلة

يمكن حاليًا إنشاء:

- `journalEntry.branchId = A`
- و`journalEntryLine.branchId = B`
- أو ربط سطر بحساب branch-specific لفرع مختلف

بدون تحقق صارم.

#### المطلوب

إضافة قواعد تحقق في `journal-entries`:

- إذا كان القيد له `branchId`:
  - كل line يجب أن تكون:
    - نفس الفرع
    - أو `NULL` فقط إذا كان هذا مسموحًا ومبررًا
- إذا كان الحساب branch-specific:
  - يجب أن يطابق فرع السطر أو فرع القيد
- إذا كان الحساب shared (`NULL`):
  - يسمح استخدامه من أي فرع

#### الملفات المستهدفة

- `school-erp-platform/backend/src/modules/finance/journal-entries/journal-entries.service.ts`
- DTOs ذات العلاقة عند الحاجة

#### معيار القبول

- لا يمكن إنشاء قيد مختلط الفروع بلا قصد
- رسائل الخطأ واضحة
- لا ينكسر happy path الحالي

---

## P1 — عالية

### 4. توحيد سياسة الكيانات: Shared vs Branch-Specific

#### المطلوب

إعداد جدول قرار رسمي يوضح لكل كيان:

- هل يسمح أن يكون `NULL`
- هل يجب أن يكون branch-specific
- هل يورّث للفروع أم لا

#### الكيانات التي يجب حسمها

- `chart_of_accounts`
- `journal_entries`
- `journal_entry_lines`
- `student_invoices`
- `budgets`
- `document_sequences`
- `cost_centers`

#### المخرجات

- تحديث توثيقي في ملفات المالية
- وربما comments/guards خفيفة في الكود عند المواضع الحساسة

---

### 5. توسيع التقارير الحساسة التي ما زالت جزئية

#### المطلوب

بعد إصلاح `trial-balance` و`balance-sheet` و`income-statement`، يتم توسيع نفس المبدأ إلى:

- `accounts receivable aging`
- `vat-report`
- `budget-vs-actual`

#### الملفات المستهدفة

- `school-erp-platform/backend/src/modules/finance/financial-reports/financial-reports.service.ts`
- `school-erp-platform/backend/src/modules/finance/budgets/budgets.service.ts`

#### معيار القبول

- سلوك موحد لكل التقارير عند إرسال `branchId`

---

### 6. مراجعة الواجهة لعرض السجلات المشتركة بوضوح

#### المطلوب

في الصفحات التي تعتمد على branch filters، يجب أن تظهر السجلات المشتركة بشكل واضح بدل أن تبدو “ناقصة”:

- إظهار badge مثل:
  - `مشترك`
  - أو `كل الفروع`

#### الصفحات الأولية

- `chart-of-accounts`
- `budgets`
- `student-invoices` إذا كان السماح بـ shared invoices مقصودًا
- `financial-reports`

#### الحالة الحالية

- تم تحسين الواجهة لعرض السجل المشترك بصياغة واضحة مثل `كافة الفروع`.
- توجد الآن `Playwright` coverage مخصصة لسلوك:
  - ظهور السجلات المشتركة داخل نتائج فرع محدد
  - وإظهار التسمية المناسبة في `student-invoices`, `budgets`, `cost-centers`, و`chart-of-accounts`

---

## P2 — متوسطة

### 7. بناء suite اختبار مخصصة للنموذج الهجين

#### المطلوب

إضافة اختبارات backend تغطي صراحة:

1. حساب shared + قيد branch-specific
2. query بفرع معيّن يجب أن يرى:
   - shared
   - local
   - لا يرى foreign branch
3. `trial-balance` حسب الفرع
4. `income-statement` حسب الفرع
5. `balance-sheet` حسب الفرع
6. رفض line account من فرع آخر

#### الملف المقترح

- `school-erp-platform/backend/test/finance-hybrid-branch-model.e2e-spec.ts`

#### أمر التشغيل المقترح

```bash
npm run test:e2e:finance
```

---

### 8. إضافة smoke/deep flows للواجهة حول الفرع المشترك

#### المطلوب

اختبارات Frontend تؤكد:

- عند اختيار فرع، تظهر السجلات المشتركة
- تظهر علامة `كل الفروع` أو `مشترك`
- لا تظهر سجلات فرع آخر

#### الملفات المقترحة

- `school-erp-platform/frontend/tests/e2e/finance-smoke.spec.ts`
- أو spec مستقلة:
  - `frontend/tests/e2e/finance-hybrid-branch.spec.ts`

---

## ترتيب التنفيذ المقترح

### المرحلة 1

1. إصلاح helper الفلترة الهجينة
2. إصلاح تقارير `trial-balance`
3. إصلاح تقارير `income-statement`
4. إصلاح `balance-sheet`

الحالة:
- منجزة

### المرحلة 2

5. إضافة guardrails في `journal-entries`
6. توسيع `budget-vs-actual` و`aging` و`vat-report`

الحالة:
- `journal-entries` guardrails منجزة
- `aging` و`vat-report` أصبحت متوافقة مع semantics الهجينة
- `budget-vs-actual` أصبح يستخدم الفلترة الهجينة في طبقة الحركة

### المرحلة 3

7. إضافة backend e2e مخصصة
8. إضافة frontend coverage
9. توثيق السياسة النهائية لكل كيان

الحالة:
- backend e2e منجزة داخل suite المالية الحالية
- frontend coverage منجزة عبر `finance-hybrid-branch.spec.ts`
- المتبقي: توثيق السياسة النهائية لكل كيان عند الحاجة المرجعية فقط

---

## المخاطر إذا لم يُصلح

- تقارير فرعية غير صحيحة محاسبيًا
- إخفاء الحسابات أو الميزانيات المشتركة عند فلترة الفرع
- قبول قيود مختلطة الفروع بلا قصد
- صعوبة كبيرة في اعتماد النظام لمدارس متعددة الفروع تشغيليًا

---

## Definition of Done

- أي استعلام بفلتر `branchId` يضم:
  - بيانات الفرع
  - والبيانات المشتركة `NULL`
- التقارير الفرعية لا تعتمد على `currentBalance` العام للحسابات المشتركة
- لا يمكن إنشاء قيد محاسبي inconsistent بين فرع القيد وفرع السطور والحساب
- توجد backend e2e تغطي السيناريو الهجين صراحة
- الواجهة تعرض السجلات المشتركة بشكل مفهوم للمستخدم
