# خطة المهام المتبقية وتوزيع الوكلاء — النظام المالي

## الهدف

تحويل الفجوات المتبقية في `07_النظام_المالي` إلى مهام تنفيذية واضحة، مع تحديد:

- المهمة المتبقية فقط
- الأولوية
- الوكيل المسؤول
- نطاق الملفات
- الاعتماديات
- أمر واضح وجاهز لإرساله إلى الوكيل

**تاريخ التحديث:** 2026-03-29  
**المرجع:** `finance_gap_matrix.md` + `finance_p0_backlog.md`

> **تحديث 2026-03-30:** أُغلقت جميع المهام الداخلية المذكورة في هذه الوثيقة، وأصبحت مرجعًا أرشيفيًا. المتبقي الوحيد خارج الريبو هو تفعيل `required checks` على GitHub حسب runbook الجودة.

---

## ما تم إنجازه بالفعل ولا يدخل في المتبقي

- backend finance e2e الأساسية موجودة: القيود، الفوترة/السداد، webhooks، التسويات البنكية، وجسر `community_contributions`
- أضيفت suite متقدمة تغطي: `branch-filtered reports`, `overdue/late fee`, `VAT edge cases`, وhappy path للـ legacy `revenues/expenses`
- workflow CI مالي موجود: `finance-quality.yml`
- frontend smoke suite أصبحت تغطي الصفحات المالية الرئيسية والتكاملات الأساسية
- frontend deep-flow suite أصبحت تغطي `student-invoices`, `invoice-installments`, `fee-structures`, `discount-rules`, و`bank-reconciliations`
- frontend typecheck أصبح يمر محليًا، وتم ربطه داخل workflow المالي قبل تشغيل Playwright
- موجة التكاملات الأولى أُغلقت وظيفيًا:
  - HR: `payroll-summary` و`employee-balance`
  - Procurement: `inventory adjustment` و`vendor-balance`
  - Transport: `revenue-report`
  - Billing contract: اعتماد `POST /finance/student-invoices` رسميًا

بالتالي، المهام أدناه هي **المتبقي الحقيقي فقط**.

---

## الترتيب التنفيذي المقترح

### الموجة 1 — مغلقة بتاريخ 2026-03-29

1. توحيد عقد الـ API والتوثيق النهائي
2. استكمال endpoints الناقصة في HR
3. استكمال endpoints الناقصة في Procurement
4. استكمال endpoint الناقص في Transport
5. حسم مسار `generate-student-invoice`

### الموجة 2 — مغلقة بتاريخ 2026-03-29

6. تثبيت وتشغيل auto-bridge الخاص بـ `community_contributions`
7. توسيع backend test coverage للحالات المتقدمة
8. توسيع frontend tests للعمليات العميقة وCRUD الحرجة

### الموجة 3 — مغلقة داخل الريبو بتاريخ 2026-03-29

9. توحيد المصطلحات والتقارير المرجعية
10. ربط `finance-quality` ببوابة الجودة العامة أو إعدادها إداريًا

---

## توزيع الوكلاء

### AGENT-FIN-01 — Documentation Contract Agent

- **النوع المقترح:** `worker`
- **الأولوية:** `P0/P1`
- **المهمة:** إغلاق Drift التوثيق وتحديث عقد الـ API النهائي
- **الحالة:** مغلق وظيفيًا بتاريخ 2026-03-29
- **نطاق الملفات:**
  - `school-erp-docs/07_النظام_المالي/advanced_finance_integration.md`
  - `school-erp-docs/07_النظام_المالي/advanced_finance_phases.md`
  - `school-erp-docs/07_النظام_المالي/README.md`
  - `school-erp-platform/docs/FINANCE_SYSTEM_COMPLETION_PLAN.md`
- **الاعتماديات:** لا يوجد
- **المخرج المطلوب:**
  - جدول نهائي يحدد لكل endpoint حالته: `Implemented` أو `Implemented under different path` أو `Pending`
  - توضيح رسمي لمسار الفوترة المعتمد
  - إزالة أي صياغة توحي أن النظام ما زال في Sprint 1

**الأمر الجاهز للوكيل:**

