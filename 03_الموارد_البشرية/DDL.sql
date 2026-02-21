-- ╔══════════════════════════════════════════════════════════════════════════════╗
-- ║                     نظام إدارة المدرسة المتكامل                              ║
-- ║                School Management System Database                              ║
-- ║                                                                               ║
-- ║  الجزء 3: نظام الموارد البشرية (Human Resources)                             ║
-- ║  المسؤول: يونس العفيف                                                        ║
-- ╚══════════════════════════════════════════════════════════════════════════════╝

-- التاريخ: 2026-01-05
-- الإصدار: 1.0

-- ═══════════════════════════════════════════════════════════════════════════════
-- نظام الموارد البشرية - 10 جداول (ترقية معمارية)
-- ═══════════════════════════════════════════════════════════════════════════════

-- -----------------------------------------------------------------------------
-- 0. جداول مرجعية إضافية (خاصة بالموارد البشرية)
-- -----------------------------------------------------------------------------

-- ⚠️ lookup_id_types: مُعرّف في System 01 (البنية المشتركة) — لا تُعاد تعريفه هنا

-- جدول الحالات الوظيفية
CREATE TABLE IF NOT EXISTS lookup_employment_statuses (
    id TINYINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name_ar VARCHAR(50) NOT NULL,
    is_active BOOLEAN DEFAULT TRUE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='الحالات الوظيفية';

INSERT INTO lookup_employment_statuses (name_ar) VALUES ('ثابت'), ('متطوع'), ('متعاقد');

-- ⚠️ lookup_genders: مُعرّف في System 01 (البنية المشتركة) — لا تُعاد تعريفه هنا

-- جدول مستويات التقييم
CREATE TABLE IF NOT EXISTS lookup_rating_levels (
    id TINYINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name_ar VARCHAR(50) NOT NULL,
    score_from TINYINT UNSIGNED NOT NULL,
    score_to TINYINT UNSIGNED NOT NULL,
    is_active BOOLEAN DEFAULT TRUE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='مستويات تقييم الأداء';

INSERT INTO lookup_rating_levels (name_ar, score_from, score_to) VALUES 
('ممتاز', 90, 100),
('جيد جداً', 80, 89),
('جيد', 70, 79),
('مقبول', 50, 69),
('ضعيف', 0, 49);

-- -----------------------------------------------------------------------------
-- 1. جدول الموظفين
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS employees (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    
    -- البيانات الأساسية
    job_number VARCHAR(20) NULL UNIQUE COMMENT 'الرقم الوظيفي',
    financial_number VARCHAR(20) NULL UNIQUE COMMENT 'الرقم المالي',
    full_name VARCHAR(150) NOT NULL,
    gender_id TINYINT UNSIGNED NOT NULL,
    birth_year YEAR NULL,
    
    -- التواصل
    phone_primary VARCHAR(20) NULL,
    phone_secondary VARCHAR(20) NULL,
    has_whatsapp BOOLEAN DEFAULT TRUE,
    
    -- المؤهلات
    qualification_id TINYINT UNSIGNED NULL,
    qualification_date DATE NULL,
    specialization VARCHAR(100) NULL COMMENT 'التخصص',
    
    -- الهوية
    id_type_id TINYINT UNSIGNED NULL,
    id_number VARCHAR(30) NULL,
    id_expiry_date DATE NULL,
    
    -- الخبرة والوظيفة
    experience_years TINYINT UNSIGNED DEFAULT 0,
    employment_status_id TINYINT UNSIGNED NULL,
    period_id TINYINT UNSIGNED NULL,
    job_role_id TINYINT UNSIGNED NULL,
    
    -- الحالة الشخصية
    marital_status_id TINYINT UNSIGNED NULL,
    health_status_id TINYINT UNSIGNED NULL,
    health_details TEXT NULL,
    children_male TINYINT UNSIGNED DEFAULT 0,
    children_female TINYINT UNSIGNED DEFAULT 0,
    is_orphan BOOLEAN DEFAULT FALSE,
    
    -- الموقع
    locality_id MEDIUMINT UNSIGNED NULL,
    school_id INT UNSIGNED NULL COMMENT 'المدرسة الحالية (لدعم تعدد المدارس)',
    
    -- بيانات المدرسة
    school_start_date DATE NULL COMMENT 'تاريخ بدء العمل بالمدرسة',
    previous_school VARCHAR(100) NULL,
    salary_approved BOOLEAN DEFAULT FALSE COMMENT 'نزل اعتماده',
    
    -- الحالة
    system_access_status TINYINT UNSIGNED DEFAULT 1 COMMENT '1: ممنوحة، 2: موقوفة',
    is_active BOOLEAN DEFAULT TRUE,
    
    -- التدقيق
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NULL ON UPDATE CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL COMMENT 'Soft Delete',
    created_by_user_id INT UNSIGNED NULL,
    updated_by_user_id INT UNSIGNED NULL,
    
    -- الفهارس
    INDEX idx_name (full_name),
    INDEX idx_job_role (job_role_id),
    INDEX idx_active (is_active),
    INDEX idx_school (school_id),
    
    -- المفاتيح الخارجية
    FOREIGN KEY (gender_id) REFERENCES lookup_genders(id),
    FOREIGN KEY (qualification_id) REFERENCES lookup_qualifications(id),
    FOREIGN KEY (id_type_id) REFERENCES lookup_id_types(id),
    FOREIGN KEY (employment_status_id) REFERENCES lookup_employment_statuses(id),
    FOREIGN KEY (period_id) REFERENCES lookup_periods(id),
    FOREIGN KEY (job_role_id) REFERENCES lookup_job_roles(id),
    FOREIGN KEY (marital_status_id) REFERENCES lookup_marital_statuses(id),
    FOREIGN KEY (health_status_id) REFERENCES lookup_health_statuses(id),
    FOREIGN KEY (locality_id) REFERENCES localities(id),
    FOREIGN KEY (school_id) REFERENCES schools(id),
    FOREIGN KEY (created_by_user_id) REFERENCES users(id),
    FOREIGN KEY (updated_by_user_id) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='بيانات الموظفين - يكتبها المدير فقط';

-- -----------------------------------------------------------------------------
-- 2. جدول مهام الموظف الإضافية
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS employee_tasks (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    employee_id INT UNSIGNED NOT NULL,
    academic_year_id INT UNSIGNED NULL COMMENT 'العام الدراسي للمهمة',
    task_name VARCHAR(100) NOT NULL COMMENT 'العمل الإضافي',
    day_of_week TINYINT UNSIGNED NULL COMMENT '1-7',
    assignment_date DATE NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NULL ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX idx_employee (employee_id),
    INDEX idx_academic_year (academic_year_id),
    FOREIGN KEY (employee_id) REFERENCES employees(id) ON DELETE CASCADE,
    FOREIGN KEY (academic_year_id) REFERENCES academic_years(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='المهام الإضافية للموظف';

-- -----------------------------------------------------------------------------
-- 3. جدول تعيينات التدريس
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS employee_teaching_assignments (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    employee_id INT UNSIGNED NOT NULL,
    classroom_id INT UNSIGNED NOT NULL,
    subject_id INT UNSIGNED NOT NULL,
    academic_year_id INT UNSIGNED NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by_user_id INT UNSIGNED NULL,
    
    UNIQUE KEY uk_assignment (classroom_id, subject_id, academic_year_id),
    INDEX idx_employee (employee_id),
    FOREIGN KEY (employee_id) REFERENCES employees(id) ON DELETE CASCADE,
    FOREIGN KEY (classroom_id) REFERENCES classrooms(id) ON DELETE CASCADE,
    FOREIGN KEY (subject_id) REFERENCES subjects(id) ON DELETE CASCADE,
    FOREIGN KEY (academic_year_id) REFERENCES academic_years(id) ON DELETE CASCADE,
    FOREIGN KEY (created_by_user_id) REFERENCES users(id),
    
    -- التدقيق
    updated_at TIMESTAMP NULL ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='تعيينات التدريس - معلم واحد لكل مادة في الفصل';

-- -----------------------------------------------------------------------------
-- 4. جدول مواهب الموظف
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS employee_talents (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    employee_id INT UNSIGNED NOT NULL,
    talent_id TINYINT UNSIGNED NOT NULL,
    notes TEXT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE KEY uk_talent (employee_id, talent_id),
    FOREIGN KEY (employee_id) REFERENCES employees(id) ON DELETE CASCADE,
    FOREIGN KEY (talent_id) REFERENCES lookup_talents(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='مواهب الموظفين';

-- -----------------------------------------------------------------------------
-- 5. جدول دورات الموظف
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS employee_courses (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    employee_id INT UNSIGNED NOT NULL,
    course_name VARCHAR(150) NOT NULL,
    course_provider VARCHAR(100) NULL COMMENT 'الجهة المنفذة',
    course_date DATE NULL,
    duration_days TINYINT UNSIGNED NULL,
    certificate_number VARCHAR(50) NULL,
    notes TEXT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    INDEX idx_employee (employee_id),
    FOREIGN KEY (employee_id) REFERENCES employees(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='الدورات التدريبية للموظفين';

-- -----------------------------------------------------------------------------
-- 6. جدول مخالفات الموظف
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS employee_violations (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    employee_id INT UNSIGNED NOT NULL,
    violation_date DATE NOT NULL,
    violation_aspect VARCHAR(100) NOT NULL COMMENT 'جانب المخالفة',
    violation_text TEXT NOT NULL COMMENT 'نص المخالفة',
    action_taken TEXT NULL COMMENT 'الإجراء المتخذ',
    has_warning BOOLEAN DEFAULT FALSE,
    has_minutes BOOLEAN DEFAULT FALSE COMMENT 'حرر محضر',
    reported_by_employee_id INT UNSIGNED NULL COMMENT 'الموظف الذي بلغ عن المخالفة',
    created_by_user_id INT UNSIGNED NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NULL ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX idx_employee (employee_id),
    INDEX idx_date (violation_date),
    FOREIGN KEY (employee_id) REFERENCES employees(id) ON DELETE CASCADE,
    FOREIGN KEY (reported_by_employee_id) REFERENCES employees(id) ON DELETE SET NULL,
    FOREIGN KEY (created_by_user_id) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='مخالفات الموظفين';

-- -----------------------------------------------------------------------------
-- 7. جدول حضور الموظفين
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS employee_attendance (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    employee_id INT UNSIGNED NOT NULL,
    attendance_date DATE NOT NULL,
    status_id TINYINT UNSIGNED NOT NULL,
    notes TEXT NULL,
    created_by_user_id INT UNSIGNED NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NULL ON UPDATE CURRENT_TIMESTAMP,
    
    UNIQUE KEY uk_attendance (employee_id, attendance_date),
    INDEX idx_date (attendance_date),
    FOREIGN KEY (employee_id) REFERENCES employees(id) ON DELETE CASCADE,
    FOREIGN KEY (status_id) REFERENCES lookup_attendance_statuses(id),
    FOREIGN KEY (created_by_user_id) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='حضور وغياب الموظفين - يكتبها المدير';

-- -----------------------------------------------------------------------------
-- 8. جدول تقييم الأداء (جديد)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS employee_performance_evaluations (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    employee_id INT UNSIGNED NOT NULL,
    academic_year_id INT UNSIGNED NOT NULL,
    evaluation_date DATE NOT NULL,
    score TINYINT UNSIGNED NOT NULL COMMENT 'الدرجة من 100',
    rating_level_id TINYINT UNSIGNED NOT NULL,
    evaluator_id INT UNSIGNED NULL COMMENT 'الموظف المقيم (المدير)',
    strengths TEXT NULL COMMENT 'نقاط القوة',
    weaknesses TEXT NULL COMMENT 'نقاط الضعف',
    recommendations TEXT NULL COMMENT 'التوصيات',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NULL ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (employee_id) REFERENCES employees(id) ON DELETE CASCADE,
    FOREIGN KEY (academic_year_id) REFERENCES academic_years(id) ON DELETE CASCADE,
    FOREIGN KEY (rating_level_id) REFERENCES lookup_rating_levels(id),
    FOREIGN KEY (evaluator_id) REFERENCES employees(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='تقييم أداء الموظفين السنوي/الدوري';

-- ═══════════════════════════════════════════════════════════════════════════════
-- ربط الموظف بجدول المستخدمين
-- ═══════════════════════════════════════════════════════════════════════════════

ALTER TABLE users 
ADD CONSTRAINT fk_user_employee 
FOREIGN KEY (employee_id) REFERENCES employees(id) ON DELETE SET NULL;

-- ربط مشرف الفصل
ALTER TABLE classrooms 
ADD CONSTRAINT fk_classroom_supervisor 
FOREIGN KEY (supervisor_id) REFERENCES employees(id) ON DELETE SET NULL;

-- ═══════════════════════════════════════════════════════════════════════════════
-- نهاية الجزء 3: نظام الموارد البشرية
-- ═══════════════════════════════════════════════════════════════════════════════

-- ╔══════════════════════════════════════════════════════════════════════════════╗
-- ║  الملخص:                                                                     ║
-- ║  - employees: بيانات الموظفين (41+ حقل)                                      ║
-- ║  - employee_tasks: المهام الإضافية                                           ║
-- ║  - employee_teaching_assignments: تعيينات التدريس                            ║
-- ║  - employee_talents: المواهب                                                 ║
-- ║  - employee_courses: الدورات                                                 ║
-- ║  - employee_violations: المخالفات                                            ║
-- ║  - employee_attendance: الحضور والغياب                                       ║
-- ║  - employee_performance_evaluations: تقييم الأداء (جديد)                     ║
-- ║  ─────────────────────────────────────────────                               ║
-- ║  المجموع: 8 جداول                                                            ║
-- ╚══════════════════════════════════════════════════════════════════════════════╝

-- -----------------------------------------------------------------------------
-- 9. (ملحق) Views التقويم التشغيلية (HR)
-- -----------------------------------------------------------------------------

-- View: تقويم حضور الموظفين الشامل
CREATE OR REPLACE VIEW v_employee_attendance_calendar AS 
SELECT  
   ea.id, ea.employee_id, e.full_name AS employee_name, 
   e.job_number, ljr.name_ar AS job_role, 
   ea.attendance_date, 
   cm.hijri_date, cm.hijri_month_name, cm.day_name_ar, 
   cm.is_school_day, cm.is_holiday, cm.holiday_name, 
   las.name_ar AS status_name, las.code AS status_code 
FROM employee_attendance ea 
LEFT JOIN calendar_master cm ON ea.attendance_date = cm.gregorian_date 
LEFT JOIN lookup_attendance_statuses las ON ea.status_id = las.id 
LEFT JOIN employees e ON ea.employee_id = e.id 
LEFT JOIN lookup_job_roles ljr ON e.job_role_id = ljr.id;
