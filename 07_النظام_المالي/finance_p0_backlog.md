# Backlog تنفيذية P0 — النظام المالي

## الهدف

إغلاق عناصر `P0` المتبقية بشكل تنفيذي واضح، مع تقليل المخاطرة وتسريع الوصول إلى حالة يمكن التحقق منها عمليًا.

**تاريخ الإعداد:** 2026-03-28  
**المرجع الأساسي:** `finance_gap_matrix.md`

> **تحديث 2026-03-30:** هذه الـ backlog أصبحت مغلقة داخل الريبو، وتحوّلت إلى مرجع أرشيفي لما تم تنفيذه في `P0`.

---

## لقطة الحالة الحالية

| المحور                   | الحالة           | الملاحظة                                                                        |
| ------------------------ | ---------------- | ------------------------------------------------------------------------------- |
| توحيد التوثيق            | منجز بدرجة كبيرة | تم تحديث عقد الـ API والـ Gap Matrix، والمتبقي توحيد إشارات ثانوية فقط          |
| اختبارات backend المالية | منجز بدرجة كبيرة | توجد الآن 9 suites مالية واضحة داخل `backend/test/`، والحزمة تمر محليًا بالكامل |
| اختبارات frontend المالية | منجز بدرجة كبيرة | `frontend typecheck` و`finance e2e` يمران محليًا بالكامل، وجرى ربطهما داخل CI    |
| صفحة `/app/finance`      | مغلق وظيفيًا     | تم التحقق أنها Dashboard فعلية، وأصبحت مغطاة ضمن smoke tests                    |

---

## التوصية التنفيذية

التوصية الحالية هي **تحديث الوثائق لتطابق المسارات الفعلية** بدل إضافة aliases جديدة في `P0`.  
إذا ظهرت حاجة تكاملية خارجية لاحقًا، يمكن إضافة aliases في `P1` أو `P2` بدون تعطيل الإغلاق الحالي.

---

## التذاكر التنفيذية

### FIN-P0-001 — مزامنة الوثائق الأساسية

- **النوع:** Documentation
- **الحالة:** منجز جزئيًا بتاريخ 2026-03-28
- **المدة التقديرية:** 0.5 يوم
- **الاعتماديات:** لا يوجد
- **الملفات المستهدفة:**
  - `school-erp-docs/07_النظام_المالي/README.md`
  - `school-erp-docs/07_النظام_المالي/finance_gap_matrix.md`
  - `school-erp-docs/07_النظام_المالي/finance_p0_backlog.md`
- **المطلوب:**
  - تصحيح عدّ الـ Views من `9` إلى `8`.
  - إغلاق الملاحظة القديمة الخاصة بـ `/app/finance`.
  - ربط الـ backlog الجديدة داخل ملفات التوثيق.
- **معايير القبول:**
  - لا توجد أرقام أو ملاحظات تتعارض مباشرة مع التحقق الحالي.
  - تظهر ملفات التنفيذ المرجعية داخل README.

### FIN-P0-002 — توحيد عقد الـ API بين الخطة والتنفيذ

- **النوع:** Documentation / API Contract
- **الحالة:** مغلق وظيفيًا بتاريخ 2026-03-29
- **المدة التقديرية:** 1 يوم
- **الاعتماديات:** `FIN-P0-001`
- **الملفات المستهدفة:**
  - `school-erp-docs/07_النظام_المالي/advanced_finance_integration.md`
  - `school-erp-docs/07_النظام_المالي/advanced_finance_phases.md`
  - `school-erp-platform/docs/FINANCE_SYSTEM_COMPLETION_PLAN.md`
- **المطلوب:**
  - إنشاء جدول mapping بين endpoints المخطط لها والمسارات الفعلية المنفذة.
  - تعليم كل endpoint كواحدة من: `Implemented`, `Implemented under different path`, `Pending`.
  - توثيق ما أُغلق فعليًا:
    - `GET /finance/hr/payroll-summary/:month`
    - `GET /finance/hr/employee-balance/:id`
    - `POST /finance/inventory/adjustment-journal`
    - `GET /finance/procurement/vendor-balance/:id`
    - `GET /finance/transport/revenue-report`
  - حسم بند الفوترة باعتماد `POST /finance/student-invoices` رسميًا في الوثائق، مع الإبقاء على `POST /finance/billing/bulk-generate` للتوليد الجماعي
