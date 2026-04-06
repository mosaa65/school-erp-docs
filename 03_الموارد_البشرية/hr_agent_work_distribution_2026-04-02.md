# توزيع المهام المتبقية على الوكلاء

تاريخ الإعداد: `2026-04-02`

## 1. الهدف

هذا التوزيع يغطي الأعمال المتبقية بعد إغلاق المرحلة الثالثة من HR، مع فصل واضح بين الوكلاء لتقليل التداخل والأخطاء ورفع جودة التسليم.

المبدأ الأساسي:

- كل وكيل يملك نطاقًا واضحًا.
- لا يوجد تعديل متوازي على نفس الملفات الأساسية إلا بعد تنسيق صريح.
- أي تغيير في قاعدة البيانات يجب أن يسبقه حصر أثر واضح، ويتبعه:
  - `backend build`
  - `frontend typecheck`
  - اختبارات مستهدفة
  - تحديث التوثيق

## 1.1 حالة التشغيل الحالية

تم اعتماد بدء التنفيذ الفعلي بتاريخ `2026-04-02`.

حالة الدفعة الأولى:

- `Coordinator`: نشط
- `Worker C - Leaves + Entitlement Policies`: started
- `Worker B - Contracts + Documents`: queued
- `Worker D - Lifecycle + Notifications + HR Reports`: queued
- `Worker A - Payroll Engine Foundation`: blocked pending `Worker C`

قاعدة التشغيل الحالية:

- لا يتم إطلاق `Worker A` قبل تثبيت مخرجات الإجازات والسياسات.
- أي تغيير في الملفات المشتركة يبقى تحت تنسيق `Coordinator` فقط.

## 2. الوكلاء ومسؤولياتهم

### الوكيل A: Payroll Engine Foundation

الهدف:

- تحويل تكاملات HR المالية الحالية من `journal posting` يدوي نسبيًا إلى نواة Payroll فعلية.

الملكية الوظيفية:

- هيكل الراتب.
- البدلات.
- الخصومات الدورية.
- السلف.
- دورة `payroll run`.
- مخرجات المسير وقسيمة الراتب.
- الربط المالي النهائي مع القيود.

الملكية التقنية الأساسية:

- `school-erp-platform/backend/src/modules/finance/hr-integrations/**`
- أي module جديدة خاصة بالرواتب داخل:
  - `school-erp-platform/backend/src/modules/finance/**`
  - أو `school-erp-platform/backend/src/modules/payroll/**`
- `school-erp-platform/frontend/src/features/hr-integrations/**`
- أي صفحات frontend جديدة للرواتب
- `school-erp-platform/backend/test/**` الخاصة بالرواتب والمالية

ممنوع عليه بدون تنسيق:

- تعديل منطق الإجازات نفسه داخل:
  - `employee-leaves`
  - `employee-leave-balances`
- تعديل العقود أو المستندات إلا إذا كان الربط المالي يتطلب interface متفقًا عليه

التسليمات المطلوبة:

1. نموذج بيانات Payroll واضح.
2. Run شهري قابل للتشغيل.
3. احتساب أولي يعتمد على:
   - الراتب المرجعي من العقود أو الملف الوظيفي
   - الإجازات غير المدفوعة
   - الخصومات الدورية
4. قيود مالية ناتجة من payroll run بدل إدخال إجمالي يدوي فقط.
5. اختبارات backend وواجهة لمسار payroll run.

شرط البدء الحقيقي:

- يعتمد على حسم قواعد الإجازات غير المدفوعة من الوكيل C.

الأولوية:

- `P1` بعد تثبيت مخرجات الوكيل C.

### الوكيل B: Contracts + Documents Institutionalization

الهدف:

- تحويل العقود والمستندات من نواة تشغيلية إلى ملف مؤسسي متكامل.

الملكية الوظيفية:

- رفع ملف ثنائي مباشر.
- صلاحيات المعاينة والتحميل.
- تصنيفات معيارية للمستندات.
- ربط المستندات بالعقود والقرارات.
- سجل تجديد/تمديد العقود.
- مرفقات العقود.
- تنبيهات انتهاء مجدولة بدل التشغيل اليدوي فقط.

الملكية التقنية الأساسية:

- `school-erp-platform/backend/src/modules/employee-documents/**`
- `school-erp-platform/backend/src/modules/employee-contracts/**`
- `school-erp-platform/frontend/src/features/employee-documents/**`
- `school-erp-platform/frontend/src/features/employee-contracts/**`
- `school-erp-platform/backend/prisma/schema.prisma`
- `school-erp-platform/backend/prisma/migrations/**`
- اختبارات E2E وbackend المرتبطة بهذين المسارين

ممنوع عليه بدون تنسيق:

- تعديل قناة الإشعارات العامة نفسها إلا بحد أدنى لازم
- تعديل منطق Payroll

التسليمات المطلوبة:

1. رفع مباشر للملفات مع تخزين منظم.
2. معاينة وتحميل مضبوطان بالصلاحيات.
3. ربط المستندات بالعقود.
4. Contract renewal / extension log.
5. Scheduled expiry alerts للعقود والوثائق.
6. اختبارات تغطي:
   - upload
   - preview/download authorization
   - renewal flow
   - scheduled alert generation

الأولوية:

- `P1` ويمكنه العمل مباشرة بالتوازي.

### الوكيل C: Leaves + Entitlement Policies

الهدف:

- تعميق الإجازات وأرصدة الإجازات من مستوى baseline policy إلى policy engine أوضح.

الملكية الوظيفية:

- قواعد استحقاق أدق حسب:
  - نوع التوظيف
  - مدة الخدمة
  - نوع الإجازة