```text
أنت مسؤول فقط عن توحيد توثيق النظام المالي مع التنفيذ الحالي.
لا تعدّل أي كود تشغيلي.
عدّل فقط الملفات التالية:
- school-erp-docs/07_النظام_المالي/advanced_finance_integration.md
- school-erp-docs/07_النظام_المالي/advanced_finance_phases.md
- school-erp-docs/07_النظام_المالي/README.md
- school-erp-platform/docs/FINANCE_SYSTEM_COMPLETION_PLAN.md

المطلوب:
1. راجع مسارات الـ API الفعلية في backend finance modules.
2. أنشئ mapping نهائي بين المخطط والمنفذ.
3. علّم كل endpoint كواحدة من:
   - Implemented
   - Implemented under different path
   - Pending
4. احسم بند الفوترة:
   - إذا كان المسار الرسمي المعتمد هو POST /finance/student-invoices فوثّقه بوضوح.
   - إذا كان يلزم alias فاذكره كتوصية Pending ولا تخترعه في الوثائق كمنفذ.
5. أزل أو صحّح أي نص قديم يوحي أن النظام ما زال في Sprint 1 فقط.

قيود مهمة:
- لا تذكر claims غير متحقق منها من الكود.
- لا تضف endpoints غير موجودة.
- لا تغيّر ملفات خارج النطاق.

التسليم:
- اذكر الملفات المعدلة.
- اذكر البنود التي أصبحت موثقة نهائيًا.
- اذكر ما بقي Pending فقط.
```

---

### AGENT-FIN-02 — HR Integration Agent

- **النوع المقترح:** `worker`
- **الأولوية:** `P1`
- **المهمة:** تنفيذ endpoints HR الناقصة
- **الحالة:** مكتمل وظيفيًا بتاريخ 2026-03-29
- **نطاق الملفات:**
  - `school-erp-platform/backend/src/modules/finance/hr-integrations/`
  - `school-erp-platform/backend/test/`
- **الاعتماديات:** يفضّل بعد مراجعة AGENT-FIN-01 لكن ليس شرطًا
- **المخرج المتحقق:**
  - `GET /finance/hr/payroll-summary/:month`
  - `GET /finance/hr/employee-balance/:id`
  - backend e2e مخصص داخل `backend/test/finance-hr-integrations.e2e-spec.ts`

**الأمر الجاهز للوكيل:**

```text
أنت مسؤول فقط عن استكمال تكاملات HR المالية.
أنت لست وحدك في المستودع؛ لا تعكس تعديلات الآخرين ولا تغيّر ملفات خارج نطاق HR integrations إلا إذا كانت تبعية مباشرة مطلوبة.

نطاقك:
- school-erp-platform/backend/src/modules/finance/hr-integrations/
- school-erp-platform/backend/test/

المطلوب:
1. أضف endpoint:
   GET /finance/hr/payroll-summary/:month
2. أضف endpoint:
   GET /finance/hr/employee-balance/:id
3. استخدم نفس أنماط DTO / guards / services / controller الموجودة في الموديول الحالي.
4. أعد استخدام Prisma models والخدمات الحالية بدل duplicating logic.
5. أضف اختبارات backend تغطي:
   - success case
   - missing/not found case عند اللزوم
   - shape contract للرد

معايير القبول:
- endpoints تعمل ضمن AppModule بدون كسر endpoints الحالية:
  - POST /finance/hr/payroll-journal
  - POST /finance/hr/deduction-journal
- الاختبارات الجديدة تمر محليًا.

قيود مهمة:
- لا تغيّر عقود endpoints القائمة.
- لا تضف افتراضات business غير موثقة بدون شرح داخل الكود أو test.
- لا تلمس procurement أو transport.

التسليم:
- اذكر الملفات المعدلة.
- اذكر كيف حُسب payroll summary وemployee balance.
- اذكر أمر الاختبار الذي شغّلته ونتيجته.
```

---

### AGENT-FIN-03 — Procurement Integration Agent

