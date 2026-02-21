# أدوات النسخ السنوي (Subsystem 09)
## `DDL_TOOLS.sql`

هذا الجزء يوفر أوامر جاهزة لفتح سنة دراسية جديدة بسرعة بدون إعادة إدخال كل الإعدادات يدويا.

## شرح مبسط
- بدل إعادة كتابة السياسات والفترات كل سنة، النظام ينسخها من سنة سابقة.
- هذا يقلل الأخطاء ويوفر الوقت.

## الإجراءات المتاحة
1. `sp_copy_policies(source_year, target_year)`
2. `sp_copy_exam_periods(source_year, target_year)`
3. `sp_copy_outcome_rules(source_year, target_year)`
4. `sp_copy_all_year_settings(source_year, target_year)`

## شرح المعلمات (ترجمة)
| المعلمة | English | معناها | مثال |
|---|---|---|---|
| `p_source_year_id` | source year id | العام المصدر | `1` |
| `p_target_year_id` | target year id | العام الهدف | `2` |

## كيف تتم العملية؟
1. تتأكد أن العامين موجودين.
2. تنسخ السياسات (مع الجوانب المخصصة).
3. تنسخ الفترات الامتحانية للفصل المقابل.
4. تنسخ قواعد النقل وكسر التعادل.

## أمثلة تشغيل (10 أوامر)
```sql
-- 1
CALL sp_copy_policies(1, 2);
-- 2
CALL sp_copy_exam_periods(1, 2);
-- 3
CALL sp_copy_outcome_rules(1, 2);
-- 4
CALL sp_copy_all_year_settings(1, 2);

-- 5
CALL sp_copy_policies(2, 3);
-- 6
CALL sp_copy_exam_periods(2, 3);
-- 7
CALL sp_copy_outcome_rules(2, 3);
-- 8
CALL sp_copy_all_year_settings(2, 3);

-- 9
CALL sp_copy_policies(3, 4);
-- 10
CALL sp_copy_all_year_settings(3, 4);
```

## ملاحظات مهمة
- لا يسمح النسخ من العام إلى نفسه.
- في الفترات الامتحانية: التواريخ التفصيلية تكمّل لاحقا من نظام الجدولة (System 08).
- الإجراء الشامل هو الأفضل للاستخدام اليومي.
