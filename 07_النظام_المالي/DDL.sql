-- ╔══════════════════════════════════════════════════════════════════════════════╗
-- ║                     النظام المالي الموحد (Unified Financial System)           ║
-- ║                School Management System - Finance & Contributions              ║
-- ║                                                                               ║
-- ║       يشمل: الصناديق، الإيرادات، المصروفات، المساهمة المجتمعية، والرقابة      ║
-- ╚══════════════════════════════════════════════════════════════════════════════╝

-- التاريخ: 2026-01-19
-- الإصدار: 2.0 (Consolidated)
-- المهندس المسؤول: عماد الجماعي / موسى العواضي
-- قاعدة البيانات: MySQL 8.0+

-- ═══════════════════════════════════════════════════════════════════════════════
-- القسم 1: الجداول المرجعية (Lookups)
-- ═══════════════════════════════════════════════════════════════════════════════

-- 1.1 أسباب الإعفاء
CREATE TABLE IF NOT EXISTS lookup_exemption_reasons (
    id TINYINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name_ar VARCHAR(50) NOT NULL,
    code VARCHAR(20) NOT NULL UNIQUE,
    is_active BOOLEAN DEFAULT TRUE,
    sort_order TINYINT DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='أسباب الإعفاء';

INSERT INTO lookup_exemption_reasons (name_ar, code, sort_order) VALUES
('يتيم', 'ORPHAN', 1),
('ابن تربوي', 'TEACHER_CHILD', 2),
('ابن موظف', 'EMPLOYEE_CHILD', 3),
('أحفاد بلال', 'BILAL_DESCENDANTS', 4),
('له أكثر من أخ', 'MULTIPLE_SIBLINGS', 5),
('حالة متعسرة', 'FINANCIAL_HARDSHIP', 6),
('أخرى', 'OTHER', 99);

-- 1.2 جهات/مصادر الإعفاء (Confirmatory Authorities)
CREATE TABLE IF NOT EXISTS lookup_exemption_authorities (
    id TINYINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name_ar VARCHAR(50) NOT NULL,
    code VARCHAR(20) NOT NULL UNIQUE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='جهات الإعفاء';

INSERT INTO lookup_exemption_authorities (name_ar, code) VALUES
('تعميم وزاري', 'CIRCULAR'),
('قرار مدير', 'PRINCIPAL'),
('مجلس الآباء', 'PARENTS_COUNCIL'),
('أخرى', 'OTHER');

-- 1.3 مبالغ المساهمة المقررة (للتوحيد)
CREATE TABLE IF NOT EXISTS lookup_contribution_amounts (
    id TINYINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name_ar VARCHAR(50) NOT NULL COMMENT 'اسم الفئة (مثلاً: أساسي كامل)',
    amount_value DECIMAL(10,2) NOT NULL,
    is_active BOOLEAN DEFAULT TRUE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='مبالغ المساهمة المقررة';

INSERT INTO lookup_contribution_amounts (name_ar, amount_value) VALUES
('أساسي (محسن)', 5000.00),
('أساسي (مخفض)', 2500.00),
('ثانوي (كامل)', 7000.00);

-- 1.4 تصنيفات الإيرادات والمصروفات
CREATE TABLE IF NOT EXISTS financial_categories (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name_ar VARCHAR(100) NOT NULL,
    category_type ENUM('REVENUE', 'EXPENSE') NOT NULL,
    code VARCHAR(30) UNIQUE,
    parent_id INT UNSIGNED NULL,
    is_active BOOLEAN DEFAULT TRUE,
    CONSTRAINT fk_fin_cat_parent FOREIGN KEY (parent_id) REFERENCES financial_categories(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='تصنيفات المحاسبة';

INSERT INTO financial_categories (name_ar, category_type, code) VALUES
('المساهمة المجتمعية', 'REVENUE', 'REV_COMMUNITY'),
('رسوم التسجيل', 'REVENUE', 'REV_REGISTRATION'),
('تبرعات', 'REVENUE', 'REV_DONATION'),
('رواتب ومكافآت', 'EXPENSE', 'EXP_SALARY'),
('صيانة وإصلاحات', 'EXPENSE', 'EXP_MAINTENANCE'),
('نثريات', 'EXPENSE', 'EXP_MISC');

-- ═══════════════════════════════════════════════════════════════════════════════
-- القسم 2: الصناديق والمحاسبة العامة
-- ═══════════════════════════════════════════════════════════════════════════════

-- 2.1 الصناديق المالية
CREATE TABLE IF NOT EXISTS financial_funds (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name_ar VARCHAR(100) NOT NULL,
    code VARCHAR(30) UNIQUE,
    fund_type ENUM('رئيسي', 'فرعي') DEFAULT 'فرعي',
    current_balance DECIMAL(15,2) DEFAULT 0.00,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='الصناديق المالية';

INSERT INTO financial_funds (name_ar, code, fund_type) VALUES
('الصندوق الرئيسي', 'MAIN_FUND', 'رئيسي'),
('صندوق المساهمة المجتمعية', 'COMMUNITY_FUND', 'فرعي');

-- 2.2 الإيرادات العامة
CREATE TABLE IF NOT EXISTS revenues (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    fund_id INT UNSIGNED NOT NULL,
    category_id INT UNSIGNED NOT NULL,
    amount DECIMAL(15,2) NOT NULL,
    revenue_date DATE NOT NULL,
    source_type ENUM('طالب', 'موظف', 'متبرع', 'أخرى') DEFAULT 'أخرى',
    source_id INT UNSIGNED NULL COMMENT 'معرف الطالب/الموظف إذا وجد',
    receipt_number VARCHAR(50),
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by_user_id INT UNSIGNED,
    FOREIGN KEY (fund_id) REFERENCES financial_funds(id),
    FOREIGN KEY (category_id) REFERENCES financial_categories(id),
    FOREIGN KEY (created_by_user_id) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='سجل الإيرادات';

-- 2.3 المصروفات العامة
CREATE TABLE IF NOT EXISTS expenses (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    fund_id INT UNSIGNED NOT NULL,
    category_id INT UNSIGNED NOT NULL,
    amount DECIMAL(15,2) NOT NULL,
    expense_date DATE NOT NULL,
    vendor_name VARCHAR(200) COMMENT 'المستفيد',
    invoice_number VARCHAR(50),
    is_approved BOOLEAN DEFAULT FALSE,
    approved_by_user_id INT UNSIGNED,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by_user_id INT UNSIGNED,
    FOREIGN KEY (fund_id) REFERENCES financial_funds(id),
    FOREIGN KEY (category_id) REFERENCES financial_categories(id),
    FOREIGN KEY (approved_by_user_id) REFERENCES users(id),
    FOREIGN KEY (created_by_user_id) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='سجل المصروفات';

-- ═══════════════════════════════════════════════════════════════════════════════
-- القسم 3: المساهمة المجتمعية (Detailed Tracking)
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS community_contributions (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    enrollment_id INT UNSIGNED NOT NULL,
    
    -- الأبعاد الزمنية (تحسين الربط)
    academic_year_id INT UNSIGNED NOT NULL,
    semester_id INT UNSIGNED NOT NULL,
    month_id INT UNSIGNED NOT NULL COMMENT 'ربط بـ academic_months',
    week_id TINYINT UNSIGNED NULL,
    
    payment_date DATE NOT NULL,
    payment_date_hijri VARCHAR(20),
    
    -- المبالغ
    required_amount_id TINYINT UNSIGNED NOT NULL COMMENT 'المقرر من lookup_contribution_amounts',
    received_amount DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    
    -- الإعفاءات
    is_exempt BOOLEAN DEFAULT FALSE,
    exemption_reason_id TINYINT UNSIGNED NULL,
    exemption_amount DECIMAL(10,2) DEFAULT 0.00,
    exemption_authority_id TINYINT UNSIGNED NULL,
    
    -- المحاسب والموصل
    recipient_employee_id INT UNSIGNED NOT NULL,
    payer_name VARCHAR(150),
    
    receipt_number VARCHAR(50),
    notes TEXT,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by_user_id INT UNSIGNED,
    
    UNIQUE KEY uk_contrib_monthly (enrollment_id, month_id),
    FOREIGN KEY (enrollment_id) REFERENCES student_enrollments(id),
    FOREIGN KEY (academic_year_id) REFERENCES academic_years(id),
    FOREIGN KEY (semester_id) REFERENCES semesters(id),
    FOREIGN KEY (month_id) REFERENCES academic_months(id),
    FOREIGN KEY (required_amount_id) REFERENCES lookup_contribution_amounts(id),
    FOREIGN KEY (exemption_reason_id) REFERENCES lookup_exemption_reasons(id),
    FOREIGN KEY (exemption_authority_id) REFERENCES lookup_exemption_authorities(id),
    FOREIGN KEY (recipient_employee_id) REFERENCES employees(id),
    FOREIGN KEY (created_by_user_id) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='المساهمة المجتمعية التفصيلية';

-- ═══════════════════════════════════════════════════════════════════════════════
-- القسم 4: نظام الرقابة (Viewers/Audit)
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS financial_view_logs (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    viewer_name VARCHAR(100),
    viewer_phone VARCHAR(20),
    view_date DATE NOT NULL,
    target_report VARCHAR(100) COMMENT 'ماذا شاهد (مركز مالي، مسددين، إلخ)',
    impression TEXT COMMENT 'ملاحظات المشاهد',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='رصد انطباعات المشاهدين والملاك';

-- ═══════════════════════════════════════════════════════════════════════════════
-- القسم 5: الرؤى والتقارير الموحدة (Views)
-- ═══════════════════════════════════════════════════════════════════════════════

-- 1. تقرير الأرصدة الشامل
CREATE OR REPLACE VIEW v_unified_financial_status AS
SELECT 
    f.name_ar AS fund_name,
    f.current_balance,
    (SELECT COALESCE(SUM(amount), 0) FROM revenues WHERE fund_id = f.id) AS total_in,
    (SELECT COALESCE(SUM(amount), 0) FROM expenses WHERE fund_id = f.id AND is_approved = 1) AS total_out
FROM financial_funds f;

-- 2. تحليل المساهمات الطلابية (شامل المتبقي)
CREATE OR REPLACE VIEW v_community_contributions_analysis AS
SELECT 
    s.full_name AS student_name,
    gl.name_ar AS grade,
    c.name_ar AS classroom,
    am.name_ar AS month_name,
    ca.amount_value AS expected,
    cc.received_amount AS paid,
    cc.exemption_amount AS exempt,
    (ca.amount_value - cc.received_amount - cc.exemption_amount) AS balance,
    cc.payment_date
FROM community_contributions cc
JOIN student_enrollments se ON cc.enrollment_id = se.id
JOIN students s ON se.student_id = s.id
JOIN classrooms c ON se.classroom_id = c.id
JOIN grade_levels gl ON c.grade_level_id = gl.id
JOIN academic_months am ON cc.month_id = am.id
JOIN lookup_contribution_amounts ca ON cc.required_amount_id = ca.id;
