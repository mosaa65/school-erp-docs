# قرار تنفيذي — Billing Contract

**التاريخ:** 2026-03-28

## القرار

المسار الرسمي لإنشاء **فاتورة طالب مفردة** هو:

- `POST /finance/student-invoices`

والمسار الرسمي لتوليد **فواتير جماعية** هو:

- `POST /finance/billing/bulk-generate`

## سبب القرار

- التنفيذ الحالي في `student-invoices.controller.ts` يوفّر عملية resource-based كاملة لإنشاء فاتورة طالب مفردة.
- `CreateStudentInvoiceDto` يغطي فعليًا كل العناصر المطلوبة لسيناريو "generate student invoice":
  - `enrollmentId`
  - `academicYearId`
  - `invoiceDate`
  - `dueDate`
  - `lines`
  - `installments`
- التوليد الجماعي موجود أصلًا في `billing-engine.controller.ts` عبر:
  - `POST /finance/billing/bulk-generate`
- إضافة alias جديد مثل `POST /finance/billing/generate-student-invoice` الآن ستنتج طبقة API إضافية لنفس السلوك بدون مكسب تشغيلي واضح.

## الأثر على التوثيق

- أي توثيق يذكر `generate-student-invoice` يجب تحديثه ليشير إلى:
  - `POST /finance/student-invoices` لإنشاء فاتورة فردية
  - `POST /finance/billing/bulk-generate` للتوليد الجماعي

## متى نضيف Alias لاحقًا؟

لا يُنصح بإضافة alias إلا إذا ظهر واحد من التالي:

- تكامل خارجي قائم يعتمد الاسم القديم حرفيًا
- حاجة backward compatibility موثقة
- حاجة فصل semantic واضحة بين create resource وgenerate workflow

في غير ذلك، يبقى المسار resource-based الحالي هو القرار المعتمد.