- **النوع المقترح:** `worker`
- **الأولوية:** `P1`
- **المهمة:** تنفيذ endpoints Procurement الناقصة
- **الحالة:** مكتمل وظيفيًا بتاريخ 2026-03-29
- **نطاق الملفات:**
  - `school-erp-platform/backend/src/modules/finance/procurement-integrations/`
  - `school-erp-platform/backend/test/`
- **الاعتماديات:** لا يوجد
- **المخرج المتحقق:**
  - `POST /finance/inventory/adjustment-journal`
  - `GET /finance/procurement/vendor-balance/:id`
  - backend e2e مخصص داخل `backend/test/finance-procurement-integrations.e2e-spec.ts`

**الأمر الجاهز للوكيل:**

```text
أنت مسؤول فقط عن استكمال تكاملات المشتريات المالية.
لا تعكس تعديلات الآخرين، ولا تعدّل ملفات خارج procurement integrations إلا إذا احتجت DTO أو test helper بشكل محدود.

نطاقك:
- school-erp-platform/backend/src/modules/finance/procurement-integrations/
- school-erp-platform/backend/test/

المطلوب:
1. أضف endpoint:
   POST /finance/inventory/adjustment-journal
2. أضف endpoint:
   GET /finance/procurement/vendor-balance/:id
3. التزم بنفس أسلوب coding الموجود في:
   - purchase-journal
   - payment-journal
   - depreciation-journal
4. أضف اختبارات backend تغطي:
   - inventory adjustment success
   - vendor balance success
   - validation / not found عند الحاجة

معايير القبول:
- لا ينكسر أي endpoint قائم في procurement integrations.
- العقود الجديدة موثقة ضمن DTO/response بشكل واضح.
- الاختبارات تمر محليًا.

قيود مهمة:
- لا تلمس HR أو Transport.
- لا تكتب منطقًا محاسبيًا معزولًا عن الخدمات الحالية إن كان بالإمكان إعادة الاستخدام.

التسليم:
- اذكر الملفات المعدلة.
- اذكر assumptions المحاسبية المستخدمة في inventory adjustment وvendor balance.
- اذكر نتائج الاختبارات.
```

---

### AGENT-FIN-04 — Transport Reporting Agent

- **النوع المقترح:** `worker`
- **الأولوية:** `P1`
- **المهمة:** تنفيذ endpoint تقرير إيرادات النقل
- **الحالة:** مكتمل وظيفيًا بتاريخ 2026-03-29
- **نطاق الملفات:**
  - `school-erp-platform/backend/src/modules/finance/transport-integrations/`
  - `school-erp-platform/frontend/src/features/transport-integrations/` عند الحاجة
  - `school-erp-platform/backend/test/`
- **الاعتماديات:** لا يوجد
- **المخرج المطلوب:**
  - `GET /finance/transport/revenue-report`
  - اختبار backend

**ملاحظة التنفيذ:**
تم تنفيذ `GET /finance/transport/revenue-report` مع backend test مخصص في `backend/test/finance-transport-revenue-report.e2e-spec.ts`.

**الأمر الجاهز للوكيل:**

```text
أنت مسؤول فقط عن استكمال Transport revenue reporting.
لا تغيّر flows النقل الحالية إلا عند الحاجة الضرورية لقراءة التقرير.

نطاقك:
- school-erp-platform/backend/src/modules/finance/transport-integrations/
- school-erp-platform/backend/test/
- وإذا احتجت واجهة عرض بسيطة: school-erp-platform/frontend/src/features/transport-integrations/

المطلوب:
1. أضف endpoint:
   GET /finance/transport/revenue-report
2. اجعل التقرير مفيدًا تشغيليًا على الأقل:
   - total revenue
   - count of invoices أو transactions
   - optional branch/date filters إذا كانت سهلة وآمنة
3. أضف اختبار backend لعقد الرد.
4. إذا كانت الواجهة الحالية تستفيد من التقرير بدون تعقيد، أضف read-only block بسيط لها.

معايير القبول:
- endpoint يعمل دون كسر:
  - generate-invoices
  - subscription-fee
  - maintenance-expense
- الاختبارات تمر محليًا.

قيود مهمة:
- لا تحول المهمة إلى refactor كبير.
- لا تضف dashboard معقدة؛ المطلوب تقرير endpoint واضح أولًا.

التسليم:
- اذكر الملفات المعدلة.
- اذكر fields التي أعدتها endpoint.
- اذكر نتيجة الاختبارات.
```

