-- 📄 نظام التقارير وطباعة الكشوفات الذكي (Smart Reports & Print System - SRPS)
-- 📂 System 16: Reporting & Output Layer
-- 👨‍💻 Engineer: Mousa Alawadhi / Ahmed Al-Hattar
-- 🏗️ Architectural Lead: Antigravity AI

-- التاريخ: 2026-01-16
-- الإصدار: 1.0 (Dynamic Intelligence Layer)

-- ═══════════════════════════════════════════════════════════════════════════════
-- 1. هيكل تعريف التقارير (Report Structure Definitions)
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS lookup_report_categories (
    id TINYINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name_ar VARCHAR(50) NOT NULL,
    code VARCHAR(30) NOT NULL UNIQUE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='تصنيفات التقارير';

INSERT INTO lookup_report_categories (name_ar, code) VALUES 
('شؤون الطلاب', 'STUDENTS'), 
('أكاديمي ودرجات', 'ACADEMIC'), 
('موارد بشرية', 'HR'), 
('حسابات ومالية', 'FINANCIAL'),
('إداري وعام', 'ADMIN'),
('إشعارات وتواصل', 'COMMUNICATION');

CREATE TABLE IF NOT EXISTS report_templates (
    id SMALLINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    category_id TINYINT UNSIGNED NOT NULL,
    name_ar VARCHAR(150) NOT NULL,
    code VARCHAR(50) NOT NULL UNIQUE,
    description TEXT,
    
    -- مصدر البيانات
    base_view_name VARCHAR(100) NOT NULL COMMENT 'اسم الـ View البرمجي الذي يوفر البيانات',
    
    -- الإعدادات الافتراضية للطباعة
    default_paper_size ENUM('A4', 'A5', 'LETTER', 'LEGAL') DEFAULT 'A4',
    default_orientation ENUM('PORTRAIT', 'LANDSCAPE') DEFAULT 'PORTRAIT',
    
    -- حزم التصميم (JSON)
    header_config JSON COMMENT 'إعدادات الرأس: شعار، عنوان، تاريخ',
    footer_config JSON COMMENT 'إعدادات التذييل: أرقام صفحات، توقيعات',
    
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (category_id) REFERENCES lookup_report_categories(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='قوالب التقارير الذكية';

CREATE TABLE IF NOT EXISTS report_columns (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    template_id SMALLINT UNSIGNED NOT NULL,
    
    column_name VARCHAR(64) NOT NULL COMMENT 'الاسم البرمجي في قاعدة البيانات',
    display_name_ar VARCHAR(100) NOT NULL COMMENT 'الاسم الظاهر في التقرير',
    
    -- الخصائص
    is_visible_default BOOLEAN DEFAULT TRUE,
    sort_order TINYINT UNSIGNED DEFAULT 0,
    data_type ENUM('STRING', 'NUMBER', 'DATE', 'PRICE', 'STATUS') DEFAULT 'STRING',
    
    -- تنسيق خاص (اختياري)
    css_class VARCHAR(50) COMMENT 'تنسيق CSS خاص للعمود (مثلاً نص سميك)',
    
    UNIQUE KEY uk_template_column (template_id, column_name),
    FOREIGN KEY (template_id) REFERENCES report_templates(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='أعمدة التقارير والتحكم في ظهورها';

-- ═══════════════════════════════════════════════════════════════════════════════
-- 2. الفلترة الديناميكية (Dynamic Filtering)
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS report_filter_definitions (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    template_id SMALLINT UNSIGNED NOT NULL,
    
    filter_field VARCHAR(64) NOT NULL COMMENT 'الحقل المراد الفلترة عليه',
    label_ar VARCHAR(100) NOT NULL,
    
    filter_type EN_UI_TYPE ENUM('SELECT', 'MULTI_SELECT', 'DATE_RANGE', 'NUMBER_RANGE', 'BOOLEAN', 'TEXT') DEFAULT 'SELECT',
    
    -- المرجعية (للـ Dropdowns مثلاً)
    lookup_source VARCHAR(100) COMMENT 'اسم جدول الـ Lookup أو استعلام لجلب الخيارات',
    
    default_value VARCHAR(255),
    is_required BOOLEAN DEFAULT FALSE,
    
    FOREIGN KEY (template_id) REFERENCES report_templates(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='تعريف خيارات الفلترة لكل تقرير';

-- ═══════════════════════════════════════════════════════════════════════════════
-- 3. تخصيصات المستخدم (User Customizations)
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS user_saved_reports (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id INT UNSIGNED NOT NULL,
    template_id SMALLINT UNSIGNED NOT NULL,
    
    custom_name VARCHAR(150),
    
    -- الإعدادات المحفوظة
    selected_columns JSON COMMENT 'قائمة الأعمدة المختارة وترتيبها',
    filter_values JSON COMMENT 'القيم المختارة في الفلترة',
    
    -- إعدادات الطباعة الخاصة
    print_settings JSON COMMENT 'هوامش، أحجام خطوط، إلخ',
    
    last_run_at TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (template_id) REFERENCES report_templates(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='التقارير المحفوظة والمخصصة لكل مستخدم';

-- ═══════════════════════════════════════════════════════════════════════════════
-- 4. السجلات والتدقيق (Logging & Audit)
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS report_generation_logs (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id INT UNSIGNED NOT NULL,
    report_name VARCHAR(255),
    
    -- الإجراء
    action ENUM('VIEW', 'PRINT', 'DOWNLOAD_PDF', 'EXPORT_EXCEL') NOT NULL,
    
    -- السياق
    params JSON COMMENT 'البارامترات المستخدمة (Filters)',
    record_count INT UNSIGNED DEFAULT 0,
    
    ip_address VARCHAR(45),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (user_id) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='سجل إنشاء التقارير وطباعتها';

-- ═══════════════════════════════════════════════════════════════════════════════
-- 5. الرؤى المدمجة للتقارير (Pre-defined Report Views)
-- ═══════════════════════════════════════════════════════════════════════════════

-- 1. كشف الطلاب الشامل (Master Student List View)
CREATE OR REPLACE VIEW v_report_student_master AS
SELECT 
    s.id AS student_id,
    s.full_name,
    s.gender,
    s.birth_date,
    TIMESTAMPDIFF(YEAR, s.birth_date, CURDATE()) AS age,
    gl.name_ar AS grade_level,
    c.name_ar AS classroom,
    se.academic_year_id,
    p.full_name AS parent_name,
    p.phone AS parent_phone
FROM students s
JOIN student_enrollments se ON s.id = se.student_id
JOIN classrooms c ON se.classroom_id = c.id
JOIN grade_levels gl ON c.grade_level_id = gl.id
LEFT JOIN parents p ON s.parent_id = p.id
WHERE se.is_active = TRUE;

-- 2. كشف الدرجات المفصل (Detailed Grades Report View)
CREATE OR REPLACE VIEW v_report_grades_detailed AS
SELECT 
    s.full_name AS student_name,
    sub.name_ar AS subject_name,
    gl.name_ar AS grade_level,
    c.name_ar AS classroom,
    ep.name_ar AS period_name,
    ses.score,
    es.max_score,
    (ses.score / et.max_score) * 100 AS percentage,
    e.full_name AS teacher_name
FROM student_exam_scores ses
JOIN exam_timetable et ON ses.exam_timetable_id = et.id
JOIN subjects sub ON et.subject_id = sub.id
JOIN student_enrollments se ON ses.enrollment_id = se.id
JOIN students s ON se.student_id = s.id
JOIN classrooms c ON se.classroom_id = c.id
JOIN grade_levels gl ON et.grade_level_id = gl.id
JOIN exam_periods ep ON et.exam_period_id = ep.id
LEFT JOIN employees e ON c.supervisor_id = e.id;

-- 3. ملخص حضور الطلاب (Student Attendance Summary View)
CREATE OR REPLACE VIEW v_report_attendance_summary AS
SELECT 
    s.full_name AS student_name,
    gl.name_ar AS grade_level,
    c.name_ar AS classroom,
    COUNT(ad.id) AS total_days,
    COUNT(CASE WHEN ad.status_id = 1 THEN 1 END) AS present_days,
    COUNT(CASE WHEN ad.status_id = 2 THEN 1 END) AS absent_days,
    (COUNT(CASE WHEN ad.status_id = 1 THEN 1 END) / COUNT(ad.id)) * 100 AS attendance_percentage
FROM student_attendance ad
JOIN student_enrollments se ON ad.enrollment_id = se.id
JOIN students s ON se.student_id = s.id
JOIN classrooms c ON se.classroom_id = c.id
JOIN grade_levels gl ON c.grade_level_id = gl.id
GROUP BY s.id, s.full_name, gl.id, c.id;
