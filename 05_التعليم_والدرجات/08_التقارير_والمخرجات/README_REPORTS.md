# التقارير والمخرجات (Subsystem 08)
## `DDL_REPORTS.sql`

هذا الجزء مسؤول عن تحويل البيانات الخام إلى تقارير مفهومة للإدارة والمعلم وولي الأمر.

## شرح مبسط
- يعطيك تقرير تفاصيل الدرجات لكل مادة في الشهر.
- يعطيك ملخص الطالب الشهري مع النسبة والترتيب.
- يحول النسبة إلى وصف واضح مثل: ممتاز، جيد، مقبول.

## شرح تقني
الجداول/الدوال/العروض:
1. `lookup_grade_descriptions` تعريف أوصاف التقدير.
2. `fn_get_grade_description(percentage)` إرجاع الوصف المناسب.
3. `v_rpt_monthly_subject_details` تقرير تفصيلي لكل مادة.
4. `v_rpt_monthly_student_summary` ملخص الطالب + ترتيبه.

## شرح جدول `lookup_grade_descriptions`
| العمود | English | لماذا موجود؟ | مثال |
|---|---|---|---|
| `id` | id | رقم السجل | `1` |
| `min_percentage` | min % | بداية نطاق النسبة | `90` |
| `max_percentage` | max % | نهاية النطاق | `100` |
| `name_ar` | Arabic grade | اسم التقدير عربي | `ممتاز` |
| `name_en` | English grade | ترجمة التقدير | `Excellent` |
| `color_code` | color code | لون العرض في الواجهة | `#2ecc71` |
| `sort_order` | order | ترتيب الظهور | `1` |
| `is_active` | active | تفعيل/تعطيل النطاق | `1` |

## كيف تتم العملية؟
1. النظام يقرأ درجات الشهر من `monthly_grades`.
2. يحسب الحد الأعلى من السياسة `grading_policies`.
3. يحسب النسبة ثم يستدعي `fn_get_grade_description`.
4. يعرض التقرير النهائي عبر Views.

## بيانات تجريبية (10 سجلات)
```sql
-- تخصيص 10 مستويات تقدير (اختياري)
INSERT INTO lookup_grade_descriptions (
  min_percentage, max_percentage, name_ar, name_en, color_code, sort_order, is_active
) VALUES
(95,100,'ممتاز مرتفع','Outstanding','#1abc9c',1,1),
(90,94.99,'ممتاز','Excellent','#2ecc71',2,1),
(85,89.99,'جيد جدا مرتفع','Very Good+','#27ae60',3,1),
(80,84.99,'جيد جدا','Very Good','#3498db',4,1),
(75,79.99,'جيد مرتفع','Good+','#2980b9',5,1),
(70,74.99,'جيد','Good','#f39c12',6,1),
(65,69.99,'مقبول مرتفع','Acceptable+','#e67e22',7,1),
(60,64.99,'مقبول','Acceptable','#d35400',8,1),
(50,59.99,'دون المتوسط','Below Avg','#c0392b',9,1),
(0,49.99,'ضعيف','Weak','#e74c3c',10,1);
```

## أمثلة استعلامات مفيدة
```sql
-- تقرير مواد طالب في شهر محدد
SELECT *
FROM v_rpt_monthly_subject_details
WHERE enrollment_id = 5001 AND month_id = 1
ORDER BY order_index;

-- ملخص الطالب الشهري
SELECT *
FROM v_rpt_monthly_student_summary
WHERE enrollment_id = 5001 AND month_id = 1;
```
