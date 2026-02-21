-- 🏫 School Management System
-- 📂 System 18: Public Viewer Feedback (نظام المشاهدين)
-- 👨‍💻 Engineer: Mousa Alawadhi (Architectural Lead)

-- التاريخ: 2026-01-16
-- الإصدار: 1.0

-- ═══════════════════════════════════════════════════════════════════════════════
-- 1. جدول سجل المشاهدين
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS public_viewer_logs (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    viewer_name VARCHAR(150) NOT NULL,
    phone_number VARCHAR(20) NULL,
    gender_id TINYINT UNSIGNED NOT NULL COMMENT 'Link to lookup_gender',
    
    -- الأبعاد الزمنية
    academic_year_id INT UNSIGNED NOT NULL,
    semester_id INT UNSIGNED NOT NULL,
    month_id TINYINT UNSIGNED NOT NULL,
    week_id TINYINT UNSIGNED NOT NULL,
    day_id TINYINT UNSIGNED NOT NULL,
    
    visit_date_gregorian DATE NOT NULL DEFAULT (CURRENT_DATE),
    visit_date_hijri VARCHAR(10) NOT NULL,
    
    -- البيانات النشطة
    viewed_content TEXT COMMENT 'ماذا شاهد؟',
    session_duration_minutes INT UNSIGNED DEFAULT 0,
    
    -- الانطباع (للمدير فقط)
    impression_text TEXT COMMENT 'اكتب انطباعك هنا (فضلاً: أكتب انطباعك هنا)',
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (academic_year_id) REFERENCES academic_years(id),
    FOREIGN KEY (semester_id) REFERENCES semesters(id),
    FOREIGN KEY (month_id) REFERENCES lookup_hijri_months(id),
    FOREIGN KEY (week_id) REFERENCES lookup_week_numbers(id),
    FOREIGN KEY (day_id) REFERENCES lookup_days(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='سجل انطباعات المشاهدين والزوار الرقميين';

-- ═══════════════════════════════════════════════════════════════════════════════
-- 2. الرؤى التحليلية (Analytical Views)
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE OR REPLACE VIEW v_public_viewer_master AS
SELECT 
    v.id,
    v.viewer_name,
    v.phone_number,
    CASE WHEN v.gender_id = 1 THEN 'ذكر' ELSE 'أنثى' END AS gender_ar,
    ay.year_name AS academic_year,
    sem.name_ar AS semester,
    hm.name_ar AS month_name,
    wn.name_ar AS week_name,
    d.name_ar AS day_name,
    v.visit_date_hijri,
    v.visit_date_gregorian,
    v.viewed_content,
    v.session_duration_minutes,
    v.impression_text
FROM public_viewer_logs v
JOIN academic_years ay ON v.academic_year_id = ay.id
JOIN semesters sem ON v.semester_id = sem.id
JOIN lookup_hijri_months hm ON v.month_id = hm.id
JOIN lookup_week_numbers wn ON v.week_id = wn.id
JOIN lookup_days d ON v.day_id = d.id;

-- التقارير المطلوبة: يومي، أسبوعي، شهري، فصلي، سنوي
CREATE OR REPLACE VIEW v_report_viewers_daily AS
SELECT visit_date_gregorian, COUNT(*) as visitor_count FROM public_viewer_logs GROUP BY visit_date_gregorian;

CREATE OR REPLACE VIEW v_report_viewers_weekly AS
SELECT academic_year_id, month_id, week_id, COUNT(*) as visitor_count FROM public_viewer_logs GROUP BY academic_year_id, month_id, week_id;

CREATE OR REPLACE VIEW v_report_viewers_monthly AS
SELECT academic_year_id, month_id, COUNT(*) as visitor_count FROM public_viewer_logs GROUP BY academic_year_id, month_id;