---

### AGENT-FIN-05 — Billing Contract Agent

- **النوع المقترح:** `worker`
- **الأولوية:** `P1`
- **المهمة:** حسم التوافق بين الخطة ومسار إنشاء فاتورة الطالب
- **الحالة:** مغلق وظيفيًا بتاريخ 2026-03-29
- **نطاق الملفات:**
  - `school-erp-platform/backend/src/modules/finance/billing-engine/`
  - `school-erp-platform/backend/src/modules/finance/student-invoices/`
  - `school-erp-docs/07_النظام_المالي/advanced_finance_integration.md`
  - `school-erp-platform/backend/test/`
- **الاعتماديات:** التنسيق مع AGENT-FIN-01
- **المخرج المتحقق:**
  - قرار تنفيذي موثق في `billing_contract_decision.md`
  - اعتماد `POST /finance/student-invoices` للفردي و`POST /finance/billing/bulk-generate` للجماعي

**الأمر الجاهز للوكيل:**

```text
أنت مسؤول فقط عن حسم مسار generate-student-invoice.
ابدأ أولًا بمراجعة التنفيذ الحالي في student-invoices وbilling-engine، ثم قرر أقل تغيير آمن:
- إما اعتماد المسار الحالي POST /finance/student-invoices وتحديث الوثائق فقط
- أو إضافة alias واضح وآمن مثل POST /finance/billing/generate-student-invoice إذا كان مطلوبًا فعلًا للتوافق

نطاقك:
- school-erp-platform/backend/src/modules/finance/billing-engine/
- school-erp-platform/backend/src/modules/finance/student-invoices/
- school-erp-docs/07_النظام_المالي/advanced_finance_integration.md
- school-erp-platform/backend/test/

المطلوب:
1. لا تضف alias إلا إذا كانت فائدته واضحة ومحددة.
2. إذا قررت الاكتفاء بالمسار الحالي، حدّث الوثائق بوضوح.
3. إذا أضفت alias:
   - اجعله thin wrapper فوق الخدمة الحالية
   - لا تكرر business logic
   - أضف test يثبت أنه يعيد نفس السلوك

معايير القبول:
- لا يوجد غموض بعد التنفيذ حول المسار الرسمي لإنشاء فاتورة طالب.
- لا يحدث ازدواج منطق بين billing-engine وstudent-invoices.

التسليم:
- اذكر القرار النهائي ولماذا.
- اذكر الملفات المعدلة.
- اذكر أي test أضفته.
```

---

### AGENT-FIN-06 — Legacy Contributions Bridge Agent

- **النوع المقترح:** `worker`
- **الأولوية:** `P1`
- **المهمة:** تقوية Bridge لـ `community_contributions`
- **الحالة:** منفذ جزئيًا بتاريخ 2026-03-29
- **نطاق الملفات:**
  - `school-erp-platform/backend/src/modules/finance/`
  - `school-erp-platform/backend/prisma/schema.prisma` عند الحاجة
  - `school-erp-platform/backend/test/`
- **الاعتماديات:** بعد اكتمال AGENT-FIN-05 أفضل
- **المخرج المتحقق حتى الآن:**
  - `autoBridge` اختياري في `community-contributions.create`
  - توليد تلقائي لـ `invoice_id` عند وجود صافي مستحق
  - توليد تلقائي لـ `journal_entry_id` عند وجود سداد فعلي
  - suite backend مخصصة: `backend/test/finance-community-contributions.e2e-spec.ts`
  - التحقق المحلي يمر الآن بنجاح ضمن `npm run test:e2e:finance`
- **المتبقي:**
  - توسيع حالات edge مثل partial/exempt combinations
  - إبقاء التحقق ضمن مسار CI العامة

**الأمر الجاهز للوكيل:**

