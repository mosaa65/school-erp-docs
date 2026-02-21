-- ╔══════════════════════════════════════════════════════════════════════════════╗
-- ║           نظام الدرجات والتقويم الذكي (SGAS) - v4.0                        ║
-- ║           ملف 1: سياسات الدرجات + تعيين المعلمين (Policies & Assignments) ║
-- ╚══════════════════════════════════════════════════════════════════════════════╝

-- التاريخ: 2026-02-19
-- الإصدار: 4.0 (FK بدل ENUM + is_default + teacher_assignments)

-- ═══════════════════════════════════════════════════════════════════════════════
-- 1. جدول حالات اعتماد الدرجات
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS lookup_grading_statuses (
    id TINYINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name_ar VARCHAR(50) NOT NULL,
    is_final BOOLEAN DEFAULT FALSE COMMENT 'هل الحالة نهائية؟',
    is_active BOOLEAN DEFAULT TRUE,
    UNIQUE KEY uk_lgs_name (name_ar)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='حالات اعتماد الدرجات (مسودة/مراجعة/معتمد/أرشيف)';

INSERT INTO lookup_grading_statuses (name_ar, is_final, is_active) VALUES
('مسودة', 0, 1),
('قيد المراجعة', 0, 1),
('معتمد', 1, 1),
('مرحل للأرشيف', 1, 1)
ON DUPLICATE KEY UPDATE
    is_final = VALUES(is_final),
    is_active = VALUES(is_active);

-- ═══════════════════════════════════════════════════════════════════════════════
-- 2. سياسات الدرجات والأوزان (لكل عام/صف/مادة/نوع تقييم)
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS grading_policies (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    academic_year_id INT UNSIGNED NOT NULL,
    grade_level_id INT UNSIGNED NOT NULL,
    subject_id INT UNSIGNED NOT NULL,

    -- نوع التقييم (FK بدل ENUM)
    exam_type_id TINYINT UNSIGNED NOT NULL DEFAULT 1 COMMENT 'FK → lookup_exam_types (System 08)',

    -- الأوزان الافتراضية
    max_exam_score DECIMAL(5,2) DEFAULT 20.00 COMMENT 'الدرجة العظمى للاختبارات',
    max_homework_score DECIMAL(5,2) DEFAULT 5.00 COMMENT 'الدرجة العظمى للواجبات',
    max_attendance_score DECIMAL(5,2) DEFAULT 5.00 COMMENT 'الدرجة العظمى للمواظبة',
    max_activity_score DECIMAL(5,2) DEFAULT 5.00 COMMENT 'الدرجة العظمى للنشاط',
    max_contribution_score DECIMAL(5,2) DEFAULT 0.00 COMMENT 'الدرجة العظمى للمساهمة/المهارات السلوكية',

    -- حدود النجاح
    passing_score DECIMAL(5,2) DEFAULT 50.00 COMMENT 'درجة النجاح المئوية',

    -- هل هذه سياسة افتراضية (قالب) يمكن نسخها للعام الجديد؟
    is_default BOOLEAN DEFAULT FALSE COMMENT 'سياسة افتراضية قابلة للنسخ (§2.3)',

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NULL ON UPDATE CURRENT_TIMESTAMP,
    created_by_user_id INT UNSIGNED NULL,

    CHECK (max_exam_score >= 0),
    CHECK (max_homework_score >= 0),
    CHECK (max_attendance_score >= 0),
    CHECK (max_activity_score >= 0),
    CHECK (max_contribution_score >= 0),
    CHECK (passing_score BETWEEN 0 AND 100),

    UNIQUE KEY uk_policy (academic_year_id, grade_level_id, subject_id, exam_type_id),
    INDEX idx_gp_type (exam_type_id),
    INDEX idx_gp_default (is_default),

    FOREIGN KEY (academic_year_id) REFERENCES academic_years(id),
    FOREIGN KEY (grade_level_id) REFERENCES grade_levels(id),
    FOREIGN KEY (subject_id) REFERENCES subjects(id),
    FOREIGN KEY (exam_type_id) REFERENCES lookup_exam_types(id),
    FOREIGN KEY (created_by_user_id) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='سياسات الدرجات المرنة — FK إلى lookup_exam_types + دعم القوالب الافتراضية';

-- ═══════════════════════════════════════════════════════════════════════════════
-- 3. المكونات المخصصة للسياسة (اختياري لكل مدرسة)
-- ═══════════════════════════════════════════════════════════════════════════════
-- الهدف: السماح لكل مدرسة بإضافة مكونات إضافية مثل:
--   سلوك، مشروع فصلي، مهارات عملية، قراءة، إلخ
-- هذه المكونات تُجمع في monthly_custom_component_scores

CREATE TABLE IF NOT EXISTS grading_policy_custom_components (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    policy_id INT UNSIGNED NOT NULL COMMENT 'FK → grading_policies',
    component_code VARCHAR(50) NOT NULL COMMENT 'رمز داخلي ثابت مثل: BEHAVIOR, PROJECT',
    component_name_ar VARCHAR(100) NOT NULL COMMENT 'اسم المكون المعروض',
    max_score DECIMAL(5,2) NOT NULL DEFAULT 0.00 COMMENT 'الدرجة العظمى لهذا المكون',
    calculation_mode ENUM('MANUAL', 'AUTO_ATTENDANCE', 'AUTO_HOMEWORK', 'AUTO_EXAM') NOT NULL DEFAULT 'MANUAL'
        COMMENT 'طريقة احتساب المكون',
    include_in_monthly BOOLEAN DEFAULT TRUE COMMENT 'يدخل في المحصلة الشهرية',
    include_in_semester BOOLEAN DEFAULT TRUE COMMENT 'يدخل في نتيجة الفصل',
    sort_order TINYINT UNSIGNED DEFAULT 1,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NULL ON UPDATE CURRENT_TIMESTAMP,

    CHECK (max_score >= 0),
    UNIQUE KEY uk_gpcc (policy_id, component_code),
    INDEX idx_gpcc_active (is_active),
    INDEX idx_gpcc_order (sort_order),

    FOREIGN KEY (policy_id) REFERENCES grading_policies(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='تعريف مكونات تقييم مخصصة لكل سياسة درجات';

-- ═══════════════════════════════════════════════════════════════════════════════
-- 4. تعيين المعلمين للمواد والفصول (§2.4)
-- ═══════════════════════════════════════════════════════════════════════════════
-- يربط المعلم بالمادة والفصل للعام الدراسي
-- يمنع معلماً غير معيّن من إدخال الدرجات

CREATE TABLE IF NOT EXISTS teacher_assignments (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    academic_year_id INT UNSIGNED NOT NULL,
    semester_id INT UNSIGNED NOT NULL,
    employee_id INT UNSIGNED NOT NULL COMMENT 'FK → employees (المعلم)',
    subject_id INT UNSIGNED NOT NULL COMMENT 'FK → subjects (المادة)',
    classroom_id INT UNSIGNED NOT NULL COMMENT 'FK → classrooms (الشعبة)',

    is_primary BOOLEAN DEFAULT TRUE COMMENT 'هل هو المعلم الأساسي؟',
    is_active BOOLEAN DEFAULT TRUE,
    notes TEXT NULL,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NULL ON UPDATE CURRENT_TIMESTAMP,
    created_by_user_id INT UNSIGNED NULL,

    -- معلم واحد لكل مادة/شعبة/فصل
    UNIQUE KEY uk_teacher_assignment (academic_year_id, semester_id, subject_id, classroom_id),
    INDEX idx_ta_employee (employee_id),
    INDEX idx_ta_subject (subject_id),
    INDEX idx_ta_classroom (classroom_id),

    FOREIGN KEY (academic_year_id) REFERENCES academic_years(id),
    FOREIGN KEY (semester_id) REFERENCES semesters(id),
    FOREIGN KEY (employee_id) REFERENCES employees(id),
    FOREIGN KEY (subject_id) REFERENCES subjects(id),
    FOREIGN KEY (classroom_id) REFERENCES classrooms(id),
    FOREIGN KEY (created_by_user_id) REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='تعيين المعلمين للمواد والفصول — يمنع الإدخال غير المصرح به للدرجات';

-- ═══════════════════════════════════════════════════════════════════════════════
SELECT '✅ DDL_POLICIES v4.0: السياسات + تعيين المعلمين + lookup_exam_types FK' AS message;