- سحب أو إلغاء الطلب وفق سياسة.
- multi-step approvals إن لزم.
- accrual / carry-forward مجدول.
- الأثر المالي للإجازة غير المدفوعة أو الجزئية.

الملكية التقنية الأساسية:

- `school-erp-platform/backend/src/modules/employee-leaves/**`
- `school-erp-platform/backend/src/modules/employee-leave-balances/**`
- `school-erp-platform/frontend/src/features/employee-leaves/**`
- `school-erp-platform/frontend/src/features/employee-leave-balances/**`
- اختبارات E2E والاختبارات الخلفية الخاصة بالإجازات

ممنوع عليه بدون تنسيق:

- تعديل وحدات Payroll المالية
- تعديل وحدات العقود والمستندات

التسليمات المطلوبة:

1. سياسة استحقاق أكثر دقة وقابلة للتوسعة.
2. Workflow أعمق لاعتماد الإجازات.
3. Withdraw / cancel policy.
4. scheduled accrual / annual rollover policy.
5. واجهة توضح policy effect بوضوح.
6. contract واضح مع الوكيل A للأثر المالي:
   - unpaid leave days
   - partial paid impact

الأولوية:

- `P1` لأنه يفتح الطريق الصحيح للوكيل A.

### الوكيل D: Lifecycle + Notifications + HR Management Reports

الهدف:

- تحويل دورة الحياة والإشعارات وتقارير HR إلى طبقة تشغيل وإدارة مؤسسية.

الملكية الوظيفية:

- قوالب مهام onboarding/offboarding.
- التشغيل التلقائي عند:
  - التعيين
  - إنهاء الخدمة
- SLA escalation.
- badge عام للإشعارات.
- notification preferences.
- قنوات إضافية مستقبلية.
- تقارير HR الإدارية:
  - الموظفون ناقصو البيانات
  - الموظفون بدون مستندات
  - العقود/الهويات القريبة من الانتهاء
  - الغياب والتأخر
  - أثر التدريب على الأداء

الملكية التقنية الأساسية:

- `school-erp-platform/backend/src/modules/employee-lifecycle-checklists/**`
- `school-erp-platform/backend/src/modules/user-notifications/**`
- `school-erp-platform/backend/src/modules/hr-reports/**`
- `school-erp-platform/frontend/src/features/employee-lifecycle-checklists/**`
- `school-erp-platform/frontend/src/features/user-notifications/**`
- صفحات التنقل والحماية المرتبطة بها

ممنوع عليه بدون تنسيق:

- تعديل منطق المستندات أو العقود أو الإجازات خارج interfaces مطلوبة للتقارير فقط

التسليمات المطلوبة:

1. lifecycle templates.
2. auto-trigger للمهام من أحداث HR.
3. escalations للمهام المتأخرة.
4. notification badge وتفضيلات المستخدم.
5. first wave من التقارير الإدارية العليا.
6. اختبارات workflow + notification + reports.

الأولوية:

- `P1` ويمكنه العمل مباشرة بالتوازي.

## 3. ترتيب التنفيذ المقترح

### الموجة الأولى: تنفيذ متوازٍ الآن

- الوكيل B
- الوكيل C
- الوكيل D

السبب:

- هذه المسارات مستقلة نسبيًا.
- تداخلها أقل.
- نتائجها ستغذي الوكيل A بدل أن يبدأ على افتراضات غير مستقرة.

### الموجة الثانية: بعد تثبيت سياسات الإجازات

- الوكيل A

السبب:

- Payroll بدون قواعد إجازات مستقرة سيؤدي إلى إعادة شغل.
- الربط المالي يجب أن يبنى على policy واضحة لا على سلوك مؤقت.

## 4. قواعد منع الأخطاء

### 4.1 حدود الملكية

- لا يفتح وكيل ملفًا مملوكًا لوكيل آخر إلا بعد تنسيق واعتماد.
- التغييرات المشتركة مثل:
  - `schema.prisma`
  - `client.ts`
  - `permissions.seed.ts`
  - `app-navigation.ts`
  تعد ملفات تكامل ويجب أن تمر عبر مراجعة تنسيقية.

### 4.2 بوابة التسليم لكل وكيل

لا يعتبر التسليم مقبولًا إلا إذا تحقق الآتي:

- `backend`: `npm run build`
- `frontend`: `npm run typecheck`
- اختبارات مستهدفة للمسار المعدل
- تحديث وثيقة التقدم أو وثيقة التسليم
- توضيح:
  - ما الذي تغير
  - ما الذي لم يغطَّ بعد
  - أي مخاطر تشغيلية متبقية

### 4.3 قاعدة التغييرات الكبيرة

إذا احتاج الوكيل:

- migration كبيرة
- تغيير contracts مشتركة
- refactor عابر للموديولات

فيجب تقسيمه إلى:

1. groundwork
2. feature wiring
3. verification

ولا يُدمج دفعة واحدة.

## 5. ملف التسليم المرجعي لكل وكيل

على كل وكيل أن يسلم في نهاية دُفعته:

- ملخص تنفيذي قصير
- قائمة الملفات المعدلة
- أوامر التحقق التي تم تشغيلها
- المخاطر المتبقية

الصيغة المفضلة:

- ملف `md` داخل `school-erp-docs/03_الموارد_البشرية/`

## 6. القرار التنفيذي

التوزيع المعتمد:

- الوكيل A: Payroll
- الوكيل B: Contracts + Documents
- الوكيل C: Leaves + Policies
- الوكيل D: Lifecycle + Notifications + HR Reports

أفضل توزيع احترافي في الوضع الحالي هو:

- تنفيذ `B + C + D` بالتوازي الآن
- ثم إدخال `A` بعد تثبيت policy contract مع الإجازات

هذا الترتيب أقل عرضة للأخطاء من تشغيل Payroll أولًا.
