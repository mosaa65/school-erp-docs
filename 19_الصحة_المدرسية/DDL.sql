-- ╔══════════════════════════════════════════════════════════════════════════════╗
-- ║                       نظام الصحة المدرسية (Student Health System)            ║
-- ║                School Management System - Health & Medical Records            ║
-- ║                                                                               ║
-- ║       يشمل: السجل الطبي، اللقاحات، زيارات العيادة، والحالات المزمنة         ║
-- ╚══════════════════════════════════════════════════════════════════════════════╝

-- التاريخ: 2026-01-19
-- الإصدار: 1.0
-- المهندس المسؤول: موسى العواضي
-- قاعدة البيانات: MySQL 8.0+

-- ═══════════════════════════════════════════════════════════════════════════════
-- القسم 1: الجداول المرجعية (Lookups)
-- ═══════════════════════════════════════════════════════════════════════════════

-- 1.1 أنواع الأمراض والظروف الصحية
CREATE TABLE IF NOT EXISTS lookup_illness_types (
    id TINYINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name_ar VARCHAR(100) NOT NULL,
    is_chronic BOOLEAN DEFAULT FALSE COMMENT 'هل هو مرض مزمن؟',
    is_active BOOLEAN DEFAULT TRUE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='أنواع الأمراض';

INSERT INTO lookup_illness_types (name_ar, is_chronic) VALUES
('ربو', TRUE),
('سكري', TRUE),
('حساسية طعام', TRUE),
('حساسية أدوية', TRUE),
('نزلة برد', FALSE),
('صداع', FALSE),
('مغص معوي', FALSE);

-- 1.2 أنواع اللقاحات
CREATE TABLE IF NOT EXISTS lookup_vaccine_types (
    id TINYINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name_ar VARCHAR(100) NOT NULL,
    required_age_months TINYINT UNSIGNED NULL,
    description TEXT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='أنواع اللقاحات';

INSERT INTO lookup_vaccine_types (name_ar) VALUES
('شلل الأطفال'),
('الحصبة'),
('السل (BCG)'),
('الثلاثي البكتيري'),
('التهاب الكبد البائي');

-- 1.3 العلاجات والإجراءات المتوفرة بالعيادة
CREATE TABLE IF NOT EXISTS lookup_medical_actions (
    id TINYINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name_ar VARCHAR(100) NOT NULL,
    is_active BOOLEAN DEFAULT TRUE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='الإجراءات الطبية';

INSERT INTO lookup_medical_actions (name_ar) VALUES
('إعطاء مسكن'),
('تضميد جرح'),
('قياس حرارة/ضغط'),
('إحالة للمستشفى'),
('استدعاء ولي الأمر'),
('راحة في الغرفة الصحية');

-- ═══════════════════════════════════════════════════════════════════════════════
-- القسم 2: السجلات الطبية الأساسية (Medical History)
-- ═══════════════════════════════════════════════════════════════════════════════

-- 2.1 السجل الطبي للطالب (العام)
CREATE TABLE IF NOT EXISTS student_medical_profiles (
    student_id INT UNSIGNED PRIMARY KEY,
    blood_type_id TINYINT UNSIGNED COMMENT 'FK to lookup_blood_types in Shared Sys',
    height_cm DECIMAL(5,2),
    weight_kg DECIMAL(5,2),
    vision_test_results VARCHAR(50) COMMENT 'نتائج فحص النظر',
    hearing_test_results VARCHAR(50),
    general_notes TEXT,
    updated_at TIMESTAMP NULL ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='الملف الصحي العام للطالب';

-- 2.2 سجل الأمراض والحساسية
CREATE TABLE IF NOT EXISTS student_health_conditions (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    student_id INT UNSIGNED NOT NULL,
    illness_type_id TINYINT UNSIGNED NOT NULL,
    diagnosis_date DATE NULL,
    severity ENUM('خفيفة', 'متوسطة', 'حرجة') DEFAULT 'متوسطة',
    medication_details TEXT COMMENT 'الأدوية التي يتناولها الطالب بانتظام',
    is_active BOOLEAN DEFAULT TRUE COMMENT 'هل الحالة لا تزال قائمة؟',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE,
    FOREIGN KEY (illness_type_id) REFERENCES lookup_illness_types(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='سجل الحالات المرضية والحساسية للطلاب';

-- ═══════════════════════════════════════════════════════════════════════════════
-- القسم 3: التحصينات والزيارات (Immunizations & Visits)
-- ═══════════════════════════════════════════════════════════════════════════════

-- 3.1 سجل اللقاحات (Immunization Record)
CREATE TABLE IF NOT EXISTS student_immunizations (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    student_id INT UNSIGNED NOT NULL,
    vaccine_id TINYINT UNSIGNED NOT NULL,
    dose_number TINYINT UNSIGNED DEFAULT 1 COMMENT 'رقم الجرعة',
    vaccination_date DATE NOT NULL,
    batch_number VARCHAR(50) COMMENT 'رقم التشغيلة إن وجد',
    place VARCHAR(150) COMMENT 'مكان التلقيح',
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE,
    FOREIGN KEY (vaccine_id) REFERENCES lookup_vaccine_types(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='سجل اللقاحات والتحصينات';

-- 3.2 سجل زيارة العيادة المدرسية (Clinic Logs)
CREATE TABLE IF NOT EXISTS student_clinic_visits (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    student_id INT UNSIGNED NOT NULL,
    visit_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    complaint TEXT NOT NULL COMMENT 'الشكوى أو الأعراض',
    temperature DECIMAL(4,2) COMMENT 'درجة الحرارة إن قيست',
    action_taken_id TINYINT UNSIGNED NOT NULL COMMENT 'الإجراء المتخذ',
    treatment_details TEXT COMMENT 'تفاصيل العلاج (مثلاً: حبة بندول)',
    outcome ENUM('عاد للفصل', 'غادر المدرسة', 'نُقل للمستشفى') DEFAULT 'عاد للفصل',
    notified_parent BOOLEAN DEFAULT FALSE,
    health_officer_id INT UNSIGNED COMMENT 'الموظف المسؤول (المرشد الصحي)',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE,
    FOREIGN KEY (action_taken_id) REFERENCES lookup_medical_actions(id),
    FOREIGN KEY (health_officer_id) REFERENCES employees(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='سجل زيارات العيادة المدرسية اليومي';

-- ═══════════════════════════════════════════════════════════════════════════════
-- القسم 4: الرؤى الاستقصائية (Health Insights)
-- ═══════════════════════════════════════════════════════════════════════════════

-- 1. قائمة الطلاب "ذوي الحالات الحرجة" (تنبيه للمعلم)
CREATE OR REPLACE VIEW v_health_critical_alerts AS
SELECT 
    s.id AS student_id,
    s.full_name,
    c.name_ar AS classroom,
    it.name_ar AS condition_name,
    shc.medication_details,
    shc.severity
FROM student_health_conditions shc
JOIN students s ON shc.student_id = s.id
JOIN student_enrollments se ON s.id = se.student_id
JOIN classrooms c ON se.classroom_id = c.id
JOIN lookup_illness_types it ON shc.illness_type_id = it.id
WHERE shc.is_active = TRUE AND (shc.severity = 'حرجة' OR it.is_chronic = TRUE);

-- 2. ملخص زيارات العيادة الأسبوعي
CREATE OR REPLACE VIEW v_health_clinic_weekly_summary AS
SELECT 
    DATE(visit_date) AS visit_day,
    COUNT(*) AS total_visits,
    COUNT(CASE WHEN outcome = 'غادر المدرسة' THEN 1 END) AS sent_home,
    COUNT(CASE WHEN outcome = 'نُقل للمستشفى' THEN 1 END) AS hospitalized
FROM student_clinic_visits
WHERE visit_date >= DATE_SUB(CURDATE(), INTERVAL 7 DAY)
GROUP BY DATE(visit_date);
