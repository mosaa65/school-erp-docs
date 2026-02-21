-- ╔══════════════════════════════════════════════════════════════════════════════╗
-- ║                    نظام جدول الحصص الأسبوعية الذكي                           ║
-- ║           Intelligent Timetable System Database Schema                        ║
-- ║                                                                               ║
-- ║    يشمل: إصدارات الجدول، التوزيع الذكي، التوازن، المحاكاة، التدقيق           ║
-- ╚══════════════════════════════════════════════════════════════════════════════╝

-- التاريخ: 2026-01-12
-- الإصدار: 1.0
-- المهندس المسؤول: موسى العواضي (تصميم واعتماد)
-- قاعدة البيانات: MySQL 8.0+

-- ═══════════════════════════════════════════════════════════════════════════════
-- القسم 1: جداول Lookup لنظام الجدول
-- ═══════════════════════════════════════════════════════════════════════════════

-- جدول حالات إصدار الجدول
CREATE TABLE IF NOT EXISTS lookup_timetable_statuses (
    id TINYINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name_ar VARCHAR(30) NOT NULL COMMENT 'الحالة بالعربية',
    code VARCHAR(20) NOT NULL UNIQUE COMMENT 'رمز الحالة',
    description VARCHAR(100) COMMENT 'وصف الحالة',
    color VARCHAR(10) COMMENT 'لون العرض',
    sort_order TINYINT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='حالات إصدار جدول الحصص';

INSERT INTO lookup_timetable_statuses (name_ar, code, description, color, sort_order) VALUES
('مسودة', 'DRAFT', 'جدول قيد الإعداد', '#6c757d', 1),
('محاكاة', 'SIMULATED', 'جدول تم اختباره بالمحاكاة', '#17a2b8', 2),
('معتمد', 'APPROVED', 'جدول معتمد للتنفيذ', '#28a745', 3),
('ملغي', 'CANCELLED', 'جدول ملغي', '#dc3545', 4),
('مؤرشف', 'ARCHIVED', 'جدول مؤرشف', '#6c757d', 5);

-- جدول أولويات المواد
CREATE TABLE IF NOT EXISTS lookup_subject_weights (
    id TINYINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name_ar VARCHAR(30) NOT NULL COMMENT 'الوزن بالعربية',
    code VARCHAR(20) NOT NULL UNIQUE COMMENT 'رمز الوزن',
    description VARCHAR(100) COMMENT 'وصف الوزن',
    preferred_periods VARCHAR(50) COMMENT 'الحصص المفضلة (مثل: 1,2)',
    sort_order TINYINT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='أوزان المواد (ثقيلة/متوسطة/خفيفة)';

INSERT INTO lookup_subject_weights (name_ar, code, description, preferred_periods, sort_order) VALUES
('ثقيلة', 'HEAVY', 'مواد تتطلب تركيز عالي (رياضيات، لغة عربية)', '1,2', 1),
('متوسطة', 'MEDIUM', 'مواد متوسطة التركيز (علوم، إنجليزي)', '3,4', 2),
('خفيفة', 'LIGHT', 'مواد خفيفة (فنية، رياضة)', '5,6', 3);

-- جدول أنواع القيود
CREATE TABLE IF NOT EXISTS lookup_constraint_types (
    id TINYINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name_ar VARCHAR(50) NOT NULL COMMENT 'نوع القيد',
    code VARCHAR(30) NOT NULL UNIQUE COMMENT 'رمز القيد',
    applies_to ENUM('معلم', 'صف', 'مادة', 'عام') DEFAULT 'عام',
    description VARCHAR(200) COMMENT 'وصف القيد',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='أنواع قيود الجدولة';

INSERT INTO lookup_constraint_types (name_ar, code, applies_to, description) VALUES
('إجازة معلم', 'TEACHER_LEAVE', 'معلم', 'المعلم غير متاح في وقت محدد'),
('حصة محجوزة', 'RESERVED_SLOT', 'صف', 'حصة محجوزة لنشاط معين'),
('منع تكرار', 'NO_REPEAT', 'مادة', 'منع تكرار المادة في نفس اليوم'),
('حد أقصى يومي', 'MAX_DAILY', 'معلم', 'الحد الأقصى لحصص المعلم يومياً'),
('فترة راحة', 'BREAK_REQUIRED', 'معلم', 'فترة راحة إلزامية'),
('عدم انتقال', 'NO_BUILDING_CHANGE', 'معلم', 'منع الانتقال بين المباني في حصص متتالية');

-- ═══════════════════════════════════════════════════════════════════════════════
-- القسم 2: إصدارات الجدول (Versioning)
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS timetable_versions (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    
    -- الربط بالسنة والفصل
    academic_year_id INT UNSIGNED NOT NULL COMMENT 'العام الدراسي',
    semester_id INT UNSIGNED NOT NULL COMMENT 'الفصل الدراسي',
    
    -- معلومات الإصدار
    version_number SMALLINT UNSIGNED NOT NULL DEFAULT 1 COMMENT 'رقم الإصدار',
    version_name VARCHAR(100) COMMENT 'اسم الإصدار',
    description TEXT COMMENT 'وصف الإصدار',
    
    -- الحالة
    status_id TINYINT UNSIGNED NOT NULL DEFAULT 1 COMMENT 'حالة الإصدار',
    is_active BOOLEAN DEFAULT FALSE COMMENT 'الإصدار النشط حالياً',
    
    -- تواريخ السريان
    effective_from DATE COMMENT 'سريان من تاريخ',
    effective_to DATE COMMENT 'سريان حتى تاريخ',
    
    -- الاعتماد
    approved_at TIMESTAMP NULL COMMENT 'تاريخ الاعتماد',
    approved_by_user_id INT UNSIGNED COMMENT 'اعتمده',
    approval_notes TEXT COMMENT 'ملاحظات الاعتماد',
    
    -- إحصائيات
    total_slots INT UNSIGNED DEFAULT 0 COMMENT 'إجمالي الحصص',
    total_conflicts INT UNSIGNED DEFAULT 0 COMMENT 'التعارضات المكتشفة',
    
    -- التدقيق
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NULL ON UPDATE CURRENT_TIMESTAMP,
    created_by_user_id INT UNSIGNED COMMENT 'أنشأه',
    
    -- المفاتيح الخارجية
    CONSTRAINT fk_ttversion_year FOREIGN KEY (academic_year_id) 
        REFERENCES academic_years(id) ON DELETE RESTRICT,
    CONSTRAINT fk_ttversion_semester FOREIGN KEY (semester_id) 
        REFERENCES semesters(id) ON DELETE RESTRICT,
    CONSTRAINT fk_ttversion_status FOREIGN KEY (status_id) 
        REFERENCES lookup_timetable_statuses(id) ON DELETE RESTRICT,
    CONSTRAINT fk_ttversion_approver FOREIGN KEY (approved_by_user_id) 
        REFERENCES users(id) ON DELETE SET NULL,
    CONSTRAINT fk_ttversion_creator FOREIGN KEY (created_by_user_id) 
        REFERENCES users(id) ON DELETE SET NULL,
    
    -- القيود
    UNIQUE KEY uk_ttversion (academic_year_id, semester_id, version_number),
    INDEX idx_ttversion_status (status_id),
    INDEX idx_ttversion_active (is_active)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='إصدارات جدول الحصص';

-- ═══════════════════════════════════════════════════════════════════════════════
-- القسم 3: أولويات المواد (Subject Priorities)
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS subject_priorities (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    
    subject_id INT UNSIGNED NOT NULL COMMENT 'المادة',
    grade_level_id INT UNSIGNED NULL COMMENT 'الصف (NULL = كل الصفوف)',
    
    -- الأولوية والوزن
    weight_id TINYINT UNSIGNED NOT NULL COMMENT 'وزن المادة',
    weekly_periods TINYINT UNSIGNED NOT NULL DEFAULT 1 COMMENT 'الحصص الأسبوعية',
    
    -- قواعد التكرار
    allow_daily_repeat BOOLEAN DEFAULT FALSE COMMENT 'السماح بالتكرار اليومي',
    max_daily_periods TINYINT UNSIGNED DEFAULT 1 COMMENT 'الحد الأقصى يومياً',
    min_periods_for_repeat TINYINT UNSIGNED DEFAULT 5 COMMENT 'الحد الأدنى للسماح بالتكرار',
    
    -- التدقيق
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NULL ON UPDATE CURRENT_TIMESTAMP,
    created_by_user_id INT UNSIGNED COMMENT 'أنشأه',
    
    -- المفاتيح الخارجية
    CONSTRAINT fk_subjprio_subject FOREIGN KEY (subject_id) 
        REFERENCES subjects(id) ON DELETE CASCADE,
    CONSTRAINT fk_subjprio_grade FOREIGN KEY (grade_level_id) 
        REFERENCES grade_levels(id) ON DELETE CASCADE,
    CONSTRAINT fk_subjprio_weight FOREIGN KEY (weight_id) 
        REFERENCES lookup_subject_weights(id) ON DELETE RESTRICT,
    CONSTRAINT fk_subjprio_creator FOREIGN KEY (created_by_user_id) 
        REFERENCES users(id) ON DELETE SET NULL,
    
    -- القيود
    UNIQUE KEY uk_subjprio (subject_id, grade_level_id),
    INDEX idx_subjprio_weight (weight_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='أولويات وأوزان المواد للجدولة';

-- إدخال أولويات المواد الافتراضية
-- إدخال أولويات المواد (مستوى دقيق: مادة لكل صف)
INSERT INTO subject_priorities (subject_id, grade_level_id, weight_id, weekly_periods, allow_daily_repeat)
SELECT 
    gs.subject_id,
    gs.grade_level_id, 
    CASE 
        WHEN s.code IN ('MATH', 'ARB') THEN 1  -- ثقيلة
        WHEN s.code IN ('SCI', 'ENG', 'PHY', 'CHM', 'BIO') THEN 2  -- متوسطة
        ELSE 3  -- خفيفة
    END,
    gs.weekly_periods,
    CASE WHEN s.code IN ('MATH', 'ARB') THEN TRUE ELSE FALSE END
FROM grade_subjects gs
JOIN subjects s ON gs.subject_id = s.id
WHERE s.is_active = TRUE;

-- ═══════════════════════════════════════════════════════════════════════════════
-- القسم 4: توفر المعلمين (Teacher Availability)
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS teacher_availability (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    
    employee_id INT UNSIGNED NOT NULL COMMENT 'المعلم',
    academic_year_id INT UNSIGNED NOT NULL COMMENT 'العام الدراسي',
    
    -- الوقت
    day_id TINYINT UNSIGNED NOT NULL COMMENT 'اليوم',
    period_number TINYINT UNSIGNED NOT NULL COMMENT 'رقم الحصة',
    
    -- الصلاحية الزمنية
    effective_from DATE NULL COMMENT 'بداية السريان',
    effective_to DATE NULL COMMENT 'نهاية السريان',
    
    -- الحالة
    is_available BOOLEAN DEFAULT TRUE COMMENT 'متاح',
    reason VARCHAR(200) COMMENT 'السبب إذا غير متاح',
    
    -- التدقيق
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by_user_id INT UNSIGNED COMMENT 'أنشأه',
    
    -- المفاتيح الخارجية
    CONSTRAINT fk_teachavail_employee FOREIGN KEY (employee_id) 
        REFERENCES employees(id) ON DELETE CASCADE,
    CONSTRAINT fk_teachavail_year FOREIGN KEY (academic_year_id) 
        REFERENCES academic_years(id) ON DELETE CASCADE,
    CONSTRAINT fk_teachavail_day FOREIGN KEY (day_id) 
        REFERENCES lookup_days(id) ON DELETE RESTRICT,
    CONSTRAINT fk_teachavail_creator FOREIGN KEY (created_by_user_id) 
        REFERENCES users(id) ON DELETE SET NULL,
    
    -- القيود
    UNIQUE KEY uk_teachavail (employee_id, academic_year_id, day_id, period_number),
    INDEX idx_teachavail_employee (employee_id),
    INDEX idx_teachavail_available (is_available)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='جدول توفر المعلمين';

-- ═══════════════════════════════════════════════════════════════════════════════
-- القسم 5: حصص الجدول (Timetable Slots)
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS timetable_slots (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    
    -- الربط بالإصدار
    version_id INT UNSIGNED NOT NULL COMMENT 'إصدار الجدول',
    
    -- الحصة
    classroom_id INT UNSIGNED NOT NULL COMMENT 'الشعبة',
    day_id TINYINT UNSIGNED NOT NULL COMMENT 'اليوم',
    period_number TINYINT UNSIGNED NOT NULL COMMENT 'رقم الحصة (1-8)',
    
    -- المادة والمعلم
    subject_id INT UNSIGNED NOT NULL COMMENT 'المادة',
    employee_id INT UNSIGNED NOT NULL COMMENT 'المعلم',
    
    -- نوع الحصة
    slot_type_id TINYINT UNSIGNED NOT NULL COMMENT 'FK to lookup_timetable_slot_types',
    
    -- التثبيت
    is_fixed BOOLEAN DEFAULT FALSE COMMENT 'حصة مثبتة لا تتغير عند إعادة التوزيع',
    fixed_reason VARCHAR(200) COMMENT 'سبب التثبيت',
    
    -- ملاحظات
    notes TEXT COMMENT 'ملاحظات',
    
    -- التدقيق
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NULL ON UPDATE CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL COMMENT 'الحذف الناعم',
    
    -- المفاتيح الخارجية
    CONSTRAINT fk_ttslot_version FOREIGN KEY (version_id) 
        REFERENCES timetable_versions(id) ON DELETE CASCADE,
    CONSTRAINT fk_ttslot_classroom FOREIGN KEY (classroom_id) 
        REFERENCES classrooms(id) ON DELETE RESTRICT,
    CONSTRAINT fk_ttslot_day FOREIGN KEY (day_id) 
        REFERENCES lookup_days(id) ON DELETE RESTRICT,
    CONSTRAINT fk_ttslot_subject FOREIGN KEY (subject_id) 
        REFERENCES subjects(id) ON DELETE RESTRICT,
    CONSTRAINT fk_ttslot_employee FOREIGN KEY (employee_id) 
        REFERENCES employees(id) ON DELETE RESTRICT,
    CONSTRAINT fk_ttslot_type FOREIGN KEY (slot_type_id)
        REFERENCES lookup_timetable_slot_types(id) ON DELETE RESTRICT,
    
    -- القيود - منع التعارض الهيكلي فقط
    CHECK (period_number BETWEEN 1 AND 8),
    UNIQUE KEY uk_ttslot_classroom (version_id, classroom_id, day_id, period_number),
    -- ملاحظة: تم إزالة UNIQUE الخاص بالمعلم للسماح للمحاكاة باكتشاف التعارضات وحلها يدوياً
    INDEX idx_ttslot_version (version_id),
    INDEX idx_ttslot_employee (employee_id),
    INDEX idx_ttslot_day (day_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='حصص جدول الدروس';

-- ═══════════════════════════════════════════════════════════════════════════════
-- القسم 6: الحصص المرنة (Flexible Slots)
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS flexible_slots (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    
    version_id INT UNSIGNED NOT NULL COMMENT 'إصدار الجدول',
    classroom_id INT UNSIGNED NOT NULL COMMENT 'الشعبة',
    
    -- الحصة المرنة المخصصة
    day_id TINYINT UNSIGNED NOT NULL COMMENT 'اليوم',
    period_number TINYINT UNSIGNED NOT NULL COMMENT 'رقم الحصة',
    
    -- الاستخدام
    is_used BOOLEAN DEFAULT FALSE COMMENT 'تم استخدامها',
    used_for VARCHAR(200) COMMENT 'استخدمت لـ',
    used_date DATE COMMENT 'تاريخ الاستخدام',
    replacement_subject_id INT UNSIGNED COMMENT 'المادة البديلة',
    replacement_employee_id INT UNSIGNED COMMENT 'المعلم البديل',
    
    -- التدقيق
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NULL ON UPDATE CURRENT_TIMESTAMP,
    
    -- المفاتيح الخارجية
    CONSTRAINT fk_flexslot_version FOREIGN KEY (version_id) 
        REFERENCES timetable_versions(id) ON DELETE CASCADE,
    CONSTRAINT fk_flexslot_classroom FOREIGN KEY (classroom_id) 
        REFERENCES classrooms(id) ON DELETE CASCADE,
    CONSTRAINT fk_flexslot_day FOREIGN KEY (day_id) 
        REFERENCES lookup_days(id) ON DELETE RESTRICT,
    CONSTRAINT fk_flexslot_subject FOREIGN KEY (replacement_subject_id) 
        REFERENCES subjects(id) ON DELETE SET NULL,
    CONSTRAINT fk_flexslot_employee FOREIGN KEY (replacement_employee_id) 
        REFERENCES employees(id) ON DELETE SET NULL,
    
    -- القيود
    UNIQUE KEY uk_flexslot (version_id, classroom_id, day_id, period_number),
    INDEX idx_flexslot_used (is_used)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='الحصص المرنة لكل شعبة';

-- ═══════════════════════════════════════════════════════════════════════════════
-- القسم 7: حسابات أحمال المعلمين (Workload Calculations)
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS teacher_workload (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    
    version_id INT UNSIGNED NOT NULL COMMENT 'إصدار الجدول',
    employee_id INT UNSIGNED NOT NULL COMMENT 'المعلم',
    
    -- الحصص
    total_periods TINYINT UNSIGNED DEFAULT 0 COMMENT 'إجمالي الحصص الأسبوعية',
    periods_per_day JSON COMMENT 'الحصص لكل يوم {1:4, 2:5, ...}',
    
    -- التوازن
    workload_score DECIMAL(5,2) COMMENT 'نقاط الحمل (للمقارنة)',
    is_overloaded BOOLEAN DEFAULT FALSE COMMENT 'محمّل زيادة',
    is_underloaded BOOLEAN DEFAULT FALSE COMMENT 'محمّل أقل',
    
    -- التوصيات
    recommended_adjustment TEXT COMMENT 'التعديل المقترح',
    
    -- التدقيق
    calculated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- المفاتيح الخارجية
    CONSTRAINT fk_workload_version FOREIGN KEY (version_id) 
        REFERENCES timetable_versions(id) ON DELETE CASCADE,
    CONSTRAINT fk_workload_employee FOREIGN KEY (employee_id) 
        REFERENCES employees(id) ON DELETE CASCADE,
    
    -- القيود
    UNIQUE KEY uk_workload (version_id, employee_id),
    INDEX idx_workload_score (workload_score),
    INDEX idx_workload_overloaded (is_overloaded)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='حسابات أحمال المعلمين';

-- ═══════════════════════════════════════════════════════════════════════════════
-- القسم 8: قيود الجدولة (Scheduling Constraints)
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS scheduling_constraints (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    
    academic_year_id INT UNSIGNED NOT NULL COMMENT 'العام الدراسي',
    
    -- نوع القيد
    constraint_type_id TINYINT UNSIGNED NOT NULL COMMENT 'نوع القيد',
    
    -- الكيان المتأثر
    employee_id INT UNSIGNED NULL COMMENT 'المعلم (إن وجد)',
    classroom_id INT UNSIGNED NULL COMMENT 'الشعبة (إن وجد)',
    subject_id INT UNSIGNED NULL COMMENT 'المادة (إن وجد)',
    
    -- الوقت المتأثر
    day_id TINYINT UNSIGNED NULL COMMENT 'اليوم (NULL = كل الأيام)',
    period_number TINYINT UNSIGNED NULL COMMENT 'الحصة (NULL = كل الحصص)',
    start_date DATE NULL COMMENT 'من تاريخ',
    end_date DATE NULL COMMENT 'حتى تاريخ',
    
    -- تفاصيل القيد
    constraint_value VARCHAR(100) COMMENT 'قيمة القيد (مثل: الحد الأقصى)',
    priority TINYINT UNSIGNED DEFAULT 5 COMMENT 'أولوية القيد (1=أعلى)',
    is_mandatory BOOLEAN DEFAULT TRUE COMMENT 'قيد إلزامي',
    
    -- ملاحظات
    notes TEXT COMMENT 'ملاحظات',
    
    -- الحالة
    is_active BOOLEAN DEFAULT TRUE COMMENT 'نشط',
    
    -- التدقيق
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by_user_id INT UNSIGNED COMMENT 'أنشأه',
    
    -- المفاتيح الخارجية
    CONSTRAINT fk_schedconst_year FOREIGN KEY (academic_year_id) 
        REFERENCES academic_years(id) ON DELETE CASCADE,
    CONSTRAINT fk_schedconst_type FOREIGN KEY (constraint_type_id) 
        REFERENCES lookup_constraint_types(id) ON DELETE RESTRICT,
    CONSTRAINT fk_schedconst_employee FOREIGN KEY (employee_id) 
        REFERENCES employees(id) ON DELETE CASCADE,
    CONSTRAINT fk_schedconst_classroom FOREIGN KEY (classroom_id) 
        REFERENCES classrooms(id) ON DELETE CASCADE,
    CONSTRAINT fk_schedconst_subject FOREIGN KEY (subject_id) 
        REFERENCES subjects(id) ON DELETE CASCADE,
    CONSTRAINT fk_schedconst_day FOREIGN KEY (day_id) 
        REFERENCES lookup_days(id) ON DELETE SET NULL,
    CONSTRAINT fk_schedconst_creator FOREIGN KEY (created_by_user_id) 
        REFERENCES users(id) ON DELETE SET NULL,
    
    -- الفهارس
    INDEX idx_schedconst_year (academic_year_id),
    INDEX idx_schedconst_type (constraint_type_id),
    INDEX idx_schedconst_active (is_active)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='قيود الجدولة';

-- ═══════════════════════════════════════════════════════════════════════════════
-- القسم 9: المحاكاة (Simulation)
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS simulation_runs (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    
    version_id INT UNSIGNED NOT NULL COMMENT 'إصدار الجدول',
    
    -- معلومات المحاكاة
    run_number SMALLINT UNSIGNED NOT NULL COMMENT 'رقم المحاكاة',
    simulation_type ENUM('كاملة', 'جزئية', 'تعديل') DEFAULT 'كاملة',
    
    -- النتائج
    status ENUM('جارية', 'ناجحة', 'فاشلة') DEFAULT 'جارية',
    total_conflicts INT UNSIGNED DEFAULT 0 COMMENT 'عدد التعارضات',
    total_warnings INT UNSIGNED DEFAULT 0 COMMENT 'عدد التحذيرات',
    workload_balance_score DECIMAL(5,2) COMMENT 'نقاط توازن الأحمال',
    
    -- التوقيت
    started_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP NULL,
    duration_seconds INT UNSIGNED COMMENT 'المدة بالثواني',
    
    -- ملاحظات
    notes TEXT COMMENT 'ملاحظات المحاكاة',
    
    -- التدقيق والأداء
    run_by_user_id INT UNSIGNED COMMENT 'نفذها',
    execution_time_ms INT UNSIGNED COMMENT 'وقت التنفيذ بالملي ثانية',
    
    -- المفاتيح الخارجية
    CONSTRAINT fk_simrun_version FOREIGN KEY (version_id) 
        REFERENCES timetable_versions(id) ON DELETE CASCADE,
    CONSTRAINT fk_simrun_user FOREIGN KEY (run_by_user_id) 
        REFERENCES users(id) ON DELETE SET NULL,
    
    -- القيود
    INDEX idx_simrun_version (version_id),
    INDEX idx_simrun_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='سجل المحاكاة';

-- ═══════════════════════════════════════════════════════════════════════════════
-- القسم 10: التعارضات المكتشفة (Conflicts)
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS simulation_conflicts (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    
    simulation_id INT UNSIGNED NOT NULL COMMENT 'رقم المحاكاة',
    
    -- نوع التعارض
    conflict_type ENUM('معلم_مكانين', 'تكرار_مادة', 'تجاوز_حمل', 'قيد_منتهك', 'أخرى') NOT NULL,
    severity ENUM('خطأ', 'تحذير', 'معلومة') DEFAULT 'خطأ',
    
    -- موقع التعارض
    day_id TINYINT UNSIGNED NULL COMMENT 'اليوم',
    period_number TINYINT UNSIGNED NULL COMMENT 'الحصة',
    
    -- الكيانات المتأثرة
    employee_id INT UNSIGNED NULL COMMENT 'المعلم',
    classroom_id INT UNSIGNED NULL COMMENT 'الشعبة',
    subject_id INT UNSIGNED NULL COMMENT 'المادة',
    
    -- التفاصيل
    description TEXT NOT NULL COMMENT 'وصف التعارض',
    suggested_fix TEXT COMMENT 'الحل المقترح',
    
    -- الحل
    is_resolved BOOLEAN DEFAULT FALSE COMMENT 'تم حله',
    resolved_at TIMESTAMP NULL,
    resolved_by_user_id INT UNSIGNED NULL,
    resolution_notes TEXT COMMENT 'ملاحظات الحل',
    
    -- التدقيق
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- المفاتيح الخارجية
    CONSTRAINT fk_conflict_sim FOREIGN KEY (simulation_id) 
        REFERENCES simulation_runs(id) ON DELETE CASCADE,
    CONSTRAINT fk_conflict_day FOREIGN KEY (day_id) 
        REFERENCES lookup_days(id) ON DELETE SET NULL,
    CONSTRAINT fk_conflict_employee FOREIGN KEY (employee_id) 
        REFERENCES employees(id) ON DELETE SET NULL,
    CONSTRAINT fk_conflict_classroom FOREIGN KEY (classroom_id) 
        REFERENCES classrooms(id) ON DELETE SET NULL,
    CONSTRAINT fk_conflict_subject FOREIGN KEY (subject_id) 
        REFERENCES subjects(id) ON DELETE SET NULL,
    CONSTRAINT fk_conflict_resolver FOREIGN KEY (resolved_by_user_id) 
        REFERENCES users(id) ON DELETE SET NULL,
    
    -- الفهارس
    INDEX idx_conflict_sim (simulation_id),
    INDEX idx_conflict_type (conflict_type),
    INDEX idx_conflict_resolved (is_resolved)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='التعارضات المكتشفة في المحاكاة';

-- ═══════════════════════════════════════════════════════════════════════════════
-- القسم 11: سجل تصدير الجدول (Export Log)
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS timetable_exports (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    
    version_id INT UNSIGNED NOT NULL COMMENT 'إصدار الجدول',
    
    -- نوع التصدير
    export_type ENUM('PDF', 'Excel', 'بوابة', 'معلمين', 'JSON') NOT NULL,
    export_scope ENUM('كامل', 'صف', 'معلم', 'شعبة') DEFAULT 'كامل',
    scope_id INT UNSIGNED NULL COMMENT 'معرف النطاق (صف/معلم/شعبة)',
    
    -- الملف
    file_path VARCHAR(500) COMMENT 'مسار الملف',
    file_size INT UNSIGNED COMMENT 'حجم الملف بالبايت',
    
    -- التدقيق
    exported_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    exported_by_user_id INT UNSIGNED COMMENT 'صدّره',
    
    -- المفاتيح الخارجية
    CONSTRAINT fk_export_version FOREIGN KEY (version_id) 
        REFERENCES timetable_versions(id) ON DELETE CASCADE,
    CONSTRAINT fk_export_user FOREIGN KEY (exported_by_user_id) 
        REFERENCES users(id) ON DELETE SET NULL,
    
    -- الفهارس
    INDEX idx_export_version (version_id),
    INDEX idx_export_date (exported_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='سجل تصدير الجدول';

-- ═══════════════════════════════════════════════════════════════════════════════
-- القسم 12: سجل تدقيق الجدول (Audit Log)
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS timetable_audit_log (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    
    version_id INT UNSIGNED NOT NULL COMMENT 'إصدار الجدول',
    
    -- نوع الإجراء
    action ENUM('CREATE', 'UPDATE', 'DELETE', 'APPROVE', 'SIMULATE', 'EXPORT', 'FIX', 'REVERT') NOT NULL,
    
    -- التفاصيل
    entity_type VARCHAR(50) COMMENT 'نوع الكيان المتأثر',
    entity_id INT UNSIGNED COMMENT 'معرف الكيان',
    old_values JSON COMMENT 'القيم القديمة',
    new_values JSON COMMENT 'القيم الجديدة',
    description TEXT COMMENT 'وصف الإجراء',
    
    -- التدقيق
    user_id INT UNSIGNED NULL COMMENT 'المستخدم',
    ip_address VARCHAR(45) COMMENT 'عنوان IP',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- المفاتيح الخارجية
    CONSTRAINT fk_ttaudit_version FOREIGN KEY (version_id) 
        REFERENCES timetable_versions(id) ON DELETE CASCADE,
    CONSTRAINT fk_ttaudit_user FOREIGN KEY (user_id) 
        REFERENCES users(id) ON DELETE SET NULL,
    
    -- الفهارس
    INDEX idx_ttaudit_version (version_id),
    INDEX idx_ttaudit_action (action),
    INDEX idx_ttaudit_date (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='سجل تدقيق جدول الحصص - INSERT ONLY';

-- ═══════════════════════════════════════════════════════════════════════════════
-- القسم 13: Views للتقارير
-- ═══════════════════════════════════════════════════════════════════════════════

-- View الجدول الكامل لإصدار معين
CREATE OR REPLACE VIEW v_timetable_full AS
SELECT 
    tv.id AS version_id,
    tv.version_name,
    lts.name_ar AS version_status,
    gl.name_ar AS grade_name,
    c.name_ar AS classroom_name,
    ld.name_ar AS day_name,
    ld.order_num AS day_order,
    ts.period_number,
    sub.name_ar AS subject_name,
    sub.code AS subject_code,
    e.full_name AS teacher_name,
    lst.name_ar AS slot_type
FROM timetable_slots ts
JOIN timetable_versions tv ON ts.version_id = tv.id
JOIN lookup_timetable_statuses lts ON tv.status_id = lts.id
JOIN lookup_timetable_slot_types lst ON ts.slot_type_id = lst.id
JOIN classrooms c ON ts.classroom_id = c.id
JOIN grade_levels gl ON c.grade_level_id = gl.id
JOIN lookup_days ld ON ts.day_id = ld.id
JOIN subjects sub ON ts.subject_id = sub.id
JOIN employees e ON ts.employee_id = e.id
ORDER BY gl.sort_order, c.name_ar, ld.order_num, ts.period_number;

-- View جدول المعلم
CREATE OR REPLACE VIEW v_teacher_timetable AS
SELECT 
    tv.id AS version_id,
    e.id AS employee_id,
    e.full_name AS teacher_name,
    ld.name_ar AS day_name,
    ld.order_num AS day_order,
    ts.period_number,
    sub.name_ar AS subject_name,
    c.name_ar AS classroom_name,
    gl.name_ar AS grade_name
FROM timetable_slots ts
JOIN timetable_versions tv ON ts.version_id = tv.id
JOIN employees e ON ts.employee_id = e.id
JOIN lookup_days ld ON ts.day_id = ld.id
JOIN subjects sub ON ts.subject_id = sub.id
JOIN classrooms c ON ts.classroom_id = c.id
JOIN grade_levels gl ON c.grade_level_id = gl.id
WHERE tv.is_active = TRUE
ORDER BY e.full_name, ld.order_num, ts.period_number;

-- View ملخص أحمال المعلمين
CREATE OR REPLACE VIEW v_teacher_workload_summary AS
SELECT 
    tw.version_id,
    e.full_name AS teacher_name,
    tw.total_periods,
    tw.workload_score,
    CASE 
        WHEN tw.is_overloaded THEN 'محمّل زيادة'
        WHEN tw.is_underloaded THEN 'محمّل أقل'
        ELSE 'متوازن'
    END AS workload_status,
    tw.recommended_adjustment
FROM teacher_workload tw
JOIN employees e ON tw.employee_id = e.id
ORDER BY tw.workload_score DESC;

-- View التعارضات غير المحلولة
CREATE OR REPLACE VIEW v_unresolved_conflicts AS
SELECT 
    sc.id AS conflict_id,
    tv.version_name,
    sr.run_number AS simulation_number,
    sc.conflict_type,
    sc.severity,
    ld.name_ar AS day_name,
    sc.period_number,
    e.full_name AS teacher_name,
    c.name_ar AS classroom_name,
    sc.description,
    sc.suggested_fix,
    sc.created_at
FROM simulation_conflicts sc
JOIN simulation_runs sr ON sc.simulation_id = sr.id
JOIN timetable_versions tv ON sr.version_id = tv.id
LEFT JOIN lookup_days ld ON sc.day_id = ld.id
LEFT JOIN employees e ON sc.employee_id = e.id
LEFT JOIN classrooms c ON sc.classroom_id = c.id
WHERE sc.is_resolved = FALSE
ORDER BY sc.severity, sc.created_at;

-- View إحصائيات الجدول
CREATE OR REPLACE VIEW v_timetable_statistics AS
SELECT 
    tv.id AS version_id,
    tv.version_name,
    lts.name_ar AS status,
    ay.name_ar AS academic_year,
    sem.name_ar AS semester,
    (SELECT COUNT(*) FROM timetable_slots WHERE version_id = tv.id) AS total_slots,
    (SELECT COUNT(DISTINCT classroom_id) FROM timetable_slots WHERE version_id = tv.id) AS classrooms_count,
    (SELECT COUNT(DISTINCT employee_id) FROM timetable_slots WHERE version_id = tv.id) AS teachers_count,
    (SELECT COUNT(*) FROM simulation_conflicts sc 
     JOIN simulation_runs sr ON sc.simulation_id = sr.id 
     WHERE sr.version_id = tv.id AND sc.is_resolved = FALSE) AS unresolved_conflicts,
    tv.created_at,
    tv.approved_at
FROM timetable_versions tv
JOIN lookup_timetable_statuses lts ON tv.status_id = lts.id
JOIN academic_years ay ON tv.academic_year_id = ay.id
JOIN semesters sem ON tv.semester_id = sem.id;

-- ═══════════════════════════════════════════════════════════════════════════════
-- القسم 14: Stored Procedures
-- ═══════════════════════════════════════════════════════════════════════════════

DELIMITER //

-- إجراء حساب أحمال المعلمين
CREATE PROCEDURE sp_calculate_teacher_workload(IN p_version_id INT)
BEGIN
    -- حذف الحسابات القديمة
    DELETE FROM teacher_workload WHERE version_id = p_version_id;
    
    -- حساب الأحمال الجديدة
    INSERT INTO teacher_workload (version_id, employee_id, total_periods, workload_score, is_overloaded, is_underloaded)
    SELECT 
        p_version_id,
        employee_id,
        COUNT(*) AS total_periods,
        COUNT(*) * 1.0 AS workload_score,
        CASE WHEN COUNT(*) > 25 THEN TRUE ELSE FALSE END AS is_overloaded,
        CASE WHEN COUNT(*) < 15 THEN TRUE ELSE FALSE END AS is_underloaded
    FROM timetable_slots
    WHERE version_id = p_version_id
    GROUP BY employee_id;
    
    -- تحديث عدد الحصص في الإصدار
    UPDATE timetable_versions 
    SET total_slots = (SELECT COUNT(*) FROM timetable_slots WHERE version_id = p_version_id)
    WHERE id = p_version_id;
END//

-- إجراء التحقق من التعارضات
CREATE PROCEDURE sp_check_conflicts(IN p_version_id INT, OUT p_conflict_count INT)
BEGIN
    DECLARE v_simulation_id INT;
    
    -- إنشاء سجل محاكاة جديد
    INSERT INTO simulation_runs (version_id, run_number, simulation_type, status)
    SELECT p_version_id, COALESCE(MAX(run_number), 0) + 1, 'كاملة', 'جارية'
    FROM simulation_runs WHERE version_id = p_version_id;
    
    SET v_simulation_id = LAST_INSERT_ID();
    
    -- التحقق من تعارض المعلم في مكانين
    INSERT INTO simulation_conflicts (simulation_id, conflict_type, severity, day_id, period_number, employee_id, description)
    SELECT 
        v_simulation_id,
        'معلم_مكانين',
        'خطأ',
        ts1.day_id,
        ts1.period_number,
        ts1.employee_id,
        CONCAT('المعلم معين في شعبتين في نفس الوقت')
    FROM timetable_slots ts1
    JOIN timetable_slots ts2 ON ts1.version_id = ts2.version_id 
        AND ts1.employee_id = ts2.employee_id 
        AND ts1.day_id = ts2.day_id 
        AND ts1.period_number = ts2.period_number
        AND ts1.id < ts2.id
    WHERE ts1.version_id = p_version_id;
    
    -- حساب عدد التعارضات
    SELECT COUNT(*) INTO p_conflict_count 
    FROM simulation_conflicts 
    WHERE simulation_id = v_simulation_id;
    
    -- تحديث حالة المحاكاة
    UPDATE simulation_runs 
    SET status = IF(p_conflict_count = 0, 'ناجحة', 'فاشلة'),
        total_conflicts = p_conflict_count,
        completed_at = CURRENT_TIMESTAMP
    WHERE id = v_simulation_id;
    
    -- تحديث عدد التعارضات في الإصدار
    UPDATE timetable_versions 
    SET total_conflicts = p_conflict_count
    WHERE id = p_version_id;
END//

DELIMITER ;

-- ═══════════════════════════════════════════════════════════════════════════════
-- رسالة اكتمال التنفيذ
-- ═══════════════════════════════════════════════════════════════════════════════

SELECT '✅ تم إنشاء جداول نظام جدول الحصص الذكي بنجاح!' AS message;
SELECT CONCAT('📊 عدد الجداول: 15 جدول + 5 Views + 2 Procedures') AS summary;

-- ╔══════════════════════════════════════════════════════════════════════════════╗
-- ║  الملخص:                                                                     ║
-- ║  Lookup: lookup_timetable_statuses, lookup_subject_weights,                  ║
-- ║          lookup_constraint_types (3)                                         ║
-- ║  الإصدارات: timetable_versions (1)                                          ║
-- ║  البيانات: subject_priorities, teacher_availability, timetable_slots (3)    ║
-- ║  المرنة: flexible_slots (1)                                                  ║
-- ║  الذكاء: teacher_workload, scheduling_constraints (2)                        ║
-- ║  المحاكاة: simulation_runs, simulation_conflicts (2)                         ║
-- ║  التصدير: timetable_exports (1)                                              ║
-- ║  التدقيق: timetable_audit_log (1)                                            ║
-- ║  ─────────────────────────────────────────────                               ║
-- ║  المجموع: 15 جدول + 5 Views + 2 Procedures                                   ║
-- ║                                                                               ║
║  إعداد واعتماد: المهندس موسى العواضي                                           ║
╚══════════════════════════════════════════════════════════════════════════════╝