```text
أنت مسؤول فقط عن تحسين Bridge الخاص بـ community_contributions.
هدفك هو إزالة الغموض الحالي: هل الربط تلقائي أم يدوي؟

نطاقك:
- school-erp-platform/backend/src/modules/finance/
- school-erp-platform/backend/prisma/schema.prisma عند الحاجة
- school-erp-platform/backend/test/

المطلوب:
1. راجع التدفق الحالي لـ community_contributions.
2. إن كان من الممكن إكمال automation بشكل آمن:
   - ولّد invoice_id وjournal_entry_id تلقائيًا عند تحقق الشروط
   - أضف tests واضحة
3. إن كان automation الكامل غير آمن أو يفتح أسئلة business غير محسومة:
   - لا تخترع behavior
   - بدلاً من ذلك، ثبّت manual bridge بوضوح في الخدمة/الوثائق
   - أضف guardrails تمنع البيانات الناقصة أو الربط الملتبس

معايير القبول:
- لا تبقى الحالة "شبه آلية" بدون تعريف واضح.
- يوجد اختبار أو توثيق صارم يشرح السلوك النهائي.

التسليم:
- اذكر القرار النهائي: Automated أو Manual with guardrails.
- اذكر الملفات المعدلة.
- اذكر الاختبارات أو التوثيق المضاف.
```

---

### AGENT-FIN-07 — Advanced Backend QA Agent

- **النوع المقترح:** `worker`
- **الأولوية:** `P2`
- **المهمة:** توسيع backend finance coverage للحالات المتقدمة
- **الحالة:** منفذ جزئيًا بتاريخ 2026-03-29
- **نطاق الملفات:**
  - `school-erp-platform/backend/test/`
  - `school-erp-platform/backend/src/modules/finance/` عند الحاجة المحدودة فقط
- **الاعتماديات:** بعد AGENT-FIN-02 إلى AGENT-FIN-06
- **المخرج المطلوب:**
  - اختبارات لحالات `overdue`, `late fee`, `tax edge cases`, `branch-filtered reports`, وlegacy flows الأساسية
- **المخرج المتحقق حتى الآن:**
  - `backend/test/finance-advanced-coverage.e2e-spec.ts`
  - تغطية `general-ledger` و`trial-balance` بفلترة الفرع
  - تغطية `invoice installments` لحالات `OVERDUE` و`lateFee`
  - تغطية تقرير `vat-report` لحالات `OUTPUT / INPUT / EXEMPT / ZERO_RATED`
  - تغطية happy path للـ legacy `revenues` و`expenses`
  - تمرير `npm run test:e2e:finance` محليًا بنتيجة `9 suites / 23 tests`
- **المتبقي:**
  - توسيع negative/security edge cases فقط عند الحاجة
  - متابعة ربط الحزمة نفسها مع بوابة الجودة العامة

**الأمر الجاهز للوكيل:**

```text
أنت مسؤول فقط عن توسيع تغطية backend finance tests.
افترض أن البنية الأساسية جاهزة، ولا تقم refactor كبير إلا إذا كان ضروريًا لكتابة test ثابت.

نطاقك:
- school-erp-platform/backend/test/
- تعديلات محدودة جدًا على backend finance modules إذا كانت مطلوبة لجعل الاختبار قابلاً للتنفيذ

المطلوب:
1. أضف coverage لحالات:
   - invoice installments overdue
   - late fee
   - VAT edge cases: OUTPUT / INPUT / EXEMPT / ZERO_RATED
   - branch-filtered reports
   - legacy revenues / expenses happy path
2. استخدم finance-test-helpers الحالية ولا تنسخ bootstrap.
3. اجعل الأسماء والـ fixtures واضحة ومستقرة.

معايير القبول:
- لا تقلل استقرار suite الحالية.
- يمكن تشغيل الاختبارات الجديدة ضمن finance suites الحالية أو سكربت فرعي واضح.

التسليم:
- اذكر ملفات الاختبار الجديدة.
- اذكر الأوامر التي شغّلتها.
- اذكر المخاطر المتبقية التي لم تغطها.
```

---

### AGENT-FIN-08 — Frontend Deep Flows Agent

