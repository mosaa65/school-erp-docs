-- 📊 نظام لوحة التحكم التنفيذية (Executive / BI Dashboard)
-- 📂 System 15: BI & Analytics Hub
-- 👨‍💻 Engineer: Mousa Alawadhi / Amaar Al-Shuaibi
-- 🏗️ Architectural Lead: Antigravity AI

-- التاريخ: 2026-01-16
-- الإصدار: 1.0 (Initial Intelligence Layer)

-- ═══════════════════════════════════════════════════════════════════════════════
-- 1. تعريفات ذكاء الأعمال (BI & KPI Definitions)
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS lookup_kpi_categories (
    id TINYINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name_ar VARCHAR(50) NOT NULL,
    code VARCHAR(30) NOT NULL UNIQUE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='تصنيفات مؤشرات الأداء';

INSERT INTO lookup_kpi_categories (name_ar, code) VALUES 
('أكاديمي', 'ACADEMIC'), 
('إداري', 'ADMIN'), 
('مالي', 'FINANCIAL'), 
('حضور وغياب', 'ATTENDANCE'),
('التواصل', 'ENGAGEMENT');

CREATE TABLE IF NOT EXISTS bi_kpi_definitions (
    id SMALLINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    category_id TINYINT UNSIGNED NOT NULL,
    name_ar VARCHAR(100) NOT NULL,
    code VARCHAR(50) NOT NULL UNIQUE,
    description TEXT,
    
    -- المنطق (Metadata)
    calculation_logic TEXT COMMENT 'وصف لكيفية حساب المؤشر برمجياً',
    unit VARCHAR(20) DEFAULT '%' COMMENT 'الوحدة (%, عدد, مبلغ)',
    
    -- الأهداف
    target_value DECIMAL(15,2),
    warning_threshold DECIMAL(15,2) COMMENT 'عتبة التحذير',
    critical_threshold DECIMAL(15,2) COMMENT 'عتبة الخطر',
    
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (category_id) REFERENCES lookup_kpi_categories(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='تعريفات مؤشرات الأداء الرئيسي (KPIs)';

CREATE TABLE IF NOT EXISTS bi_kpi_snapshots (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    kpi_id SMALLINT UNSIGNED NOT NULL,
    snapshot_date DATE NOT NULL,
    
    -- القيم
    actual_value DECIMAL(15,2) NOT NULL,
    target_value DECIMAL(15,2),
    
    -- الربط التنظيمي (اختياري)
    grade_level_id INT UNSIGNED NULL,
    classroom_id INT UNSIGNED NULL,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    INDEX idx_snapshot_lookup (kpi_id, snapshot_date),
    FOREIGN KEY (kpi_id) REFERENCES bi_kpi_definitions(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='سجل اللقطات التاريخية للمؤشرات (Trend Analysis)';

-- ═══════════════════════════════════════════════════════════════════════════════
-- 2. تخصيص لوحه القيادة (Dashboard Layout & Widgets)
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS bi_dashboard_layouts (
    id TINYINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name_ar VARCHAR(100) NOT NULL,
    role_id TINYINT UNSIGNED NULL COMMENT 'ربط الدور بالواجهة الافتراضية',
    config JSON COMMENT 'إعدادات توزيع العناصر',
    
    is_system BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='تخطيطات لوحات القيادة';

CREATE TABLE IF NOT EXISTS bi_dashboard_widgets (
    id SMALLINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    layout_id TINYINT UNSIGNED NOT NULL,
    kpi_id SMALLINT UNSIGNED NULL,
    
    title_ar VARCHAR(100) NOT NULL,
    widget_type ENUM('CHART_LINE', 'CHART_BAR', 'CHART_PIE', 'NUMBER', 'GAUGE', 'HEATMAP', 'LIST') DEFAULT 'NUMBER',
    
    -- إعدادات العرض
    display_order TINYINT UNSIGNED DEFAULT 0,
    width_span TINYINT DEFAULT 4 COMMENT 'Grid units (1-12)',
    refresh_rate_seconds INT DEFAULT 300,
    
    FOREIGN KEY (layout_id) REFERENCES bi_dashboard_layouts(id) ON DELETE CASCADE,
    FOREIGN KEY (kpi_id) REFERENCES bi_kpi_definitions(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='عناصر لوحة القيادة (Widgets)';

-- ═══════════════════════════════════════════════════════════════════════════════
-- 3. المراقبة والتنبيهات (Monitoring & Alerts)
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS bi_alert_rules (
    id SMALLINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    kpi_id SMALLINT UNSIGNED NOT NULL,
    name_ar VARCHAR(100) NOT NULL,
    
    condition_operator ENUM('>', '<', '>=', '<=', '=', '!=') NOT NULL,
    threshold_value DECIMAL(15,2) NOT NULL,
    
    severity ENUM('INFO', 'WARNING', 'CRITICAL') DEFAULT 'WARNING',
    notify_via_sns BOOLEAN DEFAULT TRUE,
    
    is_active BOOLEAN DEFAULT TRUE,
    FOREIGN KEY (kpi_id) REFERENCES bi_kpi_definitions(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='قواعد التنبيه التلقائي';

CREATE TABLE IF NOT EXISTS bi_alert_history (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    rule_id SMALLINT UNSIGNED NOT NULL,
    kpi_snapshot_id BIGINT UNSIGNED NULL,
    
    detected_value DECIMAL(15,2) NOT NULL,
    threshold_at_time DECIMAL(15,2) NOT NULL,
    
    is_resolved BOOLEAN DEFAULT FALSE,
    resolved_at TIMESTAMP NULL,
    resolver_user_id INT UNSIGNED NULL,
    resolution_notes TEXT,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (rule_id) REFERENCES bi_alert_rules(id),
    FOREIGN KEY (kpi_snapshot_id) REFERENCES bi_kpi_snapshots(id),
    FOREIGN KEY (resolver_user_id) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='سجل التنبيهات المكتشفة';

-- ═══════════════════════════════════════════════════════════════════════════════
-- 4. التقارير التنفيذية والأرشفة (Executive Reporting)
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS bi_executive_reports (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(200) NOT NULL,
    report_type ENUM('DAILY', 'WEEKLY', 'MONTHLY', 'SEMESTER', 'AD_HOC') NOT NULL,
    
    generated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    generated_by_user_id INT UNSIGNED NULL,
    
    summary_data JSON COMMENT 'بيانات مجمعة للتقرير',
    file_path VARCHAR(500) COMMENT 'رابط الملف المصدر (PDF/Excel)',
    
    INDEX idx_report_type (report_type),
    FOREIGN KEY (generated_by_user_id) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='جامع التقارير التنفيذية';

-- ═══════════════════════════════════════════════════════════════════════════════
-- 5. الرؤى التحليلية (Analytical Views - THE Intelligence Layer)
-- ═══════════════════════════════════════════════════════════════════════════════

-- 1. كشف الحضور التنفيذي (Executive Attendance Heatmap Source)
CREATE OR REPLACE VIEW v_bi_attendance_analytics AS
SELECT 
    gl.name_ar AS grade_level,
    c.name_ar AS classroom,
    ad.attendance_date,
    COUNT(CASE WHEN ad.status_id = 1 THEN 1 END) AS present_count,
    COUNT(CASE WHEN ad.status_id = 2 THEN 1 END) AS absent_count,
    (COUNT(CASE WHEN ad.status_id = 1 THEN 1 END) / COUNT(*)) * 100 AS attendance_rate
FROM student_attendance ad
JOIN student_enrollments se ON ad.enrollment_id = se.id
JOIN classrooms c ON se.classroom_id = c.id
JOIN grade_levels gl ON c.grade_level_id = gl.id
GROUP BY gl.name_ar, c.name_ar, ad.attendance_date;

-- 2. تحليل الأداء الأكاديمي (Academic Performance intelligence)
CREATE OR REPLACE VIEW v_bi_academic_kpis AS
SELECT 
    sub.name_ar AS subject_name,
    gl.name_ar AS grade_level,
    AVG(ses.score) AS average_score,
    MIN(ses.score) AS min_score,
    MAX(ses.score) AS max_score,
    COUNT(CASE WHEN ses.score < 50 THEN 1 END) AS failing_count,
    (COUNT(CASE WHEN ses.score >= 50 THEN 1 END) / COUNT(*)) * 100 AS success_rate
FROM student_exam_scores ses
JOIN exam_timetable et ON ses.exam_timetable_id = et.id
JOIN subjects sub ON et.subject_id = sub.id
JOIN grade_levels gl ON et.grade_level_id = gl.id
GROUP BY sub.name_ar, gl.name_ar;

-- 3. تحليل أحمال المعلمين (Teacher Workload BI)
CREATE OR REPLACE VIEW v_bi_teacher_efficiency AS
SELECT 
    e.full_name AS teacher_name,
    COUNT(ts.id) AS weekly_slots,
    AVG(ses.score) AS average_student_score_in_his_classes
FROM employees e
JOIN timetable_slots ts ON e.id = ts.employee_id
LEFT JOIN student_exam_scores ses ON ts.subject_id = (SELECT subject_id FROM exam_timetable WHERE subject_id = ts.subject_id LIMIT 1)
GROUP BY e.full_name;

-- 4. تحليل تفاعل أولياء الأمور (Engagement Score)
CREATE OR REPLACE VIEW v_bi_parent_engagement AS
SELECT 
    pa.full_name AS parent_name,
    COUNT(al.id) AS app_interactions_last_30_days,
    (SELECT COUNT(*) FROM parent_notifications WHERE parent_account_id = pa.id) AS notifications_received,
    (SELECT COUNT(*) FROM parent_notifications WHERE parent_account_id = pa.id AND is_read = TRUE) AS notifications_read
FROM parent_accounts pa
LEFT JOIN parent_activity_logs al ON pa.id = al.parent_account_id AND al.created_at >= DATE_SUB(NOW(), INTERVAL 30 DAY)
GROUP BY pa.id, pa.full_name;

-- 5. تحليل المخاطر (Risk Indicators)
CREATE OR REPLACE VIEW v_bi_risk_matrix AS
SELECT 
    s.id AS student_id,
    s.full_name AS student_name,
    'ACADEMIC' AS risk_type,
    'LOW_GRADES' AS risk_reason,
    AVG(ses.score) AS indicator_value
FROM students s
JOIN student_enrollments se ON s.id = se.student_id
JOIN student_exam_scores ses ON se.id = ses.enrollment_id
GROUP BY s.id, s.full_name
HAVING AVG(ses.score) < 60
UNION ALL
SELECT 
    s.id AS student_id,
    s.full_name AS student_name,
    'ATTENDANCE' AS risk_type,
    'HIGH_ABSENCE' AS risk_reason,
    (COUNT(CASE WHEN ad.status_id = 2 THEN 1 END) / COUNT(*)) * 100 AS absence_rate
FROM students s
JOIN student_enrollments se ON s.id = se.student_id
JOIN student_attendance ad ON se.id = ad.enrollment_id
GROUP BY s.id, s.full_name
HAVING (COUNT(CASE WHEN ad.status_id = 2 THEN 1 END) / COUNT(*)) * 100 > 15;
