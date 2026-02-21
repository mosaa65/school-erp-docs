# التدقيق والحوكمة (Subsystem 07)
## `DDL_AUDIT.sql`

هذا الجزء يحمي مصداقية الدرجات: من عدل؟ ماذا عدل؟ ومتى؟ وهل يسمح بالتعديل بعد الاعتماد؟

## شرح مبسط
- بعد اعتماد النتيجة، التعديل على الحقول الحساسة يصبح ممنوعا.
- أي تعديل على الدرجات يسجل في سجل تدقيق.
- الإدارة تستطيع مراجعة تاريخ التعديلات بدقة.

## شرح تقني
الجداول:
- `student_grade_audit` سجل التعديلات.

Triggers:
- قفل `semester_grades` بعد الاعتماد.
- قفل `annual_grades` بعد الاعتماد.
- قفل `annual_result` بعد الاعتماد.
- تسجيل تلقائي لتعديلات `student_exam_scores` و`monthly_grades`.

## شرح جدول `student_grade_audit`
| العمود | English | لماذا موجود؟ | مثال |
|---|---|---|---|
| `id` | audit id | رقم سجل التدقيق | `1` |
| `enrollment_id` | student enrollment | الطالب | `5001` |
| `subject_id` | subject | المادة | `3` |
| `grade_table` | source table | من أي جدول جاء التعديل | `monthly_grades` |
| `grade_field` | changed field | أي عمود تغير | `exam_score` |
| `old_value` | old value | القيمة السابقة | `6.00` |
| `new_value` | new value | القيمة الجديدة | `7.00` |
| `changed_by_user_id` | changed by | من عدل | `12` |
| `change_reason` | reason | سبب التعديل (اختياري) | `تصحيح خطأ إدخال` |
| `changed_at` | changed time | وقت التعديل | `2026-10-03 12:30` |

## كيف يعمل الحوكمة؟
1. قبل التعديل، النظام يتحقق من حالة الاعتماد.
2. إذا الحالة معتمدة (`grading_status_id = 3`) يمنع التعديل.
3. إذا التعديل مسموح، يسجل الفرق في `student_grade_audit`.

## بيانات تجريبية (10 سجلات)
```sql
INSERT INTO student_grade_audit (
  enrollment_id, subject_id, grade_table, grade_field,
  old_value, new_value, changed_by_user_id, change_reason
) VALUES
(5001,3,'monthly_grades','attendance_score',4.0,4.5,12,'تصحيح حضور'),
(5001,3,'monthly_grades','homework_score',3.5,4.0,12,'إضافة واجب متأخر'),
(5002,3,'monthly_grades','activity_score',2.0,2.5,12,'إعادة تقييم نشاط'),
(5003,3,'monthly_grades','contribution_score',1.0,1.5,12,'تحديث مساهمة'),
(5004,3,'monthly_grades','exam_score',6.0,7.0,12,'تصحيح الدرجة'),
(5005,3,'student_exam_scores','score',14.0,15.0,12,'جمع سؤال ناقص'),
(5006,3,'student_exam_scores','score',0.0,10.0,12,'رفع الغياب بعذر'),
(5007,3,'monthly_grades','custom_components_score',0.5,0.8,12,'إضافة مشروع'),
(5008,3,'monthly_grades','homework_score',4.0,4.3,12,'تصحيح'),
(5009,3,'student_exam_scores','score',11.0,12.0,12,'تصحيح نهائي');
```

## ملاحظة تشغيل
احرص على ضبط:
```sql
SET @current_user_id = 12;
```
حتى يسجل النظام اسم المعدل الصحيح.