- **النوع المقترح:** `worker`
- **الأولوية:** `P2`
- **المهمة:** الانتقال من smoke إلى flows أعمق للواجهات الحرجة
- **الحالة:** مكتمل وظيفيًا بتاريخ 2026-03-29
- **نطاق الملفات:**
  - `school-erp-platform/frontend/tests/e2e/`
  - `school-erp-platform/frontend/src/features/finance/` عند الحاجة المحدودة فقط
- **الاعتماديات:** بعد اكتمال AGENT-FIN-02 إلى AGENT-FIN-06 جزئيًا
- **المخرج المطلوب:**
  - اختبارات CRUD أو submit/validation أعمق للصفحات الحرجة
- **المخرج المتحقق:**
  - إضافة `frontend/tests/e2e/finance-deep-flows.spec.ts`
  - تغطية `submit success` و`validation` للصفحات:
    - `student-invoices`
    - `invoice-installments`
    - `fee-structures`
    - `discount-rules`
  - تغطية تحديث الحالة وصلاحيات المنع في `bank-reconciliations`
  - تمرير `npm run e2e:finance` محليًا بنتيجة `24/24`

**الأمر الجاهز للوكيل:**

```text
أنت مسؤول فقط عن تعميق اختبارات الواجهة المالية.
لا تغيّر تصميم الواجهة إلا إذا كان مطلوبًا فقط لإضافة selector أو testability hook صغيرة وواضحة.

نطاقك:
- school-erp-platform/frontend/tests/e2e/
- تعديلات محدودة جدًا على frontend features إذا احتجت تحسين testability

المطلوب:
1. أضف flows أعمق للصفحات التالية:
   - student-invoices
   - invoice-installments
   - fee-structures
   - discount-rules
   - bank-reconciliations
2. غطِّ على الأقل:
   - submit success
   - validation error
   - permission denial في صفحة واحدة إضافية
3. لا تكسر smoke suite الحالية؛ إما توسعها بحذر أو تضيف spec جديدة مستقلة.

معايير القبول:
- tests مستقرة محليًا وملائمة لـ CI.
- لا تعتمد على selectors هشة.

التسليم:
- اذكر الملفات المضافة/المعدلة.
- اذكر السيناريوات التي أصبحت مغطاة.
- اذكر أمر التشغيل ونتيجته.
```

---

### AGENT-FIN-09 — Reporting & Terminology Agent

- **النوع المقترح:** `worker`
- **الأولوية:** `P2`
- **المهمة:** توحيد المصطلحات وبند `Budget vs Actual`
- **الحالة:** مكتمل وظيفيًا بتاريخ 2026-03-29
- **نطاق الملفات:**
  - `school-erp-docs/07_النظام_المالي/`
  - `school-erp-platform/docs/`
- **الاعتماديات:** بعد AGENT-FIN-01 وAGENT-FIN-05
- **المخرج المطلوب:**
  - قرار واضح بشأن `Budget vs Actual`
  - توحيد المصطلحات بين الوثائق والكود
- **المخرج المتحقق:**
  - اعتماد المصطلحات الرسمية:
    - `chart-of-accounts`
    - `journal-entries`
    - `POST /finance/student-invoices`
  - توثيق `Budget vs Actual` كميزة منفذة فعليًا عبر `GET /finance/budgets/:id/budget-vs-actual`
  - ربط وجود صفحة `/app/budgets` بالواجهة الحالية

**الأمر الجاهز للوكيل:**

```text
أنت مسؤول فقط عن التنظيف المرجعي للمصطلحات والتقارير.
هذه مهمة توثيقية وليست refactor كود.

نطاقك:
- school-erp-docs/07_النظام_المالي/
- school-erp-platform/docs/

المطلوب:
1. وحّد المصطلحات التالية في الوثائق:
   - journal vs journal-entries
   - accounts tree vs chart-of-accounts
   - billing generate-student-invoice vs student-invoices.create
2. احسم بند Budget vs Actual:
   - إذا كان موجودًا فعليًا فاذكره بوضوح
   - إذا كان جزئيًا فاذكره كـ Partial
   - إذا كان غير موجود فلا تقدّمه كمنفذ

معايير القبول:
- لا تبقى تسميات مزدوجة لنفس الوظيفة داخل الوثائق الرئيسية.

التسليم:
- اذكر الملفات المعدلة.
- اذكر المصطلحات التي تم توحيدها.
- اذكر الحالة النهائية لـ Budget vs Actual.
```

