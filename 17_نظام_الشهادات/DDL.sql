-- 📜 نظام الشهادات الذكي (Smart Certificate System - SCS)
-- 📂 System 17: Academic Certification Layer
-- 👨‍💻 Engineer: Mousa Alawadhi / Ahmed Al-Hattar
-- 🏗️ Architectural Lead: Antigravity AI

-- التاريخ: 2026-01-16
-- الإصدار: 1.0 (Fixed Template + Dynamic Data)

-- ═══════════════════════════════════════════════════════════════════════════════
-- 1. تعريفات الشهادات (Certificate Definitions)
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS lookup_certificate_kinds (
    id TINYINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name_ar VARCHAR(100) NOT NULL,
    code VARCHAR(30) NOT NULL UNIQUE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='أنواع الشهادات المتاحة';

INSERT INTO lookup_certificate_kinds (name_ar, code) VALUES 
('شهادة نهاية العام', 'YEAR_END'), 
('شهادة فصل دراسي', 'SEMESTER'), 
('شهادة تقدير وتفوق', 'MERIT'), 
('شهادة مغادرة/انتقال', 'LEAVING'),
('بيان درجات', 'TRANSCRIPT');

CREATE TABLE IF NOT EXISTS certificate_templates (
    id SMALLINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    kind_id TINYINT UNSIGNED NOT NULL,
    name_ar VARCHAR(150) NOT NULL,
    
    -- التصميم (Template Logic)
    background_image_path VARCHAR(255) COMMENT 'رابط صورة خلفية الشهادة (القالب الثابت)',
    layout_config JSON COMMENT 'إعدادات CSS/HTML ونقاط التموضع للبيانات',
    
    -- الأبعاد
    page_size ENUM('A4', 'A5', 'LANDSCAPE_A4') DEFAULT 'LANDSCAPE_A4',
    
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (kind_id) REFERENCES lookup_certificate_kinds(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='قوالب الشهادات الرسمية (The Fixed Form)';

-- ═══════════════════════════════════════════════════════════════════════════════
-- 2. ربط الحقول الديناميكية (Dynamic Placeholder Mapping)
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS certificate_placeholders (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    template_id SMALLINT UNSIGNED NOT NULL,
    
    placeholder_key VARCHAR(50) NOT NULL COMMENT 'مثل: {{student_name}}',
    data_source_field VARCHAR(100) NOT NULL COMMENT 'الحقل المقابل في الـ View أو الجدول',
    
    -- تنسيق العرض داخل الشهادة
    font_family VARCHAR(50) DEFAULT 'Amiri',
    font_size TINYINT DEFAULT 14,
    font_color VARCHAR(10) DEFAULT '#000000',
    position_x DECIMAL(5,2) COMMENT 'الإحداثي السيني بنسبة مئوية',
    position_y DECIMAL(5,2) COMMENT 'الإحداثي الصادي بنسبة مئوية',
    
    UNIQUE KEY uk_template_placeholder (template_id, placeholder_key),
    FOREIGN KEY (template_id) REFERENCES certificate_templates(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='خريطة البيانات الديناميكية داخل القالب';

-- ═══════════════════════════════════════════════════════════════════════════════
-- 3. حوكمة الإصدار والتوقيع (Generation & Governance)
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS certificate_authorized_signers (
    id TINYINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    employee_id INT UNSIGNED NOT NULL,
    title_ar VARCHAR(100) NOT NULL COMMENT 'مثلاً: مدير المدرسة، مسؤول التسجيل',
    
    digital_signature_path VARCHAR(255) COMMENT 'رابط صورة التوقيع المفرغة',
    digital_stamp_path VARCHAR(255) COMMENT 'رابط صورة الختم الرسمي',
    
    is_active BOOLEAN DEFAULT TRUE,
    FOREIGN KEY (employee_id) REFERENCES employees(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='الموقعون المعتمدون للشهادات';

CREATE TABLE IF NOT EXISTS issued_certificates (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    template_id SMALLINT UNSIGNED NOT NULL,
    student_id INT UNSIGNED NOT NULL,
    academic_year_id INT UNSIGNED NOT NULL,
    
    -- بيانات التوثيق
    certificate_serial VARCHAR(50) NOT NULL UNIQUE COMMENT 'الرقم التسلسلي الفريد للشهادة',
    verification_hash CHAR(64) NOT NULL COMMENT 'كود التحقق الرقمي للتأكد من صحة الشهادة',
    
    -- الإصدار
    issued_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    issued_by_user_id INT UNSIGNED NOT NULL,
    
    -- حالة النسخة
    is_original BOOLEAN DEFAULT TRUE,
    print_counts INT UNSIGNED DEFAULT 0,
    
    FOREIGN KEY (template_id) REFERENCES certificate_templates(id),
    FOREIGN KEY (student_id) REFERENCES students(id),
    FOREIGN KEY (academic_year_id) REFERENCES academic_years(id),
    FOREIGN KEY (issued_by_user_id) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='سجل الشهادات الصادرة فعلياً (The Final Audit)';

-- ═══════════════════════════════════════════════════════════════════════════════
-- 4. محرك تجميع النتائج (Data Engine Views)
-- ═══════════════════════════════════════════════════════════════════════════════

-- View شامل لتوليد بيانات الشهادة (End-of-Year Certificate Engine)
CREATE OR REPLACE VIEW v_certificate_data_primary AS
SELECT 
    s.id AS student_id,
    s.full_name AS placeholder_student_full_name,
    gl.name_ar AS placeholder_grade_level,
    c.name_ar AS placeholder_classroom,
    ay.name_ar AS placeholder_academic_year,
    
    -- الدرجات والمجاميع (SGAS Layer)
    (SELECT SUM(semester_work_total + IFNULL(final_exam_score, 0)) 
     FROM semester_grades 
     WHERE enrollment_id = se.id) AS placeholder_total_marks,
     
    (SELECT AVG((semester_work_total + IFNULL(final_exam_score, 0)) / (SELECT max_grade FROM subjects WHERE id = subject_id) * 100)
     FROM semester_grades 
     WHERE enrollment_id = se.id) AS placeholder_gpa_percentage,
     
    sch.name_ar AS placeholder_school_name,
    sch.logo_path AS placeholder_school_logo
    
FROM students s
JOIN student_enrollments se ON s.id = se.student_id
JOIN academic_years ay ON se.academic_year_id = ay.id
JOIN classrooms c ON se.classroom_id = c.id
JOIN grade_levels gl ON c.grade_level_id = gl.id
JOIN schools sch ON gl.id > 0 -- مجرد ربط للحصول على بيانات المدرسة المركزية
WHERE se.is_active = TRUE;
