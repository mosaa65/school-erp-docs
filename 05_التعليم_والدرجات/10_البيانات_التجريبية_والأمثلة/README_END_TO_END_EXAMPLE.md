# مثال عملي شامل (Subsystem 10)
## من السياسة إلى النتيجة النهائية

هذا المثال يوضح كيف تتحرك البيانات داخل النظام خطوة بخطوة بلغة بسيطة.

## الفكرة
سنستخدم شعبة واحدة (`classroom_id=41`) ومادة واحدة (`subject_id=3`) ونمر على:
1. سياسة الدرجات
2. الاختبارات
3. الواجبات
4. المحصلة الشهرية
5. نتائج الفصل
6. النتيجة النهائية

## الخطوة 1: تجهيز جلسة المستخدم
```sql
SET @current_user_id = 12;
```

## الخطوة 2: إدخال بيانات أولية (10 سجلات)
```sql
-- 1) سياسة
INSERT INTO grading_policies (
  academic_year_id, grade_level_id, subject_id, exam_type_id,
  max_exam_score, max_homework_score, max_attendance_score,
  max_activity_score, max_contribution_score, passing_score,
  is_default, created_by_user_id
) VALUES (1,8,3,1,20,5,5,5,4,50,1,12);

-- 2) تكليف المعلم
INSERT INTO teacher_assignments (
  academic_year_id, semester_id, employee_id, subject_id, classroom_id,
  is_primary, is_active, created_by_user_id
) VALUES (1,1,27,3,41,1,1,12);

-- 3) فترة اختبار شهرية
INSERT INTO exam_periods (
  academic_year_id, semester_id, name_ar, exam_type_id, status_id, created_by, is_active
) VALUES (1,1,'اختبار محرم',1,3,12,1);

-- 4) واجب
INSERT INTO homeworks (
  academic_year_id, semester_id, month_id, created_by, classroom_id,
  subject_id, homework_type_id, homework_date, due_date, title, max_grade, is_active
) VALUES (1,1,1,12,41,3,1,'2026-09-03','2026-09-05','واجب أول',5,1);
SET @hw_id = LAST_INSERT_ID();

-- 5..10) 6 سجلات متابعة طلاب للواجب
INSERT INTO student_homeworks (homework_id, enrollment_id, is_completed, manual_grade, notes) VALUES
(@hw_id,5001,1,NULL,''),
(@hw_id,5002,1,4.5,'جيد'),
(@hw_id,5003,0,NULL,'لم يسلم'),
(@hw_id,5004,1,NULL,''),
(@hw_id,5005,1,5.0,'ممتاز'),
(@hw_id,5006,1,NULL,'');
```

## الخطوة 3: الحساب الشهري
```sql
CALL sp_calculate_monthly_grades(1, 3, 41);
```

## الخطوة 4: حساب نتيجة الفصل
```sql
CALL sp_calculate_semester_totals(1, 3, 41);
CALL sp_fill_final_exam_score(1, 41);
```

## الخطوة 5: حساب نتيجة العام والترتيب
```sql
CALL sp_calculate_annual_results(1, 41);
```

## كيف أقرأ الناتج؟
- جدول `monthly_grades`: نتيجة كل شهر.
- جدول `semester_grades`: نتيجة الفصل.
- جدول `annual_grades`: نتيجة كل مادة على مستوى العام.
- جدول `annual_result`: النتيجة النهائية للطالب (نسبة + ترتيب + قرار).

## استعلامات تحقق سريعة
```sql
SELECT * FROM monthly_grades WHERE subject_id = 3 AND month_id = 1;
SELECT * FROM semester_grades WHERE subject_id = 3 AND semester_id = 1;
SELECT * FROM annual_result WHERE academic_year_id = 1 ORDER BY rank_in_class;
```
