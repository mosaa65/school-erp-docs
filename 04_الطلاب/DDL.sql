-- ╔══════════════════════════════════════════════════════════════════════════════╗
-- ║                     نظام إدارة المدرسة المتكامل                              ║
-- ║                School Management System Database                              ║
-- ║                                                                               ║
-- ║  الجزء 4: نظام الطلاب (Student Information System - SIS)                     ║
-- ║  المسؤول: أحمد الهتار                                                        ║
-- ╚══════════════════════════════════════════════════════════════════════════════╝

-- التاريخ: 2026-01-05
-- الإصدار: 1.0

-- ═══════════════════════════════════════════════════════════════════════════════
-- ═══════════════════════════════════════════════════════════════════════════════
-- نظام الطلاب - 14 جدول (تم تحديثه لإضافة الجداول المرجعية الداخلية)
-- ═══════════════════════════════════════════════════════════════════════════════

-- -----------------------------------------------------------------------------
-- 0.1 جدول حالات القيد (جديد - داخلي)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS lookup_enrollment_statuses (
    id TINYINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name_ar VARCHAR(50) NOT NULL,
    is_active BOOLEAN DEFAULT TRUE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO lookup_enrollment_statuses (name_ar) VALUES
('مستجد'), ('منقول'), ('ناجح'), ('راسب'), ('معيد'), ('مفصول'), ('منقطع');

-- -----------------------------------------------------------------------------
-- 0.2 جدول حالات اليتيم (جديد - داخلي)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS lookup_orphan_statuses (
    id TINYINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name_ar VARCHAR(50) NOT NULL,
    is_active BOOLEAN DEFAULT TRUE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO lookup_orphan_statuses (name_ar) VALUES
('غير يتيم'), ('يتيم الأب'), ('يتيم الأم'), ('يتيم الأبوين (لطيم)');

-- -----------------------------------------------------------------------------
-- 0.3 جدول مستويات القدرة (جديد - داخلي)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS lookup_ability_levels (
    id TINYINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name_ar VARCHAR(50) NOT NULL,
    is_active BOOLEAN DEFAULT TRUE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO lookup_ability_levels (name_ar) VALUES
('ممتاز'), ('جيد جداً'), ('جيد'), ('متوسط'), ('ضعيف');

-- -----------------------------------------------------------------------------
-- 0.4 جدول أنواع النشاط (جديد - داخلي)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS lookup_activity_types (
    id TINYINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name_ar VARCHAR(50) NOT NULL,
    is_active BOOLEAN DEFAULT TRUE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO lookup_activity_types (name_ar) VALUES
('علمي'), ('ثقافي'), ('رياضي'), ('اجتماعي'), ('كشفي');

-- -----------------------------------------------------------------------------
-- 1. جدول الطلاب
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS students (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    
    -- البيانات الأساسية
    full_name VARCHAR(150) NOT NULL,
    gender_id TINYINT UNSIGNED NOT NULL,
    birth_date DATE NULL,
    
    -- الحالة الصحية
    health_status_id TINYINT UNSIGNED NULL,
    illness_details TEXT NULL,
    
    -- بيانات التسجيل
    enrollment_type_id TINYINT UNSIGNED NULL COMMENT 'يرتبط بـ lookup_enrollment_types (جديد/قديم)',
    previous_school VARCHAR(100) NULL,
    
    -- المذاكرة
    tutor_name VARCHAR(100) NULL COMMENT 'من يذاكر له',
    tutor_relation_id TINYINT UNSIGNED NULL,
    
    -- المقعد والطابور
    seat_row TINYINT UNSIGNED NULL,
    seat_number TINYINT UNSIGNED NULL,
    queue_row TINYINT UNSIGNED NULL,
    queue_number TINYINT UNSIGNED NULL,
    
    -- بيانات إضافية
    uniform_status_id TINYINT UNSIGNED NULL COMMENT 'يرتبط بـ lookup_ability_levels',
    orphan_status_id TINYINT UNSIGNED NULL COMMENT 'يرتبط بـ lookup_orphan_statuses',
    activity_type_id TINYINT UNSIGNED NULL COMMENT 'يرتبط بـ lookup_activity_types',
    reading_ability_id TINYINT UNSIGNED NULL COMMENT 'يرتبط بـ lookup_ability_levels',
    writing_ability_id TINYINT UNSIGNED NULL COMMENT 'يرتبط بـ lookup_ability_levels',
    
    -- الموقع
    locality_id MEDIUMINT UNSIGNED NULL,
    
    -- الحالة
    is_active BOOLEAN DEFAULT TRUE,
    
    -- التدقيق
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NULL ON UPDATE CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL,
    created_by_user_id INT UNSIGNED NULL,
    
    -- القيود
    CHECK (seat_row IS NULL OR seat_row BETWEEN 1 AND 5),
    CHECK (seat_number IS NULL OR seat_number BETWEEN 1 AND 30),
    
    -- الفهارس
    INDEX idx_name (full_name),
    INDEX idx_gender (gender_id),
    
    -- المفاتيح الخارجية
    FOREIGN KEY (gender_id) REFERENCES lookup_genders(id),
    FOREIGN KEY (health_status_id) REFERENCES lookup_health_statuses(id),
    FOREIGN KEY (orphan_status_id) REFERENCES lookup_orphan_statuses(id),
    FOREIGN KEY (uniform_status_id) REFERENCES lookup_ability_levels(id),
    FOREIGN KEY (activity_type_id) REFERENCES lookup_activity_types(id),
    FOREIGN KEY (reading_ability_id) REFERENCES lookup_ability_levels(id),
    FOREIGN KEY (writing_ability_id) REFERENCES lookup_ability_levels(id),
    FOREIGN KEY (tutor_relation_id) REFERENCES lookup_relationship_types(id),
    FOREIGN KEY (locality_id) REFERENCES localities(id),
    FOREIGN KEY (created_by_user_id) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='بيانات الطلاب';

-- -----------------------------------------------------------------------------
-- 2. جدول أولياء الأمور
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS guardians (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    full_name VARCHAR(150) NOT NULL,
    gender_id TINYINT UNSIGNED NOT NULL,
    id_type_id TINYINT UNSIGNED NULL,
    id_number VARCHAR(30) NULL,
    phone_primary VARCHAR(20) NULL,
    phone_secondary VARCHAR(20) NULL,
    whatsapp_number VARCHAR(20) NULL,
    residence_text VARCHAR(255) NULL,
    locality_id MEDIUMINT UNSIGNED NULL,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NULL ON UPDATE CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL,
    created_by_user_id INT UNSIGNED NULL,
    updated_by_user_id INT UNSIGNED NULL,
    
    INDEX idx_name (full_name),
    FOREIGN KEY (gender_id) REFERENCES lookup_genders(id),
    FOREIGN KEY (id_type_id) REFERENCES lookup_id_types(id),
    FOREIGN KEY (locality_id) REFERENCES localities(id),
    FOREIGN KEY (created_by_user_id) REFERENCES users(id),
    FOREIGN KEY (updated_by_user_id) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='أولياء الأمور';

-- -----------------------------------------------------------------------------
-- 3. جدول علاقة الطلاب بأولياء الأمور
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS student_guardians (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    student_id INT UNSIGNED NOT NULL,
    guardian_id INT UNSIGNED NOT NULL,
    relationship_id TINYINT UNSIGNED NOT NULL,
    is_primary BOOLEAN DEFAULT FALSE COMMENT 'ولي الأمر الأساسي',
    can_receive_notifications BOOLEAN DEFAULT TRUE,
    can_pickup BOOLEAN DEFAULT TRUE COMMENT 'مخول بالاستلام',
    start_date DATE NULL,
    end_date DATE NULL,
    notes TEXT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by_user_id INT UNSIGNED NULL,
    
    UNIQUE KEY uk_relation (student_id, guardian_id, relationship_id, start_date),
    FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE,
    FOREIGN KEY (guardian_id) REFERENCES guardians(id) ON DELETE CASCADE,
    FOREIGN KEY (relationship_id) REFERENCES lookup_relationship_types(id),
    FOREIGN KEY (created_by_user_id) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='ربط الطلاب بأولياء الأمور';

-- -----------------------------------------------------------------------------
-- 4. جدول التسجيل الأكاديمي
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS student_enrollments (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    student_id INT UNSIGNED NOT NULL,
    academic_year_id INT UNSIGNED NOT NULL,
    classroom_id INT UNSIGNED NOT NULL,
    enrollment_date DATE NULL,
    enrollment_status_id TINYINT UNSIGNED NOT NULL,
    notes TEXT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NULL ON UPDATE CURRENT_TIMESTAMP,
    created_by_user_id INT UNSIGNED NULL,
    
    UNIQUE KEY uk_enrollment (student_id, academic_year_id),
    INDEX idx_classroom (classroom_id),
    INDEX idx_year (academic_year_id),
    FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE,
    FOREIGN KEY (academic_year_id) REFERENCES academic_years(id),
    FOREIGN KEY (classroom_id) REFERENCES classrooms(id),
    FOREIGN KEY (enrollment_status_id) REFERENCES lookup_enrollment_statuses(id),
    FOREIGN KEY (created_by_user_id) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='التسجيل الأكاديمي للطلاب';

-- -----------------------------------------------------------------------------
-- 5. جدول مواهب الطلاب
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS student_talents (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    student_id INT UNSIGNED NOT NULL,
    talent_id TINYINT UNSIGNED NOT NULL,
    notes TEXT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE KEY uk_talent (student_id, talent_id),
    FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE,
    FOREIGN KEY (talent_id) REFERENCES lookup_talents(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='مواهب الطلاب';

-- -----------------------------------------------------------------------------
-- 6. جدول الإخوة في المدرسة
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS student_siblings (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    student_id INT UNSIGNED NOT NULL,
    sibling_id INT UNSIGNED NOT NULL,
    relationship ENUM('أخ', 'أخت') NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE KEY uk_sibling (student_id, sibling_id),
    CHECK (student_id != sibling_id),
    FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE,
    FOREIGN KEY (sibling_id) REFERENCES students(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='الإخوة في المدرسة';

-- -----------------------------------------------------------------------------
-- 7. جدول كتب الطلاب
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS student_books (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    enrollment_id INT UNSIGNED NOT NULL,
    subject_id INT UNSIGNED NOT NULL,
    semester_id INT UNSIGNED NOT NULL,
    book_part_id TINYINT UNSIGNED NULL COMMENT '1:ج1، 2:ج2، 3:جزئين',
    ownership_type_id TINYINT UNSIGNED NULL COMMENT '1:ملك، 2:مدرسة',
    issued_date DATE NULL,
    is_returned BOOLEAN DEFAULT FALSE,
    return_date DATE NULL,
    notes TEXT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NULL ON UPDATE CURRENT_TIMESTAMP,
    
    UNIQUE KEY uk_book (enrollment_id, subject_id, semester_id),
    FOREIGN KEY (enrollment_id) REFERENCES student_enrollments(id) ON DELETE CASCADE,
    FOREIGN KEY (subject_id) REFERENCES subjects(id),
    FOREIGN KEY (semester_id) REFERENCES semesters(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='كتب الطلاب';

-- -----------------------------------------------------------------------------
-- 8. جدول حضور الطلاب
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS student_attendance (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    enrollment_id INT UNSIGNED NOT NULL,
    attendance_date DATE NOT NULL,
    status_id TINYINT UNSIGNED NOT NULL,
    has_permission BOOLEAN DEFAULT FALSE COMMENT 'بإذن',
    has_excuse BOOLEAN DEFAULT FALSE COMMENT 'بعذر',
    is_disruptive BOOLEAN DEFAULT FALSE COMMENT 'مزعج',
    is_polite BOOLEAN DEFAULT FALSE COMMENT 'مؤدب',
    late_minutes SMALLINT UNSIGNED NULL COMMENT 'مدة التأخر بالدقائق',
    notes TEXT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by_user_id INT UNSIGNED NULL,
    
    UNIQUE KEY uk_attendance (enrollment_id, attendance_date),
    INDEX idx_date (attendance_date),
    INDEX idx_status (status_id),
    FOREIGN KEY (enrollment_id) REFERENCES student_enrollments(id) ON DELETE CASCADE,
    FOREIGN KEY (status_id) REFERENCES lookup_attendance_statuses(id),
    FOREIGN KEY (created_by_user_id) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='حضور وغياب الطلاب';

-- -----------------------------------------------------------------------------
-- 9. جدول مشكلات الطلاب
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS student_problems (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    student_id INT UNSIGNED NOT NULL,
    problem_date DATE NOT NULL,
    problem_type VARCHAR(50) NULL,
    problem_description TEXT NOT NULL,
    actions_taken TEXT NULL,
    has_minutes BOOLEAN DEFAULT FALSE COMMENT 'حرر محضر',
    is_resolved BOOLEAN DEFAULT FALSE,
    created_by_user_id INT UNSIGNED NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    INDEX idx_student (student_id),
    INDEX idx_date (problem_date),
    FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE,
    FOREIGN KEY (created_by_user_id) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='مشكلات الطلاب';

-- -----------------------------------------------------------------------------
-- 10. جدول إشعارات أولياء الأمور
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS parent_notifications (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    notification_number INT UNSIGNED NOT NULL COMMENT 'رقم تسلسلي',
    student_id INT UNSIGNED NOT NULL,
    notification_type_id TINYINT UNSIGNED NOT NULL COMMENT '1: إيجابي، 2: سلبي',
    guardian_title_id TINYINT UNSIGNED NULL COMMENT 'يرتبط بـ lookup_relationship_types',
    behavior_type VARCHAR(100) NULL COMMENT 'نوع السلوك',
    behavior_description TEXT NULL,
    required_action TEXT NULL COMMENT 'المطلوب من ولي الأمر',
    send_method ENUM('ورقي', 'واتس', 'هاتف', 'أخرى') DEFAULT 'ورقي',
    messenger_name VARCHAR(100) NULL COMMENT 'اسم الرسول',
    is_sent BOOLEAN DEFAULT FALSE,
    sent_date DATE NULL,
    results TEXT NULL COMMENT 'نتائج الإشعار',
    created_by_user_id INT UNSIGNED NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    INDEX idx_student (student_id),
    INDEX idx_type (notification_type_id),
    FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE,
    FOREIGN KEY (created_by_user_id) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='إشعارات أولياء الأمور';

-- ═══════════════════════════════════════════════════════════════════════════════
-- نهاية الجزء 4: نظام الطلاب
-- ═══════════════════════════════════════════════════════════════════════════════

-- ╔══════════════════════════════════════════════════════════════════════════════╗
-- ║  الملخص:                                                                     ║
-- ║  - students: بيانات الطلاب                                                   ║
-- ║  - guardians: أولياء الأمور                                                  ║
-- ║  - student_guardians: الربط                                                  ║
-- ║  - student_enrollments: التسجيل                                              ║
-- ║  - student_talents: المواهب                                                  ║
-- ║  - student_siblings: الإخوة                                                  ║
-- ║  - student_books: الكتب                                                      ║
-- ║  - student_attendance: الحضور                                                ║
-- ║  - student_problems: المشكلات                                                ║
-- ║  - parent_notifications: الإشعارات                                           ║
-- ║  ─────────────────────────────────────────────                               ║
-- ║  المجموع: 10 جداول                                                           ║
-- ╚══════════════════════════════════════════════════════════════════════════════╝

-- -----------------------------------------------------------------------------
-- 11. (ملحق) Views التقويم التشغيلية (SIS)
-- -----------------------------------------------------------------------------

-- View: تقويم حضور الطلاب الشامل
CREATE OR REPLACE VIEW v_student_attendance_calendar AS 
SELECT  
   sa.id, sa.enrollment_id, s.full_name AS student_name, 
   c.name_ar AS classroom_name, gl.name_ar AS grade_level_name, 
   sa.attendance_date, 
   cm.hijri_date, cm.hijri_day, cm.hijri_month, cm.hijri_year, 
   cm.hijri_month_name, cm.day_name_ar, 
   cm.is_school_day, cm.is_holiday, cm.holiday_name, cm.academic_week, 
   las.name_ar AS status_name, las.code AS status_code, las.color_code, 
   sa.has_permission, sa.has_excuse, sa.is_disruptive, sa.is_polite, 
   sa.late_minutes, sa.notes 
FROM student_attendance sa 
LEFT JOIN calendar_master cm ON sa.attendance_date = cm.gregorian_date 
LEFT JOIN lookup_attendance_statuses las ON sa.status_id = las.id 
LEFT JOIN student_enrollments se ON sa.enrollment_id = se.id 
LEFT JOIN students s ON se.student_id = s.id 
LEFT JOIN classrooms c ON se.classroom_id = c.id 
LEFT JOIN grade_levels gl ON c.grade_level_id = gl.id;