- **معايير القبول:**
  - كل endpoint في الوثائق له حالة واضحة.
  - لا تبقى أي مطالبة بأن النظام ما زال في Sprint 1 فقط.

### FIN-P0-003 — بناء Harness لاختبارات المالية

- **النوع:** Backend Testing Infrastructure
- **الحالة:** منجز جزئيًا بتاريخ 2026-03-28
- **المدة التقديرية:** 1 يوم
- **الاعتماديات:** لا يوجد
- **الملفات المستهدفة:**
  - `school-erp-platform/backend/test/`
  - `school-erp-platform/backend/test/jest-e2e.json`
  - `school-erp-platform/backend/package.json`
- **تم تنفيذه فعليًا:**
  - إضافة `backend/test/finance-test-helpers.ts`
  - توحيد bootstrap الاختبارات مع `main.ts` فيما يخص `rawBody` و`ValidationPipe`
- **المطلوب:**
  - إنشاء utilities مشتركة لاختبارات المالية: bootstrap, login, cleanup, id helpers.
  - تجهيز seed/runtime data الحد الأدنى لدورة الفرع، السنة، الفترة، والحسابات اللازمة.
  - اعتماد naming واضح لملفات الاختبار المالية داخل `backend/test/`.
- **معايير القبول:**
  - يمكن تشغيل اختبارات المالية عبر `npm run test:e2e`.
  - لا تتكرر أكواد bootstrap والتنظيف داخل كل ملف اختبار.

### FIN-P0-004 — اختبار e2e لدورة القيد المحاسبي

- **النوع:** Backend E2E
- **الحالة:** منجز جزئيًا بتاريخ 2026-03-28
- **المدة التقديرية:** 1 يوم
- **الاعتماديات:** `FIN-P0-003`
- **الملفات المستهدفة:**
  - `school-erp-platform/backend/test/finance-journal-entries.e2e-spec.ts`
  - `school-erp-platform/backend/src/modules/finance/journal-entries/`
- **تم تنفيذه فعليًا:**
  - تغطية: create → approve → post → reverse
  - تغطية: منع post قبل approve
- **المطلوب:**
  - اختبار إنشاء قيد متوازن.
  - اختبار الانتقال من `Draft` إلى `Approved` ثم `Posted`.
  - اختبار العكس `Reverse` والتحقق من الأثر المحاسبي المتوقع.
- **معايير القبول:**
  - التحقق من توازن المدين/الدائن.
  - التحقق من تغيّر الحالة ومنع المسارات غير المسموح بها.

### FIN-P0-005 — اختبار e2e للفوترة والسداد

- **النوع:** Backend E2E
- **الحالة:** منجز جزئيًا بتاريخ 2026-03-28
- **المدة التقديرية:** 1.5 يوم
- **الاعتماديات:** `FIN-P0-003`
- **الملفات المستهدفة:**
  - `school-erp-platform/backend/test/finance-billing-payments.e2e-spec.ts`
  - `school-erp-platform/backend/src/modules/finance/billing-engine/`
  - `school-erp-platform/backend/src/modules/finance/student-invoices/`
  - `school-erp-platform/backend/src/modules/finance/payment-transactions/`
- **تم تنفيذه فعليًا:**
  - تغطية إنشاء فاتورة طالب بحالتها `ISSUED`
  - تغطية سداد جزئي مع `receipt` و`reconcile`
  - تغطية سداد كامل عبر قسطين وتحديث حالة الفاتورة إلى `PAID`
  - تغطية `student statement` و`family balance`
- **المطلوب:**
  - اختبار توليد فاتورة لطالب.
  - اختبار سداد كامل وسداد جزئي.
  - اختبار إصدار إيصال وتحديث حالة الفاتورة/القسط.
