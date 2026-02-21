-- ╔══════════════════════════════════════════════════════════════════════════════╗
-- ║         نظام جدولة الاختبارات وتوزيع اللجان (ETDS) - v2.0                 ║
-- ║         Exam Timetabling & Distribution System                              ║
-- ║                                                                               ║
-- ║  يشمل: جدولة الاختبارات، جلسات الامتحان، اللجان، الأطر، المقاعد،            ║
-- ║        المراقبين، التوزيع التلقائي، التحقق من التعارضات                       ║
-- ╚══════════════════════════════════════════════════════════════════════════════╝

-- التاريخ: 2026-02-19 (محدّث)
-- الإصدار: 2.0
-- المهندس المسؤول: عمار الشعيبي / موسى العواضي
-- قاعدة البيانات: MySQL 8.0+
-- ملاحظة: يجب تنفيذ DDL_SCHEDULING.sql أولاً (يحتوي lookup_exam_types)

-- ═══════════════════════════════════════════════════════════════════════════════
-- القسم 1: جداول Lookup للجان الامتحانات
-- ═══════════════════════════════════════════════════════════════════════════════

-- جدول مواضع المقعد
CREATE TABLE IF NOT EXISTS lookup_seat_positions (
    id TINYINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name_ar VARCHAR(20) NOT NULL COMMENT 'الموضع بالعربية',
    code VARCHAR(10) NOT NULL UNIQUE COMMENT 'رمز الموضع',
    sort_order TINYINT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='مواضع المقعد في الإطار';

INSERT INTO lookup_seat_positions (name_ar, code, sort_order) VALUES
('يمين', 'RIGHT', 1),
('وسط', 'CENTER', 2),
('شمال', 'LEFT', 3);

-- جدول أسماء الأطر
CREATE TABLE IF NOT EXISTS lookup_frame_names (
    id TINYINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name_ar VARCHAR(30) NOT NULL COMMENT 'اسم الإطار بالعربية',
    code VARCHAR(20) NOT NULL UNIQUE COMMENT 'رمز الإطار',
    sort_order TINYINT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='أسماء الأطر الثابتة';

INSERT INTO lookup_frame_names (name_ar, code, sort_order) VALUES
('جهة الجدار', 'WALL_SIDE', 1),
('الوسط', 'CENTER', 2),
('جهة الباب', 'DOOR_SIDE', 3);

-- جدول سياسات الجنس
CREATE TABLE IF NOT EXISTS lookup_gender_policies (
    id TINYINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name_ar VARCHAR(50) NOT NULL COMMENT 'السياسة بالعربية',
    code VARCHAR(30) NOT NULL UNIQUE COMMENT 'رمز السياسة',
    description TEXT COMMENT 'وصف السياسة',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='سياسات توزيع الجنس في اللجان';

INSERT INTO lookup_gender_policies (name_ar, code, description) VALUES
('فصل كامل', 'COMPLETE_SEPARATION', 'لجان ذكور فقط ولجان إناث فقط'),
('دمج مع أطر منفصلة', 'MIXED_SEPARATE_FRAMES', 'لجان مختلطة مع أطر منفصلة لكل جنس'),
('مختلط حر', 'FULLY_MIXED', 'توزيع حر بدون اعتبار الجنس');

-- جدول طرق الترتيب
CREATE TABLE IF NOT EXISTS lookup_ordering_methods (
    id TINYINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name_ar VARCHAR(50) NOT NULL COMMENT 'الطريقة بالعربية',
    code VARCHAR(30) NOT NULL UNIQUE COMMENT 'رمز الطريقة',
    description TEXT COMMENT 'وصف الطريقة',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='طرق ترتيب الطلاب في اللجان';

INSERT INTO lookup_ordering_methods (name_ar, code, description) VALUES
('أبجدي', 'ALPHABETICAL', 'ترتيب أبجدي حسب الاسم'),
('حسب الصف ثم أبجدي', 'GRADE_THEN_ALPHA', 'ترتيب حسب الصف أولاً ثم أبجدياً'),
('عشوائي', 'RANDOM', 'توزيع عشوائي'),
('متوازن', 'BALANCED', 'توزيع متوازن Round-robin');

-- ═══════════════════════════════════════════════════════════════════════════════
-- القسم 2: جلسات الامتحان
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS exam_sessions (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    
    -- الربط بالسنة والفصل
    academic_year_id INT UNSIGNED NOT NULL COMMENT 'العام الدراسي',
    semester_id INT UNSIGNED NOT NULL COMMENT 'الفصل الدراسي',
    
    -- معلومات الامتحان
    exam_name VARCHAR(100) NOT NULL COMMENT 'اسم الامتحان',
    exam_type_id TINYINT UNSIGNED NOT NULL DEFAULT 3 COMMENT 'FK → lookup_exam_types',
    building_id TINYINT UNSIGNED NULL COMMENT 'المبنى',
    round_number TINYINT UNSIGNED DEFAULT 1 COMMENT 'الدور (1=الأول، 2=الثاني...)',
    
    -- التواريخ
    start_date DATE COMMENT 'تاريخ بداية الامتحان',
    end_date DATE COMMENT 'تاريخ نهاية الامتحان',
    
    -- الحالة
    is_locked BOOLEAN DEFAULT FALSE COMMENT 'مقفل - لا يمكن التعديل',
    locked_at TIMESTAMP NULL COMMENT 'تاريخ القفل',
    locked_by_user_id INT UNSIGNED COMMENT 'قفله',
    
    -- ملاحظات
    notes TEXT COMMENT 'ملاحظات',
    
    -- التدقيق
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NULL ON UPDATE CURRENT_TIMESTAMP,
    created_by_user_id INT UNSIGNED COMMENT 'أنشأه',
    
    -- المفاتيح الخارجية
    CONSTRAINT fk_examsession_year FOREIGN KEY (academic_year_id) 
        REFERENCES academic_years(id) ON DELETE RESTRICT,
    CONSTRAINT fk_examsession_semester FOREIGN KEY (semester_id) 
        REFERENCES semesters(id) ON DELETE RESTRICT,
    CONSTRAINT fk_examsession_examtype FOREIGN KEY (exam_type_id)
        REFERENCES lookup_exam_types(id) ON DELETE RESTRICT,
    CONSTRAINT fk_examsession_creator FOREIGN KEY (created_by_user_id) 
        REFERENCES users(id) ON DELETE SET NULL,
    CONSTRAINT fk_examsession_locker FOREIGN KEY (locked_by_user_id) 
        REFERENCES users(id) ON DELETE SET NULL,
    CONSTRAINT fk_examsession_building FOREIGN KEY (building_id)
        REFERENCES lookup_buildings(id) ON DELETE SET NULL,
    
    -- القيود
    UNIQUE KEY uk_exam_session (academic_year_id, semester_id, exam_type_id, round_number),
    INDEX idx_examsession_dates (start_date, end_date),
    INDEX idx_examsession_type (exam_type_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='جلسات الامتحان — تستخدم lookup_exam_types بدل ENUM';

-- ═══════════════════════════════════════════════════════════════════════════════
-- القسم 3: إعدادات التوزيع
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS exam_distribution_settings (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    
    exam_session_id INT UNSIGNED NOT NULL COMMENT 'جلسة الامتحان',
    
    -- سياسات التوزيع
    gender_policy_id TINYINT UNSIGNED NOT NULL COMMENT 'سياسة الجنس',
    ordering_method_id TINYINT UNSIGNED NOT NULL COMMENT 'طريقة الترتيب',
    
    -- خيارات التوزيع
    mix_grades BOOLEAN DEFAULT TRUE COMMENT 'خلط الصفوف في اللجنة',
    respect_fixed_assignments BOOLEAN DEFAULT TRUE COMMENT 'احترام التثبيتات',
    random_seed INT UNSIGNED COMMENT 'بذرة العشوائية للتكرار',
    
    -- الصفوف المشمولة
    included_grade_levels JSON COMMENT 'قائمة الصفوف المشمولة',
    
    -- ملاحظات
    notes TEXT COMMENT 'ملاحظات',
    
    -- التدقيق
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NULL ON UPDATE CURRENT_TIMESTAMP,
    created_by_user_id INT UNSIGNED COMMENT 'أنشأه',
    
    -- المفاتيح الخارجية
    CONSTRAINT fk_distsettings_session FOREIGN KEY (exam_session_id) 
        REFERENCES exam_sessions(id) ON DELETE CASCADE,
    CONSTRAINT fk_distsettings_genderpolicy FOREIGN KEY (gender_policy_id) 
        REFERENCES lookup_gender_policies(id) ON DELETE RESTRICT,
    CONSTRAINT fk_distsettings_ordering FOREIGN KEY (ordering_method_id) 
        REFERENCES lookup_ordering_methods(id) ON DELETE RESTRICT,
    CONSTRAINT fk_distsettings_creator FOREIGN KEY (created_by_user_id) 
        REFERENCES users(id) ON DELETE SET NULL,
    
    -- القيود
    UNIQUE KEY uk_dist_session (exam_session_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='إعدادات توزيع لجان الامتحان';

-- ═══════════════════════════════════════════════════════════════════════════════
-- القسم 4: اللجان
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS exam_committees (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    
    exam_session_id INT UNSIGNED NOT NULL COMMENT 'جلسة الامتحان',
    
    -- معلومات اللجنة
    committee_number SMALLINT UNSIGNED NOT NULL COMMENT 'رقم اللجنة',
    location VARCHAR(100) COMMENT 'مقر اللجنة',
    classroom_id INT UNSIGNED COMMENT 'الفصل المستضيف',
    
    -- السعات
    total_capacity SMALLINT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'السعة الكلية',
    male_capacity SMALLINT UNSIGNED DEFAULT 0 COMMENT 'سعة الذكور',
    female_capacity SMALLINT UNSIGNED DEFAULT 0 COMMENT 'سعة الإناث',
    
    -- ملاحظات
    notes TEXT COMMENT 'ملاحظات',
    
    -- التدقيق
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- المفاتيح الخارجية
    CONSTRAINT fk_committee_session FOREIGN KEY (exam_session_id) 
        REFERENCES exam_sessions(id) ON DELETE CASCADE,
    CONSTRAINT fk_committee_classroom FOREIGN KEY (classroom_id) 
        REFERENCES classrooms(id) ON DELETE SET NULL,
    
    -- القيود
    UNIQUE KEY uk_committee_number (exam_session_id, committee_number),
    INDEX idx_committee_session (exam_session_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='لجان الامتحان';

-- ═══════════════════════════════════════════════════════════════════════════════
-- القسم 5: الأطر
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS committee_frames (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    
    committee_id INT UNSIGNED NOT NULL COMMENT 'اللجنة',
    
    -- معلومات الإطار
    frame_number TINYINT UNSIGNED NOT NULL COMMENT 'رقم الإطار',
    frame_name_id TINYINT UNSIGNED COMMENT 'اسم الإطار',
    frame_custom_name VARCHAR(50) COMMENT 'اسم مخصص للإطار',
    frame_gender ENUM('ذكور', 'إناث', 'مختلط') NOT NULL DEFAULT 'مختلط' COMMENT 'جنس الإطار',
    
    -- السعة
    capacity SMALLINT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'سعة الإطار',
    
    -- التدقيق
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- المفاتيح الخارجية
    CONSTRAINT fk_frame_committee FOREIGN KEY (committee_id) 
        REFERENCES exam_committees(id) ON DELETE CASCADE,
    CONSTRAINT fk_frame_name FOREIGN KEY (frame_name_id) 
        REFERENCES lookup_frame_names(id) ON DELETE SET NULL,
    
    -- القيود
    UNIQUE KEY uk_frame_number (committee_id, frame_number),
    INDEX idx_frame_committee (committee_id),
    INDEX idx_frame_gender (frame_gender)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='أطر اللجان';

-- ═══════════════════════════════════════════════════════════════════════════════
-- القسم 6: المقاعد
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS exam_seats (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    
    frame_id INT UNSIGNED NOT NULL COMMENT 'الإطار',
    
    -- معلومات المقعد
    seat_number SMALLINT UNSIGNED NOT NULL COMMENT 'رقم المقعد',
    seat_position_id TINYINT UNSIGNED COMMENT 'موضع المقعد',
    
    -- الحالة
    is_available BOOLEAN DEFAULT TRUE COMMENT 'متاح للتوزيع',
    
    -- التدقيق
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- المفاتيح الخارجية
    CONSTRAINT fk_seat_frame FOREIGN KEY (frame_id) 
        REFERENCES committee_frames(id) ON DELETE CASCADE,
    CONSTRAINT fk_seat_position FOREIGN KEY (seat_position_id) 
        REFERENCES lookup_seat_positions(id) ON DELETE SET NULL,
    
    -- القيود
    UNIQUE KEY uk_seat_number (frame_id, seat_number),
    INDEX idx_seat_frame (frame_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='مقاعد الامتحان';

-- ═══════════════════════════════════════════════════════════════════════════════
-- القسم 7: تعيين الطلاب على المقاعد
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS exam_assignments (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    
    -- الربط بالجلسة والطالب
    exam_session_id INT UNSIGNED NOT NULL COMMENT 'جلسة الامتحان',
    enrollment_id INT UNSIGNED NOT NULL COMMENT 'تسجيل الطالب',
    
    -- التعيين
    committee_id INT UNSIGNED NOT NULL COMMENT 'اللجنة',
    frame_id INT UNSIGNED NOT NULL COMMENT 'الإطار',
    seat_id INT UNSIGNED NOT NULL COMMENT 'المقعد',
    
    -- حالة التثبيت
    is_fixed BOOLEAN DEFAULT FALSE COMMENT 'مثبت (استثناء) - لا يتم تغييره عند إعادة التوزيع',
    fixed_reason VARCHAR(200) COMMENT 'سبب التثبيت',
    
    -- ملاحظات
    notes TEXT COMMENT 'ملاحظات',
    
    -- التدقيق
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NULL ON UPDATE CURRENT_TIMESTAMP,
    created_by_user_id INT UNSIGNED COMMENT 'أنشأه',
    
    -- المفاتيح الخارجية
    CONSTRAINT fk_assignment_session FOREIGN KEY (exam_session_id) 
        REFERENCES exam_sessions(id) ON DELETE CASCADE,
    CONSTRAINT fk_assignment_enrollment FOREIGN KEY (enrollment_id) 
        REFERENCES student_enrollments(id) ON DELETE CASCADE,
    CONSTRAINT fk_assignment_committee FOREIGN KEY (committee_id) 
        REFERENCES exam_committees(id) ON DELETE CASCADE,
    CONSTRAINT fk_assignment_frame FOREIGN KEY (frame_id) 
        REFERENCES committee_frames(id) ON DELETE CASCADE,
    CONSTRAINT fk_assignment_seat FOREIGN KEY (seat_id) 
        REFERENCES exam_seats(id) ON DELETE CASCADE,
    CONSTRAINT fk_assignment_creator FOREIGN KEY (created_by_user_id) 
        REFERENCES users(id) ON DELETE SET NULL,
    
    -- القيود
    UNIQUE KEY uk_assignment_student (exam_session_id, enrollment_id),
    UNIQUE KEY uk_assignment_seat (exam_session_id, seat_id),
    INDEX idx_assignment_session (exam_session_id),
    INDEX idx_assignment_committee (committee_id),
    INDEX idx_assignment_fixed (is_fixed)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='تعيين الطلاب على مقاعد الامتحان';

-- ═══════════════════════════════════════════════════════════════════════════════
-- القسم 8: سجل التدقيق لتغييرات التوزيع
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS exam_distribution_audit (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    
    exam_session_id INT UNSIGNED NOT NULL COMMENT 'جلسة الامتحان',
    
    -- معلومات التغيير
    action ENUM('GENERATE', 'REGENERATE', 'LOCK', 'UNLOCK', 'FIX', 'UNFIX', 'MANUAL_CHANGE') 
        NOT NULL COMMENT 'نوع الإجراء',
    affected_count INT UNSIGNED COMMENT 'عدد المتأثرين',
    reason TEXT COMMENT 'سبب التغيير',
    
    -- التدقيق
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    user_id INT UNSIGNED COMMENT 'المستخدم',
    
    -- المفاتيح الخارجية
    CONSTRAINT fk_distaudit_session FOREIGN KEY (exam_session_id) 
        REFERENCES exam_sessions(id) ON DELETE CASCADE,
    CONSTRAINT fk_distaudit_user FOREIGN KEY (user_id) 
        REFERENCES users(id) ON DELETE SET NULL,
    
    -- الفهارس
    INDEX idx_distaudit_session (exam_session_id),
    INDEX idx_distaudit_date (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='سجل تدقيق توزيع لجان الامتحان';

-- ═══════════════════════════════════════════════════════════════════════════════
-- القسم 9: Views للتقارير
-- ═══════════════════════════════════════════════════════════════════════════════

-- View توزيع الطلاب الكامل
CREATE OR REPLACE VIEW v_exam_distribution_full AS
SELECT 
    es.id AS session_id,
    es.exam_name,
    es.exam_type,
    lb.name_ar AS building_name,
    ec.committee_number,
    ec.location AS committee_location,
    cf.frame_number,
    COALESCE(lfn.name_ar, cf.frame_custom_name) AS frame_name,
    cf.frame_gender,
    exs.seat_number,
    COALESCE(lsp.name_ar, '') AS seat_position,
    se.id AS enrollment_id,
    s.full_name AS student_name,
    s.gender AS student_gender,
    gl.name_ar AS grade_name,
    c.name_ar AS classroom_name,
    ea.is_fixed
FROM exam_assignments ea
JOIN exam_sessions es ON ea.exam_session_id = es.id
LEFT JOIN lookup_buildings lb ON es.building_id = lb.id
JOIN exam_committees ec ON ea.committee_id = ec.id
JOIN committee_frames cf ON ea.frame_id = cf.id
LEFT JOIN lookup_frame_names lfn ON cf.frame_name_id = lfn.id
JOIN exam_seats exs ON ea.seat_id = exs.id
LEFT JOIN lookup_seat_positions lsp ON exs.seat_position_id = lsp.id
JOIN student_enrollments se ON ea.enrollment_id = se.id
JOIN students s ON se.student_id = s.id
JOIN classrooms c ON se.classroom_id = c.id
JOIN grade_levels gl ON c.grade_level_id = gl.id
ORDER BY ec.committee_number, cf.frame_number, exs.seat_number;

-- View ملخص اللجنة
CREATE OR REPLACE VIEW v_committee_summary AS
SELECT 
    ec.id AS committee_id,
    es.exam_name,
    ec.committee_number,
    ec.location,
    ec.total_capacity,
    COUNT(ea.id) AS assigned_count,
    SUM(CASE WHEN s.gender = 'ذكر' THEN 1 ELSE 0 END) AS male_count,
    SUM(CASE WHEN s.gender = 'أنثى' THEN 1 ELSE 0 END) AS female_count,
    (ec.total_capacity - COUNT(ea.id)) AS remaining_seats
FROM exam_committees ec
JOIN exam_sessions es ON ec.exam_session_id = es.id
LEFT JOIN exam_assignments ea ON ec.id = ea.committee_id
LEFT JOIN student_enrollments se ON ea.enrollment_id = se.id
LEFT JOIN students s ON se.student_id = s.id
GROUP BY ec.id, es.exam_name, ec.committee_number, ec.location, ec.total_capacity;

-- View ملخص التوزيع حسب الصف
CREATE OR REPLACE VIEW v_distribution_by_grade AS
SELECT 
    es.id AS session_id,
    es.exam_name,
    gl.id AS grade_id,
    gl.name_ar AS grade_name,
    COUNT(ea.id) AS total_students,
    SUM(CASE WHEN s.gender = 'ذكر' THEN 1 ELSE 0 END) AS male_count,
    SUM(CASE WHEN s.gender = 'أنثى' THEN 1 ELSE 0 END) AS female_count
FROM exam_assignments ea
JOIN exam_sessions es ON ea.exam_session_id = es.id
JOIN student_enrollments se ON ea.enrollment_id = se.id
JOIN students s ON se.student_id = s.id
JOIN classrooms c ON se.classroom_id = c.id
JOIN grade_levels gl ON c.grade_level_id = gl.id
GROUP BY es.id, es.exam_name, gl.id, gl.name_ar;

-- ═══════════════════════════════════════════════════════════════════════════════

-- -----------------------------------------------------------------------------
-- 10. (ملحق) Views التقويم التشغيلية (Exams)
-- -----------------------------------------------------------------------------

-- View: تقويم جلسات الامتحانات
CREATE OR REPLACE VIEW v_exam_sessions_calendar AS 
SELECT  
   es.id, es.exam_name, es.exam_type, 
   es.start_date, es.end_date, 
   cm_start.hijri_date AS start_hijri, 
   cm_end.hijri_date AS end_hijri, 
   lb.name_ar AS building_name, 
   es.is_locked 
FROM exam_sessions es 
LEFT JOIN calendar_master cm_start ON es.start_date = cm_start.gregorian_date 
LEFT JOIN calendar_master cm_end ON es.end_date = cm_end.gregorian_date 
LEFT JOIN lookup_buildings lb ON es.building_id = lb.id;

-- ═══════════════════════════════════════════════════════════════════════════════
-- رسالة اكتمال التنفيذ
-- ═══════════════════════════════════════════════════════════════════════════════

SELECT '✅ تم إنشاء جداول نظام جدولة الاختبارات وتوزيع اللجان بنجاح!' AS message;
SELECT CONCAT('📊 DDL.sql: 12 جدول + 4 Views | DDL_SCHEDULING.sql: 8 جداول + 3 Views + 1 SP') AS summary;
SELECT 'ملاحظة: تأكد من تنفيذ DDL_SCHEDULING.sql أولاً (يحتوي lookup_exam_types)' AS note;
