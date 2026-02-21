-- ==================================================================================
-- نظام التعليم والدرجات (System 05) - وحدة دفتر المتابعة الذكي (11)
-- ==================================================================================
-- الوصف: إنشاء الجداول والمناظير (Views) الخاصة بتوليد دفاتر المتابعة (الذكية والمستقلة).
-- يعتمد النظام على استقاء البيانات من أنظمة (الطلاب، الجدول الذكي، التقويم المرجعي).
-- ==================================================================================

-- ----------------------------------------------------------------------------------
-- 1. جدول قوالب الدفاتر الدائمة (Notebook Templates)
-- ----------------------------------------------------------------------------------
-- يحفظ التصاميم والأشكال المختلفة لدفاتر المتابعة (مثلاً قالب المرحلة الابتدائية، المسطر..الخ)
CREATE TABLE IF NOT EXISTS `notebook_templates` (
    `template_id` INT AUTO_INCREMENT PRIMARY KEY,
    `template_name_ar` VARCHAR(100) NOT NULL COMMENT 'اسم القالب بالعربية',
    `template_name_en` VARCHAR(100) DEFAULT NULL COMMENT 'اسم القالب بالإنجليزية',
    `description` TEXT COMMENT 'وصف القالب واستخدامه',
    `layout_type` ENUM('grid', 'lined', 'custom') DEFAULT 'grid' COMMENT 'نوع تخطيط الدفتر',
    `is_active` BOOLEAN DEFAULT TRUE COMMENT 'تفعيل أو إيقاف القالب',
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='تخزين إعدادات وتصاميم جاهزة لدفاتر المتابعة';

-- ----------------------------------------------------------------------------------
-- 2. جدول سجلات طباعة الدفاتر (Notebook Print Logs)
-- ----------------------------------------------------------------------------------
-- تتبع عمليات استخراج وطباعة الدفاتر عبر النظام لمعرفة هل المعلم مهتم بالتحضير أم لا
CREATE TABLE IF NOT EXISTS `notebook_print_logs` (
    `log_id` INT AUTO_INCREMENT PRIMARY KEY,
    `teacher_id` INT NULL COMMENT 'رقم المعلم (في النمط المستقل قد يكون فارغاً)',
    `subject_id` INT NULL COMMENT 'المقرر (في النمط المستقل قد يكون فارغاً)',
    `class_id` INT NOT NULL COMMENT 'الشعبة المستهدفة بالدفتر',
    `template_id` INT NOT NULL COMMENT 'القالب المستخدم في الطباعة',
    `printed_by` INT NOT NULL COMMENT 'المستخدم الذي قام بتوليد الدفتر',
    `print_mode` ENUM('smart', 'standalone') NOT NULL COMMENT 'نمط طباعة الدفتر: ذكي أو فصل عام',
    `date_from` DATE NOT NULL COMMENT 'الفترة المطبوعة من',
    `date_to` DATE NOT NULL COMMENT 'الفترة المطبوعة إلى',
    `print_date` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (`template_id`) REFERENCES `notebook_templates`(`template_id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='سجل تتبع من قام بطباعة دفاتر المتابعة ومتى';


-- ==================================================================================
-- 3. المناظير الذكية (Smart Engine Views)
-- ==================================================================================
-- هذه المناظير هي العقل المدبر لتوليد هيكل الدفتر ديناميكياً

-- آ. منظور أيام النمط الذكي (Smart Mode Days)
-- يعتمد على جدول حصص المعلم (System 11) + التقويم المرجعي (System 01)
-- يعيد الأيام التي بها حصص فعلية فقط مستبعداً الإجازات
CREATE OR REPLACE VIEW `vw_smart_notebook_smart_days` AS
SELECT 
    tp.teacher_id,
    tp.class_id,
    tp.subject_id,
    tp.day_of_week,
    cal.gregorian_date,
    cal.hijri_date,
    cal.is_holiday,
    cal.holiday_name
FROM `time_table_periods` tp
JOIN `reference_calendar` cal ON cal.day_of_week = tp.day_of_week
WHERE cal.is_holiday = FALSE
  AND cal.is_weekend = FALSE;

-- ب. منظور أيام النمط المستقل (Standalone Mode Days)
-- لكل أيام العمل الأسبوعية بغض النظر عن حصص مخصصة (يستمد من التقويم فقط)
CREATE OR REPLACE VIEW `vw_smart_notebook_standalone_days` AS
SELECT 
    cal.gregorian_date,
    cal.hijri_date,
    cal.day_of_week,
    cal.is_holiday,
    cal.holiday_name
FROM `reference_calendar` cal
WHERE cal.is_holiday = FALSE
  AND cal.is_weekend = FALSE;

-- ج. منظور مواد الشعبة (Standalone Mode Subjects)
-- يجلب جميع المواد المسندة لهذه الشعبة لتوليد أقسام الدفتر العام
CREATE OR REPLACE VIEW `vw_smart_notebook_subjects` AS
SELECT 
    cs.class_id,
    cs.subject_id,
    s.subject_name_ar,
    s.subject_name_en,
    s.color_code
FROM `class_subjects` cs
JOIN `subjects` s ON cs.subject_id = s.subject_id
WHERE cs.is_active = TRUE;

-- د. منظور طلاب الدفتر (Notebook Students)
-- يجلب بيانات الطلاب المسجلين حالياً في الشعبة لطباعة أسمائهم
CREATE OR REPLACE VIEW `vw_smart_notebook_students` AS
SELECT 
    sc.class_id,
    s.student_id,
    s.first_name,
    s.last_name,
    s.national_id,
    s.profile_photo AS profile_picture_url,
    sc.enrollment_date
FROM `student_enrollments` sc
JOIN `students` s ON sc.student_id = s.student_id
WHERE sc.enrollment_status = 'active'
ORDER BY s.first_name, s.last_name;

-- هـ. منظور أعمدة التقييم (Evaluation Columns)
-- يجلب التقسيمات الخاصة بمادة معينة من سياسات الدرجات لرسم أعمدة التقييم في الدفتر
CREATE OR REPLACE VIEW `vw_smart_notebook_evaluation_cols` AS
SELECT 
    gp.policy_id,
    gp.subject_id,
    gpc.category_name_ar,
    gpc.category_name_en,
    gpc.max_score,
    gpc.weight_percentage
FROM `grading_policies` gp
JOIN `grading_policy_categories` gpc ON gp.policy_id = gpc.policy_id
WHERE gp.is_active = TRUE;