- **معايير القبول:**
  - الفاتورة تنتقل إلى الحالة الصحيحة بعد السداد.
  - يظهر أثر السداد في السجلات المالية المرتبطة.

### FIN-P0-006 — اختبار e2e للـ Webhooks

- **النوع:** Backend E2E
- **الحالة:** منجز جزئيًا بتاريخ 2026-03-28
- **المدة التقديرية:** 1 يوم
- **الاعتماديات:** `FIN-P0-003`
- **الملفات المستهدفة:**
  - `school-erp-platform/backend/test/finance-payment-webhooks.e2e-spec.ts`
  - `school-erp-platform/backend/src/modules/finance/payment-webhooks/`
- **تم تنفيذه فعليًا:**
  - تغطية: success
  - تغطية: duplicate success / idempotency
  - تغطية: failure
  - تغطية: refund + reversal journal entry
- **المطلوب:**
  - اختبار `success`
  - اختبار `failure`
  - اختبار `refund`
  - اختبار `duplicate` للتحقق من idempotency
- **معايير القبول:**
  - كل webhook تعطي الأثر المتوقع مرة واحدة فقط.
  - يتم التحقق من منطق الحماية الأساسي دون كسر السيناريو الطبيعي.

---

## الترتيب المقترح للتنفيذ

1. `FIN-P0-001`
2. `FIN-P0-002`
3. `FIN-P0-003`
4. `FIN-P0-004`
5. `FIN-P0-005`
6. `FIN-P0-006`

---

## المدة الإجمالية المتوقعة

- **أقل تقدير:** 5 أيام عمل
- **تقدير مريح:** 6 أيام عمل

---

## Definition of Done لـ P0

- التوثيق المالي الأساسي لا يحتوي على تضارب مباشر مع التنفيذ الحالي.
- الوثائق تميز بوضوح بين `implemented`, `replaced`, و`pending`.
- توجد 9 ملفات e2e مالية واضحة داخل `backend/test/`.
- تمر اختبارات المالية عبر `npm run test:e2e` ضمن بيئة جاهزة.
- يوجد workflow CI مخصص لتشغيل backend finance suites وfrontend finance e2e.

---

## ملاحظة تنفيذية

تم بدء العمل فعليًا من الجانب التوثيقي في نفس تاريخ إعداد هذه الوثيقة عبر:

- تصحيح عدّ الـ Views.
- تحديث حالة `/app/finance` داخل Gap Matrix.
- ربط هذه الـ backlog داخل README.
- إضافة جدول mapping لحالة التنفيذ الحالية داخل `advanced_finance_integration.md`.
- تحويل `FINANCE_SYSTEM_COMPLETION_PLAN.md` إلى مرجع تاريخي صريح بدل مرجع حالة حالي.
- إضافة `finance-journal-entries.e2e-spec.ts` وتشغيلها بنجاح.
- إضافة `finance-payment-webhooks.e2e-spec.ts` وتشغيلها بنجاح.
- إضافة `finance-billing-payments.e2e-spec.ts` وتشغيلها بنجاح.
- إضافة `finance-bank-reconciliations.e2e-spec.ts` وتشغيلها بنجاح.
- إضافة workflow: `school-erp-platform/.github/workflows/finance-quality.yml`.
- إضافة smoke tests للواجهة: `frontend/tests/e2e/finance-smoke.spec.ts`.
- توسيع smoke tests للواجهة لتغطية: `student-invoices`, `invoice-installments`, `billing-engine`, `bank-reconciliations`.
- توسيع smoke tests للواجهة لتغطية: `currencies`, `chart-of-accounts`, `fee-structures`, `discount-rules`.
- توسيع smoke tests للواجهة لتغطية: `hr-integrations`, `procurement-integrations`, `transport-integrations`.
- إضافة deep flows للواجهة: `frontend/tests/e2e/finance-deep-flows.spec.ts`.
- اعتماد script موحد للواجهة: `npm run e2e:finance`.