---

### AGENT-FIN-10 — CI Governance Agent

- **النوع المقترح:** `worker`
- **الأولوية:** `P2`
- **المهمة:** إغلاق جانب الحوكمة وربط `finance-quality` بالمسار الإداري الصحيح
- **الحالة:** مغلق داخل الريبو ويتطلب خطوة إدارية خارجية بتاريخ 2026-03-29
- **نطاق الملفات:**
  - `.github/workflows/finance-quality.yml`
  - `school-erp-docs/07_النظام_المالي/`
  - `school-erp-platform/docs/`
- **الاعتماديات:** بعد استقرار suites الحالية
- **المخرج المطلوب:**
  - تحسينات CI إن وجدت
  - توثيق إداري واضح لجعل `Finance Quality` required check
- **المخرج المتحقق:**
  - workflow الحالي موثق باسم `Finance Quality`
  - job checks الحالية موثقة بوضوح:
    - `Backend Finance E2E`
    - `Frontend Finance E2E`
  - إضافة runbook إداري داخل:
    - `school-erp-platform/docs/FINANCE_QUALITY_REQUIRED_CHECK_RUNBOOK.md`
  - تمييز ما يمكن تنفيذه من داخل الريبو وما يحتاج صلاحيات GitHub Admin

**الأمر الجاهز للوكيل:**

```text
أنت مسؤول فقط عن إغلاق جانب CI governance للنظام المالي.
افترض أنك قد لا تملك صلاحيات GitHub الإدارية المباشرة، لذلك نفّذ ما يمكن في المستودع ووثّق ما يحتاج إجراءً يدويًا.

نطاقك:
- .github/workflows/finance-quality.yml
- school-erp-docs/07_النظام_المالي/
- school-erp-platform/docs/

المطلوب:
1. راجع workflow الحالي finance-quality.yml.
2. حسّن أي نقطة واضحة وآمنة فقط إذا كانت ضرورية لاستقرار التنفيذ.
3. أنشئ توثيقًا واضحًا يشرح:
   - اسم الـ check المطلوب
   - الفروع المستهدفة
   - ما الذي يجب ضبطه في Branch Protection
4. إذا لم يمكن ضبط required check من داخل المستودع، اذكر ذلك صراحة واجعل المخرج Runbook إداري واضح.

معايير القبول:
- لا يتم الادعاء بأن required check فُعّل إذا كان هذا يحتاج صلاحيات خارج المستودع.
- يوجد runbook واضح يمكن لفريق الـ DevOps أو Admin تنفيذه.

التسليم:
- اذكر الملفات المعدلة.
- اذكر ما تم داخل الكود/الريبو.
- اذكر ما يحتاج إجراءً يدويًا خارج الريبو.
```

---

## الترتيب النهائي للتشغيل

1. شغّل بالتوازي:
   - `AGENT-FIN-01`
   - `AGENT-FIN-02`
   - `AGENT-FIN-03`
   - `AGENT-FIN-04`
   - `AGENT-FIN-05`

2. بعد إغلاقهم شغّل:
   - `AGENT-FIN-06`
   - `AGENT-FIN-07`
   - `AGENT-FIN-08`

3. أخيرًا شغّل:
   - `AGENT-FIN-09`
   - `AGENT-FIN-10`

---

## ملاحظات تشغيلية مهمة

- لا تعطِ وكيلين نفس نطاق الكتابة على نفس الملفات إلا إذا كان أحدهما توثيقيًا فقط وتم التنسيق بينهما.
- وكلاء `backend` يجب أن يذكروا أمر الاختبار الذي نفذوه ونتيجته.
- وكلاء `frontend` يجب أن يذكروا spec files وأوامر Playwright التي شغلوها.
- أي وكيل لا يجد يقينًا business-wise يجب أن يثبّت الافتراض في التسليم بدل اختراع سلوك جديد.
- أي خطوة تتطلب صلاحيات GitHub الإدارية يجب أن تُوثّق كإجراء يدوي، لا كإنجاز منجز داخل الكود.
