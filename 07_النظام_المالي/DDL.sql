-- ╔══════════════════════════════════════════════════════════════════════════════╗
-- ║           النظام المالي الموحد المتقدم (Unified Advanced Financial System)    ║
-- ║              School Management System - Finance & Double-Entry                 ║
-- ║                                                                               ║
-- ║  يشمل: [LEGACY] الصناديق، المساهمات، الإيرادات، المصروفات                    ║
-- ║        [ADVANCED] شجرة الحسابات، القيد المزدوج، الفوترة، بوابات الدفع         ║
-- ╚══════════════════════════════════════════════════════════════════════════════╝

-- التاريخ: 2026-03-02
-- الإصدار: 3.0 (Unified — Legacy + Advanced Finance)
-- المهندس المسؤول: عماد الجماعي / فيصل الجماعي
-- المعماري: عماد الجماعي
-- قاعدة البيانات: MySQL 8.0+

-- ╔══════════════════════════════════════════════════════════════════════════════╗
-- ║  تصنيف الأقسام:                                                             ║
-- ║  [LEGACY]   = النظام المالي الأساسي v2.0 (الصناديق والمساهمات)              ║
-- ║  [ADVANCED] = النظام المالي المتقدم v3.0 (القيد المزدوج والفوترة)           ║
-- ║  [BRIDGE]   = جداول/Views تربط النظامين معاً أثناء الترحيل                   ║
-- ╚══════════════════════════════════════════════════════════════════════════════╝


-- ███████████████████████████████████████████████████████████████████████████████
-- ██                                                                           ██
-- ██   [LEGACY] القسم 1: الجداول المرجعية الأساسية (Lookups)                    ██
-- ██   ملاحظة الترحيل: تبقى كما هي — يعتمد عليها النظام الجديد أيضاً           ██
-- ██                                                                           ██
-- ███████████████████████████████████████████████████████████████████████████████

-- [LEGACY] 1.1 أسباب الإعفاء
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

-- [LEGACY] 1.2 جهات/مصادر الإعفاء (Confirmatory Authorities)
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

-- [LEGACY] 1.3 مبالغ المساهمة المقررة (للتوحيد)
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

-- [LEGACY] 1.4 تصنيفات الإيرادات والمصروفات
-- ملاحظة الترحيل: سيتم ربط كل تصنيف بحساب مقابل في chart_of_accounts (عمود coa_account_id)
CREATE TABLE IF NOT EXISTS financial_categories (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name_ar VARCHAR(100) NOT NULL,
    category_type ENUM('REVENUE', 'EXPENSE') NOT NULL,
    code VARCHAR(30) UNIQUE,
    parent_id INT UNSIGNED NULL,
    is_active BOOLEAN DEFAULT TRUE,
    -- [BRIDGE] ربط بشجرة الحسابات الجديدة
    coa_account_id INT UNSIGNED NULL COMMENT '[BRIDGE] الحساب المقابل في chart_of_accounts',
    CONSTRAINT fk_fin_cat_parent FOREIGN KEY (parent_id) REFERENCES financial_categories(id)
    -- ملاحظة: FK لـ coa_account_id تُضاف لاحقاً بعد إنشاء chart_of_accounts
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='تصنيفات المحاسبة [LEGACY + BRIDGE]';

INSERT INTO financial_categories (name_ar, category_type, code) VALUES
-- إيرادات (15 تصنيف)
('المساهمة المجتمعية', 'REVENUE', 'REV_COMMUNITY'),
('رسوم التسجيل والقبول', 'REVENUE', 'REV_REGISTRATION'),
('الرسوم الدراسية (الأقساط)', 'REVENUE', 'REV_TUITION'),
('رسوم النقل المدرسي', 'REVENUE', 'REV_TRANSPORT'),
('رسوم الزي المدرسي', 'REVENUE', 'REV_UNIFORM'),
('رسوم الكتب والقرطاسية', 'REVENUE', 'REV_BOOKS'),
('رسوم الأنشطة والفعاليات', 'REVENUE', 'REV_ACTIVITIES'),
('إيرادات المقصف/الكافتيريا', 'REVENUE', 'REV_CAFETERIA'),
('رسوم الامتحانات', 'REVENUE', 'REV_EXAMS'),
('غرامات التأخير', 'REVENUE', 'REV_LATE_FEE'),
('تبرعات ومنح', 'REVENUE', 'REV_DONATION'),
('إيرادات تأجير المرافق', 'REVENUE', 'REV_FACILITY_RENTAL'),
('رسوم الشهادات والوثائق', 'REVENUE', 'REV_CERTIFICATES'),
('رسوم الدورات التدريبية', 'REVENUE', 'REV_TRAINING'),
('إيرادات متنوعة أخرى', 'REVENUE', 'REV_OTHER'),
-- مصروفات (12 تصنيف)
('رواتب وأجور ومكافآت', 'EXPENSE', 'EXP_SALARY'),
('صيانة وإصلاحات', 'EXPENSE', 'EXP_MAINTENANCE'),
('وقود ومواصلات', 'EXPENSE', 'EXP_FUEL'),
('كهرباء ومياه وخدمات', 'EXPENSE', 'EXP_UTILITIES'),
('إيجارات', 'EXPENSE', 'EXP_RENT'),
('مشتريات وقرطاسية ولوازم', 'EXPENSE', 'EXP_SUPPLIES'),
('أثاث ومعدات وأجهزة', 'EXPENSE', 'EXP_EQUIPMENT'),
('تقنية معلومات وبرمجيات', 'EXPENSE', 'EXP_IT'),
('تدريب وتطوير مهني', 'EXPENSE', 'EXP_TRAINING'),
('طباعة ونسخ وتصوير', 'EXPENSE', 'EXP_PRINTING'),
('ضيافة واحتفالات وفعاليات', 'EXPENSE', 'EXP_EVENTS'),
('نظافة وتعقيم وأمن', 'EXPENSE', 'EXP_CLEANING'),
('نثريات ومصروفات متنوعة', 'EXPENSE', 'EXP_MISC');


-- ███████████████████████████████████████████████████████████████████████████████
-- ██                                                                           ██
-- ██   [LEGACY] القسم 2: الصناديق والمحاسبة العامة                              ██
-- ██   ملاحظة الترحيل: كل صندوق سيُربط بحساب في chart_of_accounts              ██
-- ██                                                                           ██
-- ███████████████████████████████████████████████████████████████████████████████

-- [LEGACY] 2.1 الصناديق المالية
-- ملاحظة الترحيل: current_balance سيُحسب آلياً من journal_entry_lines بعد الترحيل
CREATE TABLE IF NOT EXISTS financial_funds (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name_ar VARCHAR(100) NOT NULL,
    code VARCHAR(30) UNIQUE,
    fund_type ENUM('رئيسي', 'فرعي') DEFAULT 'فرعي',
    current_balance DECIMAL(15,2) DEFAULT 0.00,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    -- [BRIDGE] ربط بشجرة الحسابات الجديدة
    coa_account_id INT UNSIGNED NULL COMMENT '[BRIDGE] الحساب المقابل في chart_of_accounts'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='الصناديق المالية [LEGACY + BRIDGE]';

INSERT INTO financial_funds (name_ar, code, fund_type) VALUES
-- الصناديق الرئيسية
('الصندوق الرئيسي العام', 'MAIN_FUND', 'رئيسي'),
('صندوق الرواتب والأجور', 'PAYROLL_FUND', 'رئيسي'),
-- الصناديق الفرعية (إيرادات مخصصة)
('صندوق المساهمة المجتمعية', 'COMMUNITY_FUND', 'فرعي'),
('صندوق الرسوم الدراسية', 'TUITION_FUND', 'فرعي'),
('صندوق النقل المدرسي', 'TRANSPORT_FUND', 'فرعي'),
('صندوق الأنشطة والفعاليات', 'ACTIVITIES_FUND', 'فرعي'),
('صندوق الصيانة والتشغيل', 'MAINTENANCE_FUND', 'فرعي'),
('صندوق المشتريات واللوازم', 'PROCUREMENT_FUND', 'فرعي'),
('صندوق المقصف/الكافتيريا', 'CAFETERIA_FUND', 'فرعي'),
('صندوق التبرعات والمنح', 'DONATIONS_FUND', 'فرعي'),
('صندوق التطوير والتحسين', 'DEVELOPMENT_FUND', 'فرعي'),
('صندوق الطوارئ والاحتياطي', 'EMERGENCY_FUND', 'فرعي');

-- [LEGACY] 2.2 الإيرادات العامة
-- ملاحظة الترحيل: كل إيراد جديد سيُولّد قيد يومية تلقائياً في journal_entries
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
    -- [BRIDGE] ربط بالقيد اليومي
    journal_entry_id BIGINT UNSIGNED NULL COMMENT '[BRIDGE] القيد اليومي المُولّد تلقائياً',
    FOREIGN KEY (fund_id) REFERENCES financial_funds(id),
    FOREIGN KEY (category_id) REFERENCES financial_categories(id),
    FOREIGN KEY (created_by_user_id) REFERENCES users(id)
    -- ملاحظة: FK لـ journal_entry_id تُضاف لاحقاً بعد إنشاء journal_entries
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='سجل الإيرادات [LEGACY + BRIDGE]';

-- [LEGACY] 2.3 المصروفات العامة
-- ملاحظة الترحيل: كل مصروف جديد سيُولّد قيد يومية تلقائياً
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
    -- [BRIDGE] ربط بالقيد اليومي
    journal_entry_id BIGINT UNSIGNED NULL COMMENT '[BRIDGE] القيد اليومي المُولّد تلقائياً',
    FOREIGN KEY (fund_id) REFERENCES financial_funds(id),
    FOREIGN KEY (category_id) REFERENCES financial_categories(id),
    FOREIGN KEY (approved_by_user_id) REFERENCES users(id),
    FOREIGN KEY (created_by_user_id) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='سجل المصروفات [LEGACY + BRIDGE]';


-- ███████████████████████████████████████████████████████████████████████████████
-- ██                                                                           ██
-- ██   [LEGACY] القسم 3: المساهمة المجتمعية (Detailed Tracking)                 ██
-- ██   ملاحظة الترحيل: ستُربط بالفوترة الجديدة — كل سداد يُولّد قيد مزدوج     ██
-- ██                                                                           ██
-- ███████████████████████████████████████████████████████████████████████████████

-- [LEGACY]
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

    -- [BRIDGE] ربط بالنظام المتقدم
    invoice_id BIGINT UNSIGNED NULL COMMENT '[BRIDGE] الفاتورة المقابلة في student_invoices',
    journal_entry_id BIGINT UNSIGNED NULL COMMENT '[BRIDGE] القيد اليومي المُولّد تلقائياً',
    
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
    -- ملاحظة: FKs لـ invoice_id و journal_entry_id تُضاف لاحقاً
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='المساهمة المجتمعية التفصيلية [LEGACY + BRIDGE]';


-- ███████████████████████████████████████████████████████████████████████████████
-- ██                                                                           ██
-- ██   [LEGACY] القسم 4: نظام الرقابة (Viewers/Audit)                           ██
-- ██   ملاحظة الترحيل: يبقى كما هو — لا يحتاج ترحيل                           ██
-- ██                                                                           ██
-- ███████████████████████████████████████████████████████████████████████████████

-- [LEGACY]
CREATE TABLE IF NOT EXISTS financial_view_logs (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    viewer_name VARCHAR(100),
    viewer_phone VARCHAR(20),
    view_date DATE NOT NULL,
    target_report VARCHAR(100) COMMENT 'ماذا شاهد (مركز مالي، مسددين، إلخ)',
    impression TEXT COMMENT 'ملاحظات المشاهد',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='رصد انطباعات المشاهدين والملاك [LEGACY]';


-- ═══════════════════════════════════════════════════════════════════════════════
-- ═══════════════════════════════════════════════════════════════════════════════
-- ██                                                                           ██
-- ██                    ▼▼▼  بداية النظام المتقدم  ▼▼▼                          ██
-- ██                                                                           ██
-- ═══════════════════════════════════════════════════════════════════════════════
-- ═══════════════════════════════════════════════════════════════════════════════


-- ███████████████████████████████████████████████████████████████████████████████
-- ██                                                                           ██
-- ██   [ADVANCED] القسم 5: دعم الفروع والعملات (Multi-Branch / Multi-Currency)  ██
-- ██                                                                           ██
-- ███████████████████████████████████████████████████████████████████████████████

-- [ADVANCED] 5.1 الفروع
CREATE TABLE IF NOT EXISTS branches (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    code VARCHAR(10) NOT NULL UNIQUE COMMENT 'رمز الفرع (BR01)',
    name_ar VARCHAR(100) NOT NULL,
    name_en VARCHAR(100) NULL,
    address TEXT NULL,
    phone VARCHAR(20) NULL,
    is_headquarters BOOLEAN DEFAULT FALSE COMMENT 'المقر الرئيسي',
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='فروع المدرسة [ADVANCED]';

-- [ADVANCED] 5.2 العملات
CREATE TABLE IF NOT EXISTS currencies (
    id TINYINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    code VARCHAR(3) NOT NULL UNIQUE COMMENT 'ISO 4217 (YER, SAR, USD)',
    name_ar VARCHAR(50) NOT NULL,
    symbol VARCHAR(5) NOT NULL,
    decimal_places TINYINT UNSIGNED DEFAULT 2,
    is_base BOOLEAN DEFAULT FALSE COMMENT 'العملة الأساسية',
    is_active BOOLEAN DEFAULT TRUE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='العملات [ADVANCED]';

INSERT INTO currencies (code, name_ar, symbol, is_base) VALUES
('YER', 'ريال يمني', 'ر.ي', TRUE),
('SAR', 'ريال سعودي', 'ر.س', FALSE),
('USD', 'دولار أمريكي', '$', FALSE);

-- [ADVANCED] 5.3 أسعار الصرف
CREATE TABLE IF NOT EXISTS currency_exchange_rates (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    from_currency_id TINYINT UNSIGNED NOT NULL,
    to_currency_id TINYINT UNSIGNED NOT NULL,
    rate DECIMAL(15,6) NOT NULL COMMENT 'سعر الصرف',
    effective_date DATE NOT NULL,
    source VARCHAR(50) NULL COMMENT 'مصدر السعر (بنك مركزي/سوق)',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uk_rate (from_currency_id, to_currency_id, effective_date),
    FOREIGN KEY (from_currency_id) REFERENCES currencies(id),
    FOREIGN KEY (to_currency_id) REFERENCES currencies(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='أسعار الصرف [ADVANCED]';


-- ███████████████████████████████████████████████████████████████████████████████
-- ██                                                                           ██
-- ██   [ADVANCED] القسم 6: السنة المالية وشجرة الحسابات (CoA)                   ██
-- ██                                                                           ██
-- ███████████████████████████████████████████████████████████████████████████████

-- [ADVANCED] 6.1 السنوات المالية
CREATE TABLE IF NOT EXISTS fiscal_years (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name_ar VARCHAR(50) NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    academic_year_id INT UNSIGNED NULL COMMENT 'ربط بالعام الدراسي',
    is_closed BOOLEAN DEFAULT FALSE COMMENT 'مقفلة — لا تقبل قيود',
    closed_at TIMESTAMP NULL,
    closed_by_user_id INT UNSIGNED NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uk_fiscal_dates (start_date, end_date),
    CHECK (end_date > start_date),
    FOREIGN KEY (academic_year_id) REFERENCES academic_years(id),
    FOREIGN KEY (closed_by_user_id) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='السنوات المالية [ADVANCED]';

-- [ADVANCED] 6.1.1 الفترات المالية (Financial Periods) — إقفال شهري/ربعي
-- ═══ الفجوة رقم 1: إقفال الفترات المالية ═══
CREATE TABLE IF NOT EXISTS fiscal_periods (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    fiscal_year_id INT UNSIGNED NOT NULL,
    period_number TINYINT UNSIGNED NOT NULL COMMENT 'رقم الفترة (1-12 شهري، 1-4 ربعي)',
    name_ar VARCHAR(50) NOT NULL COMMENT 'مثال: يناير 2026، الربع الأول',
    period_type ENUM('MONTHLY','QUARTERLY','CUSTOM') NOT NULL DEFAULT 'MONTHLY',
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    status ENUM('OPEN','CLOSING','CLOSED','REOPENED') NOT NULL DEFAULT 'OPEN'
        COMMENT 'OPEN=يقبل قيود، CLOSING=قيد المراجعة، CLOSED=مقفل نهائياً، REOPENED=أعيد فتحه مؤقتاً',
    -- بيانات الإقفال
    closed_at TIMESTAMP NULL,
    closed_by_user_id INT UNSIGNED NULL,
    close_notes TEXT NULL COMMENT 'ملاحظات الإقفال',
    -- بيانات إعادة الفتح (حالة استثنائية)
    reopened_at TIMESTAMP NULL,
    reopened_by_user_id INT UNSIGNED NULL,
    reopen_reason TEXT NULL COMMENT 'سبب إعادة الفتح — إلزامي',
    reopen_deadline DATE NULL COMMENT 'موعد الإغلاق المؤقت بعد إعادة الفتح',
    -- التدقيق
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NULL ON UPDATE CURRENT_TIMESTAMP,
    -- القيود
    CHECK (end_date > start_date),
    UNIQUE KEY uk_period (fiscal_year_id, period_number),
    INDEX idx_status (status),
    INDEX idx_dates (start_date, end_date),
    FOREIGN KEY (fiscal_year_id) REFERENCES fiscal_years(id) ON DELETE RESTRICT,
    FOREIGN KEY (closed_by_user_id) REFERENCES users(id),
    FOREIGN KEY (reopened_by_user_id) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='الفترات المالية — التحكم بإقفال شهري/ربعي [ADVANCED - Gap Fix #1]';

-- [ADVANCED] 6.2 شجرة الحسابات — Chart of Accounts
CREATE TABLE IF NOT EXISTS chart_of_accounts (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    account_code VARCHAR(20) NOT NULL UNIQUE COMMENT 'رمز الحساب (1000, 1100, 1101)',
    name_ar VARCHAR(150) NOT NULL,
    name_en VARCHAR(150) NULL,
    account_type ENUM('ASSET','LIABILITY','EQUITY','REVENUE','EXPENSE') NOT NULL,
    parent_id INT UNSIGNED NULL COMMENT 'الحساب الأب (شجرة)',
    hierarchy_level TINYINT UNSIGNED NOT NULL DEFAULT 1 COMMENT 'مستوى التفرع',
    is_header BOOLEAN DEFAULT FALSE COMMENT 'حساب رئيسي فقط (لا يقبل قيود)',
    is_bank_account BOOLEAN DEFAULT FALSE,
    default_currency_id TINYINT UNSIGNED NULL,
    branch_id INT UNSIGNED NULL COMMENT 'NULL = مشترك بين الفروع',
    normal_balance ENUM('DEBIT','CREDIT') NOT NULL COMMENT 'الطبيعة الطبيعية',
    current_balance DECIMAL(18,2) DEFAULT 0.00 COMMENT 'رصيد محتسب (cacheable)',
    is_system BOOLEAN DEFAULT FALSE COMMENT 'حساب نظامي لا يُحذف',
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NULL ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_parent (parent_id),
    INDEX idx_type (account_type),
    INDEX idx_code (account_code),
    FOREIGN KEY (parent_id) REFERENCES chart_of_accounts(id) ON DELETE RESTRICT,
    FOREIGN KEY (default_currency_id) REFERENCES currencies(id),
    FOREIGN KEY (branch_id) REFERENCES branches(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='شجرة الحسابات [ADVANCED]';

-- [ADVANCED] بذور شجرة الحسابات الافتراضية
INSERT INTO chart_of_accounts (account_code, name_ar, account_type, parent_id, hierarchy_level, is_header, normal_balance, is_system) VALUES
-- ── الأصول ──
('1000', 'الأصول', 'ASSET', NULL, 1, TRUE, 'DEBIT', TRUE),
('1100', 'الأصول المتداولة', 'ASSET', 1, 2, TRUE, 'DEBIT', TRUE),
('1101', 'النقدية والبنوك', 'ASSET', 2, 3, FALSE, 'DEBIT', TRUE),
('1102', 'بوابات الدفع الإلكتروني', 'ASSET', 2, 3, FALSE, 'DEBIT', TRUE),
('1103', 'الذمم المدينة — أولياء الأمور', 'ASSET', 2, 3, FALSE, 'DEBIT', TRUE),
('1104', 'الذمم المدينة — موظفون', 'ASSET', 2, 3, FALSE, 'DEBIT', TRUE),
('1200', 'الأصول الثابتة', 'ASSET', 1, 2, TRUE, 'DEBIT', TRUE),
('1201', 'الأثاث والمعدات', 'ASSET', 7, 3, FALSE, 'DEBIT', TRUE),
('1202', 'وسائل النقل (الباصات)', 'ASSET', 7, 3, FALSE, 'DEBIT', TRUE),
('1203', 'مجمع الإهلاك', 'ASSET', 7, 3, FALSE, 'CREDIT', TRUE),
-- ── الخصوم ──
('2000', 'الخصوم', 'LIABILITY', NULL, 1, TRUE, 'CREDIT', TRUE),
('2100', 'الخصوم المتداولة', 'LIABILITY', 11, 2, TRUE, 'CREDIT', TRUE),
('2101', 'الذمم الدائنة — الموردون', 'LIABILITY', 12, 3, FALSE, 'CREDIT', TRUE),
('2102', 'الرواتب المستحقة', 'LIABILITY', 12, 3, FALSE, 'CREDIT', TRUE),
('2103', 'مستحقات الاسترداد — أولياء أمور', 'LIABILITY', 12, 3, FALSE, 'CREDIT', TRUE),
('2104', 'ضريبة القيمة المضافة المستحقة', 'LIABILITY', 12, 3, FALSE, 'CREDIT', TRUE),
('2105', 'إيرادات مؤجلة (رسوم مقدمة)', 'LIABILITY', 12, 3, FALSE, 'CREDIT', TRUE),
-- ── حقوق الملكية ──
('3000', 'حقوق الملكية', 'EQUITY', NULL, 1, TRUE, 'CREDIT', TRUE),
('3001', 'رأس المال', 'EQUITY', 18, 2, FALSE, 'CREDIT', TRUE),
('3002', 'الأرباح المحتجزة', 'EQUITY', 18, 2, FALSE, 'CREDIT', TRUE),
-- ── الإيرادات ──
('4000', 'الإيرادات', 'REVENUE', NULL, 1, TRUE, 'CREDIT', TRUE),
('4001', 'إيراد الرسوم الدراسية', 'REVENUE', 21, 2, FALSE, 'CREDIT', TRUE),
('4002', 'إيراد المساهمة المجتمعية', 'REVENUE', 21, 2, FALSE, 'CREDIT', TRUE),
('4003', 'إيراد رسوم النقل', 'REVENUE', 21, 2, FALSE, 'CREDIT', TRUE),
('4004', 'إيراد رسوم الزي المدرسي', 'REVENUE', 21, 2, FALSE, 'CREDIT', TRUE),
('4005', 'إيراد رسوم التسجيل', 'REVENUE', 21, 2, FALSE, 'CREDIT', TRUE),
('4006', 'إيرادات أخرى / تبرعات', 'REVENUE', 21, 2, FALSE, 'CREDIT', TRUE),
('4007', 'إيراد الغرامات والتأخير', 'REVENUE', 21, 2, FALSE, 'CREDIT', TRUE),
-- ── المصروفات ──
('5000', 'المصروفات', 'EXPENSE', NULL, 1, TRUE, 'DEBIT', TRUE),
('5001', 'مصروف الرواتب والأجور', 'EXPENSE', 29, 2, FALSE, 'DEBIT', TRUE),
('5002', 'مصروف الصيانة', 'EXPENSE', 29, 2, FALSE, 'DEBIT', TRUE),
('5003', 'مصروف الوقود والنقل', 'EXPENSE', 29, 2, FALSE, 'DEBIT', TRUE),
('5004', 'مصروف المشتريات والمخازن', 'EXPENSE', 29, 2, FALSE, 'DEBIT', TRUE),
('5005', 'مصروف الإهلاك', 'EXPENSE', 29, 2, FALSE, 'DEBIT', TRUE),
('5006', 'مصروفات إدارية عامة', 'EXPENSE', 29, 2, FALSE, 'DEBIT', TRUE),
('5007', 'مصروف خصومات (إخوة/إعفاءات)', 'EXPENSE', 29, 2, FALSE, 'DEBIT', TRUE);


-- ███████████████████████████████████████████████████████████████████████████████
-- ██                                                                           ██
-- ██   [ADVANCED] القسم 7: القيد المزدوج (Double-Entry Journal System)          ██
-- ██                                                                           ██
-- ███████████████████████████████████████████████████████████████████████████████

-- [ADVANCED] 7.1 القيود اليومية — رأس القيد
CREATE TABLE IF NOT EXISTS journal_entries (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    entry_number VARCHAR(30) NOT NULL UNIQUE COMMENT 'رقم القيد (JE-2026-00001)',
    entry_date DATE NOT NULL,
    fiscal_year_id INT UNSIGNED NOT NULL,
    fiscal_period_id INT UNSIGNED NULL COMMENT '[Gap Fix #1] الفترة المالية — للتحقق من الإقفال',
    branch_id INT UNSIGNED NULL,
    description TEXT NOT NULL COMMENT 'البيان',
    reference_type VARCHAR(30) NULL COMMENT 'PAYMENT/INVOICE/SALARY/PURCHASE/CONTRIBUTION/MANUAL',
    reference_id BIGINT UNSIGNED NULL COMMENT 'معرف المصدر',
    status ENUM('DRAFT','APPROVED','POSTED','REVERSED') NOT NULL DEFAULT 'DRAFT',
    total_debit DECIMAL(18,2) NOT NULL DEFAULT 0.00,
    total_credit DECIMAL(18,2) NOT NULL DEFAULT 0.00,
    currency_id TINYINT UNSIGNED NULL,
    exchange_rate DECIMAL(10,6) DEFAULT 1.000000 COMMENT '[Gap Fix #3] دقة 6 خانات عشرية',
    -- دورة الاعتماد (Draft → Approved → Posted)
    created_by_user_id INT UNSIGNED NOT NULL,
    approved_by_user_id INT UNSIGNED NULL,
    approved_at TIMESTAMP NULL,
    posted_by_user_id INT UNSIGNED NULL,
    posted_at TIMESTAMP NULL,
    -- العكس (Reversals)
    is_reversal BOOLEAN DEFAULT FALSE,
    reversal_of_id BIGINT UNSIGNED NULL COMMENT 'القيد الأصلي المعكوس',
    reversed_by_id BIGINT UNSIGNED NULL COMMENT 'القيد العاكس لهذا القيد',
    reversal_reason TEXT NULL COMMENT 'سبب العكس — إلزامي عند العكس',
    -- التدقيق
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NULL ON UPDATE CURRENT_TIMESTAMP,
    -- ✅ القيد الذهبي: المدين = الدائن دائماً
    CHECK (total_debit = total_credit),
    INDEX idx_date (entry_date),
    INDEX idx_status (status),
    INDEX idx_ref (reference_type, reference_id),
    INDEX idx_fiscal (fiscal_year_id),
    INDEX idx_period (fiscal_period_id),
    FOREIGN KEY (fiscal_year_id) REFERENCES fiscal_years(id) ON DELETE RESTRICT,
    FOREIGN KEY (fiscal_period_id) REFERENCES fiscal_periods(id) ON DELETE RESTRICT,
    FOREIGN KEY (branch_id) REFERENCES branches(id),
    FOREIGN KEY (currency_id) REFERENCES currencies(id),
    FOREIGN KEY (created_by_user_id) REFERENCES users(id),
    FOREIGN KEY (approved_by_user_id) REFERENCES users(id),
    FOREIGN KEY (posted_by_user_id) REFERENCES users(id),
    FOREIGN KEY (reversal_of_id) REFERENCES journal_entries(id) ON DELETE RESTRICT,
    FOREIGN KEY (reversed_by_id) REFERENCES journal_entries(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='القيود اليومية — رأس القيد المزدوج [ADVANCED]';

-- [ADVANCED] 7.2 بنود القيد اليومي — سطور المدين والدائن
CREATE TABLE IF NOT EXISTS journal_entry_lines (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    journal_entry_id BIGINT UNSIGNED NOT NULL,
    line_number SMALLINT UNSIGNED NOT NULL,
    account_id INT UNSIGNED NOT NULL,
    description VARCHAR(255) NULL COMMENT 'بيان السطر',
    debit_amount DECIMAL(18,2) NOT NULL DEFAULT 0.00,
    credit_amount DECIMAL(18,2) NOT NULL DEFAULT 0.00,
    -- أبعاد تحليلية (Analytical Dimensions)
    cost_center VARCHAR(50) NULL COMMENT 'مركز تكلفة',
    student_id INT UNSIGNED NULL COMMENT 'طالب مرتبط',
    employee_id INT UNSIGNED NULL COMMENT 'موظف مرتبط',
    branch_id INT UNSIGNED NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CHECK (debit_amount >= 0 AND credit_amount >= 0),
    CHECK (NOT (debit_amount > 0 AND credit_amount > 0)),
    UNIQUE KEY uk_line (journal_entry_id, line_number),
    INDEX idx_account (account_id),
    INDEX idx_student (student_id),
    INDEX idx_employee (employee_id),
    FOREIGN KEY (journal_entry_id) REFERENCES journal_entries(id) ON DELETE CASCADE,
    FOREIGN KEY (account_id) REFERENCES chart_of_accounts(id) ON DELETE RESTRICT,
    FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE SET NULL,
    FOREIGN KEY (employee_id) REFERENCES employees(id) ON DELETE SET NULL,
    FOREIGN KEY (branch_id) REFERENCES branches(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='بنود القيد اليومي — سطور المدين والدائن [ADVANCED]';


-- ███████████████████████████████████████████████████████████████████████████████
-- ██                                                                           ██
-- ██   [ADVANCED] القسم 8: الفوترة والرسوم (Billing & Fees)                     ██
-- ██                                                                           ██
-- ███████████████████████████████████████████████████████████████████████████████

-- [ADVANCED] 8.1 هياكل الرسوم
CREATE TABLE IF NOT EXISTS fee_structures (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name_ar VARCHAR(100) NOT NULL,
    academic_year_id INT UNSIGNED NOT NULL,
    grade_level_id INT UNSIGNED NULL COMMENT 'NULL = كل المراحل',
    fee_type ENUM('TUITION','TRANSPORT','UNIFORM','REGISTRATION','ACTIVITY','PENALTY','OTHER') NOT NULL,
    amount DECIMAL(15,2) NOT NULL,
    currency_id TINYINT UNSIGNED NULL,
    vat_rate DECIMAL(5,2) DEFAULT 0.00 COMMENT 'نسبة الضريبة %',
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_year (academic_year_id),
    INDEX idx_type (fee_type),
    FOREIGN KEY (academic_year_id) REFERENCES academic_years(id),
    FOREIGN KEY (grade_level_id) REFERENCES grade_levels(id),
    FOREIGN KEY (currency_id) REFERENCES currencies(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='هياكل الرسوم — تعريف المبالغ حسب المرحلة والنوع [ADVANCED]';

-- [ADVANCED] 8.2 قواعد الخصم الآلي (Sibling Discount Engine)
-- ═══ الفجوة رقم 4: التوجيه المحاسبي للخصومات ═══
CREATE TABLE IF NOT EXISTS discount_rules (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name_ar VARCHAR(100) NOT NULL,
    discount_type ENUM('SIBLING','ORPHAN','EMPLOYEE_CHILD','SCHOLARSHIP','HARDSHIP','CUSTOM') NOT NULL,
    calculation_method ENUM('PERCENTAGE','FIXED') NOT NULL,
    value DECIMAL(10,2) NOT NULL COMMENT 'نسبة مئوية أو مبلغ ثابت',
    applies_to_fee_type ENUM('TUITION','TRANSPORT','ALL') DEFAULT 'TUITION',
    sibling_order_from TINYINT UNSIGNED NULL COMMENT 'يبدأ من الأخ رقم (لخصم الإخوة)',
    max_discount_percentage DECIMAL(5,2) DEFAULT 100.00,
    requires_approval BOOLEAN DEFAULT FALSE,
    -- [Gap Fix #4] التوجيه المحاسبي للخصم
    discount_gl_account_id INT UNSIGNED NULL
        COMMENT '[Gap Fix #4] حساب مصروف الخصم في CoA (مدين: 5007 مصروف خصومات)',
    contra_gl_account_id INT UNSIGNED NULL
        COMMENT '[Gap Fix #4] الحساب المقابل (دائن: 1103 ذمم مدينة أولياء أمور)',
    academic_year_id INT UNSIGNED NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (academic_year_id) REFERENCES academic_years(id),
    FOREIGN KEY (discount_gl_account_id) REFERENCES chart_of_accounts(id) ON DELETE SET NULL,
    FOREIGN KEY (contra_gl_account_id) REFERENCES chart_of_accounts(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='قواعد الخصم الآلي — يشمل خصم الإخوة + التوجيه المحاسبي [ADVANCED - Gap Fix #4]';

-- [ADVANCED] 8.3 فواتير الطلاب
CREATE TABLE IF NOT EXISTS student_invoices (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    invoice_number VARCHAR(30) NOT NULL UNIQUE COMMENT 'INV-2026-00001',
    enrollment_id INT UNSIGNED NOT NULL,
    academic_year_id INT UNSIGNED NOT NULL,
    branch_id INT UNSIGNED NULL,
    invoice_date DATE NOT NULL,
    due_date DATE NOT NULL,
    subtotal DECIMAL(15,2) NOT NULL DEFAULT 0.00,
    discount_amount DECIMAL(15,2) DEFAULT 0.00,
    vat_amount DECIMAL(15,2) DEFAULT 0.00,
    total_amount DECIMAL(15,2) NOT NULL DEFAULT 0.00 COMMENT 'subtotal - discount + vat',
    paid_amount DECIMAL(15,2) DEFAULT 0.00,
    balance_due DECIMAL(15,2) GENERATED ALWAYS AS (total_amount - paid_amount) STORED,
    currency_id TINYINT UNSIGNED NULL,
    status ENUM('DRAFT','ISSUED','PARTIAL','PAID','CANCELLED','CREDITED') DEFAULT 'DRAFT',
    notes TEXT NULL,
    created_by_user_id INT UNSIGNED NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NULL ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_enrollment (enrollment_id),
    INDEX idx_status (status),
    INDEX idx_date (invoice_date),
    FOREIGN KEY (enrollment_id) REFERENCES student_enrollments(id) ON DELETE RESTRICT,
    FOREIGN KEY (academic_year_id) REFERENCES academic_years(id),
    FOREIGN KEY (branch_id) REFERENCES branches(id),
    FOREIGN KEY (currency_id) REFERENCES currencies(id),
    FOREIGN KEY (created_by_user_id) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='فواتير الطلاب [ADVANCED]';

-- [ADVANCED] 8.4 بنود الفاتورة
-- ═══ الفجوات رقم 2 + 4: ربط الكود الضريبي + حساب الخصم ═══
CREATE TABLE IF NOT EXISTS invoice_line_items (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    invoice_id BIGINT UNSIGNED NOT NULL,
    fee_structure_id INT UNSIGNED NULL,
    description_ar VARCHAR(200) NOT NULL,
    fee_type ENUM('TUITION','TRANSPORT','UNIFORM','REGISTRATION','ACTIVITY','PENALTY','OTHER') NOT NULL,
    quantity DECIMAL(10,2) DEFAULT 1.00,
    unit_price DECIMAL(15,2) NOT NULL,
    -- الخصم + التوجيه المحاسبي
    discount_amount DECIMAL(15,2) DEFAULT 0.00,
    discount_rule_id INT UNSIGNED NULL,
    discount_gl_account_id INT UNSIGNED NULL
        COMMENT '[Gap Fix #4] حساب مصروف الخصم (مدين) — يُورث من discount_rules أو يُحدد يدوياً',
    -- الضريبة + الكود الضريبي
    tax_code_id TINYINT UNSIGNED NULL
        COMMENT '[Gap Fix #2] كود الضريبة — يحدد النسبة وحساب GL تلقائياً',
    vat_rate DECIMAL(5,2) DEFAULT 0.00,
    vat_amount DECIMAL(15,2) DEFAULT 0.00,
    line_total DECIMAL(15,2) NOT NULL,
    account_id INT UNSIGNED NULL COMMENT 'حساب الإيراد المرتبط في CoA',
    FOREIGN KEY (invoice_id) REFERENCES student_invoices(id) ON DELETE CASCADE,
    FOREIGN KEY (fee_structure_id) REFERENCES fee_structures(id),
    FOREIGN KEY (discount_rule_id) REFERENCES discount_rules(id),
    FOREIGN KEY (discount_gl_account_id) REFERENCES chart_of_accounts(id) ON DELETE SET NULL,
    FOREIGN KEY (account_id) REFERENCES chart_of_accounts(id)
    -- ملاحظة: FK لـ tax_code_id تُضاف بعد إنشاء جدول fin_tax_codes
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='بنود الفاتورة — مع ربط ضريبي وتوجيه خصومات [ADVANCED - Gap Fix #2 & #4]';

-- [ADVANCED] 8.5 أقساط الفاتورة — خطط التقسيط
CREATE TABLE IF NOT EXISTS invoice_installments (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    invoice_id BIGINT UNSIGNED NOT NULL,
    installment_number TINYINT UNSIGNED NOT NULL,
    due_date DATE NOT NULL,
    amount DECIMAL(15,2) NOT NULL,
    paid_amount DECIMAL(15,2) DEFAULT 0.00,
    payment_date DATE NULL,
    status ENUM('PENDING','PARTIAL','PAID','OVERDUE','CANCELLED') DEFAULT 'PENDING',
    late_fee DECIMAL(10,2) DEFAULT 0.00,
    notes VARCHAR(255) NULL,
    UNIQUE KEY uk_installment (invoice_id, installment_number),
    INDEX idx_due (due_date),
    INDEX idx_status (status),
    FOREIGN KEY (invoice_id) REFERENCES student_invoices(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='أقساط الفاتورة — خطط التقسيط [ADVANCED]';


-- ███████████████████████████████████████████████████████████████████████████████
-- ██                                                                           ██
-- ██   [ADVANCED] القسم 9: بوابات الدفع والتسويات البنكية                       ██
-- ██                                                                           ██
-- ███████████████████████████████████████████████████████████████████████████████

-- [ADVANCED] 9.1 بوابات الدفع
CREATE TABLE IF NOT EXISTS payment_gateways (
    id TINYINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name_ar VARCHAR(50) NOT NULL,
    name_en VARCHAR(50) NOT NULL,
    provider_code VARCHAR(20) NOT NULL UNIQUE COMMENT 'STRIPE/MOYASAR/TAP/MANUAL',
    gateway_type ENUM('ONLINE','OFFLINE') NOT NULL,
    api_endpoint VARCHAR(255) NULL,
    merchant_id VARCHAR(100) NULL,
    settlement_account_id INT UNSIGNED NULL COMMENT 'حساب بنك التسوية في CoA',
    is_active BOOLEAN DEFAULT TRUE,
    FOREIGN KEY (settlement_account_id) REFERENCES chart_of_accounts(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='بوابات الدفع [ADVANCED]';

INSERT INTO payment_gateways (name_ar, name_en, provider_code, gateway_type) VALUES
('نقدي', 'Cash', 'CASH', 'OFFLINE'),
('تحويل بنكي', 'Bank Transfer', 'BANK_TRANSFER', 'OFFLINE'),
('بوابة إلكترونية', 'Online Gateway', 'ONLINE_GW', 'ONLINE');

-- [ADVANCED] 9.2 معاملات الدفع
CREATE TABLE IF NOT EXISTS payment_transactions (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    transaction_number VARCHAR(30) NOT NULL UNIQUE COMMENT 'TXN-2026-00001',
    gateway_id TINYINT UNSIGNED NOT NULL,
    gateway_transaction_id VARCHAR(100) NULL COMMENT 'معرف البوابة الخارجي',
    invoice_id BIGINT UNSIGNED NULL,
    installment_id BIGINT UNSIGNED NULL,
    enrollment_id INT UNSIGNED NULL,
    amount DECIMAL(15,2) NOT NULL,
    currency_id TINYINT UNSIGNED NULL,
    payment_method ENUM('CASH','CARD','BANK_TRANSFER','MOBILE_WALLET','CHEQUE') NOT NULL,
    status ENUM('PENDING','COMPLETED','FAILED','REFUNDED','CANCELLED') DEFAULT 'PENDING',
    paid_at TIMESTAMP NULL,
    receipt_number VARCHAR(50) NULL,
    payer_name VARCHAR(150) NULL,
    payer_phone VARCHAR(20) NULL,
    journal_entry_id BIGINT UNSIGNED NULL COMMENT 'القيد المحاسبي المرتبط',
    notes TEXT NULL,
    created_by_user_id INT UNSIGNED NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NULL ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_gateway (gateway_id),
    INDEX idx_invoice (invoice_id),
    INDEX idx_status (status),
    INDEX idx_date (paid_at),
    FOREIGN KEY (gateway_id) REFERENCES payment_gateways(id),
    FOREIGN KEY (invoice_id) REFERENCES student_invoices(id) ON DELETE RESTRICT,
    FOREIGN KEY (installment_id) REFERENCES invoice_installments(id),
    FOREIGN KEY (enrollment_id) REFERENCES student_enrollments(id),
    FOREIGN KEY (currency_id) REFERENCES currencies(id),
    FOREIGN KEY (journal_entry_id) REFERENCES journal_entries(id),
    FOREIGN KEY (created_by_user_id) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='معاملات الدفع [ADVANCED]';

-- [ADVANCED] 9.3 التسويات البنكية
CREATE TABLE IF NOT EXISTS bank_reconciliation (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    bank_account_id INT UNSIGNED NOT NULL COMMENT 'حساب البنك في CoA',
    statement_date DATE NOT NULL,
    statement_reference VARCHAR(50) NULL,
    bank_balance DECIMAL(18,2) NOT NULL COMMENT 'رصيد كشف البنك',
    book_balance DECIMAL(18,2) NOT NULL COMMENT 'رصيد الدفاتر',
    difference DECIMAL(18,2) GENERATED ALWAYS AS (bank_balance - book_balance) STORED,
    status ENUM('OPEN','IN_PROGRESS','RECONCILED') DEFAULT 'OPEN',
    reconciled_by_user_id INT UNSIGNED NULL,
    reconciled_at TIMESTAMP NULL,
    notes TEXT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_bank (bank_account_id),
    INDEX idx_date (statement_date),
    FOREIGN KEY (bank_account_id) REFERENCES chart_of_accounts(id),
    FOREIGN KEY (reconciled_by_user_id) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='التسويات البنكية [ADVANCED]';

-- [ADVANCED] 9.4 بنود التسوية البنكية
CREATE TABLE IF NOT EXISTS reconciliation_items (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    reconciliation_id BIGINT UNSIGNED NOT NULL,
    transaction_id BIGINT UNSIGNED NULL COMMENT 'معاملة الدفع المطابقة',
    journal_entry_id BIGINT UNSIGNED NULL,
    bank_reference VARCHAR(100) NULL,
    amount DECIMAL(18,2) NOT NULL,
    item_type ENUM('MATCHED','UNMATCHED_BANK','UNMATCHED_BOOK') NOT NULL,
    matched_at TIMESTAMP NULL,
    FOREIGN KEY (reconciliation_id) REFERENCES bank_reconciliation(id) ON DELETE CASCADE,
    FOREIGN KEY (transaction_id) REFERENCES payment_transactions(id),
    FOREIGN KEY (journal_entry_id) REFERENCES journal_entries(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='بنود التسوية البنكية [ADVANCED]';


-- ███████████████████████████████████████████████████████████████████████████████
-- ██                                                                           ██
-- ██   [ADVANCED] القسم 10: محرك الضرائب المتقدم (Tax Engine)                    ██
-- ██   ═══ الفجوة رقم 2: محرك الضرائب المتقدم ═══                              ██
-- ██                                                                           ██
-- ███████████████████████████████████████████████████████████████████████████████

-- [ADVANCED] 10.1 أكواد الضرائب (يحل محل tax_configurations البسيط)
CREATE TABLE IF NOT EXISTS fin_tax_codes (
    id TINYINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    tax_code VARCHAR(10) NOT NULL UNIQUE COMMENT 'رمز الضريبة (VAT15, VAT0, EXEMPT)',
    tax_name_ar VARCHAR(80) NOT NULL COMMENT 'مثال: ضريبة القيمة المضافة 15%',
    tax_name_en VARCHAR(80) NULL,
    rate DECIMAL(5,2) NOT NULL COMMENT 'النسبة المئوية (15.00, 5.00, 0.00)',
    tax_type ENUM('OUTPUT','INPUT','EXEMPT','ZERO_RATED') NOT NULL
        COMMENT 'OUTPUT=ضريبة مخرجات (مبيعات), INPUT=ضريبة مدخلات (مشتريات)',
    is_inclusive BOOLEAN DEFAULT FALSE COMMENT 'مشمول في السعر؟',
    -- التوجيه المحاسبي — حسابات GL للقيد المزدوج
    output_gl_account_id INT UNSIGNED NULL
        COMMENT 'حساب ضريبة المخرجات في CoA (2104 — خصوم: ضريبة مستحقة)',
    input_gl_account_id INT UNSIGNED NULL
        COMMENT 'حساب ضريبة المدخلات في CoA (1105 — أصول: ضريبة مسترداة)',
    -- الفعالية
    effective_from DATE NOT NULL,
    effective_to DATE NULL COMMENT 'NULL = ساري حتى إشعار آخر',
    is_active BOOLEAN DEFAULT TRUE,
    -- التدقيق
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NULL ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (output_gl_account_id) REFERENCES chart_of_accounts(id) ON DELETE SET NULL,
    FOREIGN KEY (input_gl_account_id) REFERENCES chart_of_accounts(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='أكواد الضرائب — محرك VAT متقدم مع توجيه GL [ADVANCED - Gap Fix #2]';

INSERT INTO fin_tax_codes (tax_code, tax_name_ar, rate, tax_type, effective_from) VALUES
('VAT15', 'ضريبة القيمة المضافة 15%', 15.00, 'OUTPUT', '2026-01-01'),
('VAT5', 'ضريبة القيمة المضافة 5%', 5.00, 'OUTPUT', '2026-01-01'),
('VAT0', 'نسبة صفرية', 0.00, 'ZERO_RATED', '2026-01-01'),
('EXEMPT', 'معفى من الضريبة', 0.00, 'EXEMPT', '2026-01-01'),
('VAT_IN15', 'ضريبة مدخلات 15%', 15.00, 'INPUT', '2026-01-01');

-- [ADVANCED] 10.2 ربط أكواد الضرائب ببنود الفواتير
ALTER TABLE invoice_line_items
    ADD CONSTRAINT fk_invoice_line_tax_code FOREIGN KEY (tax_code_id)
    REFERENCES fin_tax_codes(id) ON DELETE SET NULL;


-- ███████████████████████████████████████████████████████████████████████████████
-- ██                                                                           ██
-- ██   [BRIDGE] القسم 11: ربط الجداول القديمة بالجديدة (Foreign Keys)           ██
-- ██   يُنفذ بعد إنشاء جميع الجداول أعلاه                                      ██
-- ██                                                                           ██
-- ███████████████████████████████████████████████████████████████████████████████

-- [BRIDGE] ربط التصنيفات المالية بشجرة الحسابات
ALTER TABLE financial_categories
    ADD CONSTRAINT fk_fincat_coa FOREIGN KEY (coa_account_id) 
    REFERENCES chart_of_accounts(id) ON DELETE SET NULL;

-- [BRIDGE] ربط الصناديق بشجرة الحسابات
ALTER TABLE financial_funds
    ADD CONSTRAINT fk_fund_coa FOREIGN KEY (coa_account_id) 
    REFERENCES chart_of_accounts(id) ON DELETE SET NULL;

-- [BRIDGE] ربط الإيرادات بالقيود اليومية
ALTER TABLE revenues
    ADD CONSTRAINT fk_revenue_je FOREIGN KEY (journal_entry_id) 
    REFERENCES journal_entries(id) ON DELETE SET NULL;

-- [BRIDGE] ربط المصروفات بالقيود اليومية
ALTER TABLE expenses
    ADD CONSTRAINT fk_expense_je FOREIGN KEY (journal_entry_id) 
    REFERENCES journal_entries(id) ON DELETE SET NULL;

-- [BRIDGE] ربط المساهمات بالفواتير والقيود
ALTER TABLE community_contributions
    ADD CONSTRAINT fk_contrib_invoice FOREIGN KEY (invoice_id) 
    REFERENCES student_invoices(id) ON DELETE SET NULL;

ALTER TABLE community_contributions
    ADD CONSTRAINT fk_contrib_je FOREIGN KEY (journal_entry_id) 
    REFERENCES journal_entries(id) ON DELETE SET NULL;


-- ███████████████████████████████████████████████████████████████████████████████
-- ██                                                                           ██
-- ██   القسم 12: الرؤى والتقارير الموحدة (Views)                                ██
-- ██                                                                           ██
-- ███████████████████████████████████████████████████████████████████████████████

-- [LEGACY] تقرير الأرصدة الشامل (محدّث)
CREATE OR REPLACE VIEW v_unified_financial_status AS
SELECT 
    f.name_ar AS fund_name,
    f.current_balance,
    (SELECT COALESCE(SUM(amount), 0) FROM revenues WHERE fund_id = f.id) AS total_in,
    (SELECT COALESCE(SUM(amount), 0) FROM expenses WHERE fund_id = f.id AND is_approved = 1) AS total_out,
    coa.account_code AS coa_code,
    coa.name_ar AS coa_account_name
FROM financial_funds f
LEFT JOIN chart_of_accounts coa ON f.coa_account_id = coa.id;

-- [LEGACY] تحليل المساهمات الطلابية (شامل المتبقي)
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
    cc.payment_date,
    cc.invoice_id AS linked_invoice_id,
    cc.journal_entry_id AS linked_je_id
FROM community_contributions cc
JOIN student_enrollments se ON cc.enrollment_id = se.id
JOIN students s ON se.student_id = s.id
JOIN classrooms c ON se.classroom_id = c.id
JOIN grade_levels gl ON c.grade_level_id = gl.id
JOIN academic_months am ON cc.month_id = am.id
JOIN lookup_contribution_amounts ca ON cc.required_amount_id = ca.id;

-- [ADVANCED] دفتر الأستاذ العام (General Ledger)
CREATE OR REPLACE VIEW v_general_ledger AS
SELECT
    coa.account_code,
    coa.name_ar AS account_name,
    coa.account_type,
    je.entry_date,
    je.entry_number,
    je.description AS entry_description,
    jel.description AS line_description,
    jel.debit_amount,
    jel.credit_amount,
    je.status,
    je.reference_type,
    fp.name_ar AS fiscal_period_name,
    fp.status AS period_status,
    b.name_ar AS branch_name
FROM journal_entry_lines jel
JOIN journal_entries je ON jel.journal_entry_id = je.id
JOIN chart_of_accounts coa ON jel.account_id = coa.id
LEFT JOIN fiscal_periods fp ON je.fiscal_period_id = fp.id
LEFT JOIN branches b ON je.branch_id = b.id
WHERE je.status = 'POSTED';

-- [ADVANCED] ميزان المراجعة (Trial Balance)
CREATE OR REPLACE VIEW v_trial_balance AS
SELECT
    coa.account_code,
    coa.name_ar AS account_name,
    coa.account_type,
    coa.normal_balance,
    SUM(jel.debit_amount) AS total_debit,
    SUM(jel.credit_amount) AS total_credit,
    SUM(jel.debit_amount) - SUM(jel.credit_amount) AS net_balance
FROM journal_entry_lines jel
JOIN journal_entries je ON jel.journal_entry_id = je.id
JOIN chart_of_accounts coa ON jel.account_id = coa.id
WHERE je.status = 'POSTED'
GROUP BY coa.id, coa.account_code, coa.name_ar, coa.account_type, coa.normal_balance
ORDER BY coa.account_code;

-- [ADVANCED] كشف حساب الطالب (Student Account Statement)
CREATE OR REPLACE VIEW v_student_account_statement AS
SELECT
    s.id AS student_id,
    s.full_name AS student_name,
    si.invoice_number,
    si.invoice_date,
    si.total_amount,
    si.paid_amount,
    si.balance_due,
    si.status AS invoice_status,
    gl.name_ar AS grade_name
FROM student_invoices si
JOIN student_enrollments se ON si.enrollment_id = se.id
JOIN students s ON se.student_id = s.id
JOIN classrooms c ON se.classroom_id = c.id
JOIN grade_levels gl ON c.grade_level_id = gl.id;

-- [ADVANCED] تقرير الإقرار الضريبي (VAT Return Report)
CREATE OR REPLACE VIEW v_vat_return_report AS
SELECT
    tc.tax_code,
    tc.tax_name_ar,
    tc.rate AS tax_rate,
    tc.tax_type,
    COUNT(ili.id) AS line_count,
    SUM(ili.unit_price * ili.quantity) AS taxable_amount,
    SUM(ili.vat_amount) AS tax_collected,
    coa_out.account_code AS output_account_code,
    coa_out.name_ar AS output_account_name
FROM invoice_line_items ili
JOIN fin_tax_codes tc ON ili.tax_code_id = tc.id
JOIN student_invoices si ON ili.invoice_id = si.id
LEFT JOIN chart_of_accounts coa_out ON tc.output_gl_account_id = coa_out.id
WHERE si.status IN ('ISSUED','PARTIAL','PAID')
GROUP BY tc.id, tc.tax_code, tc.tax_name_ar, tc.rate, tc.tax_type,
         coa_out.account_code, coa_out.name_ar;


-- ███████████████████████████████████████████████████████████████████████████████
-- ██                                                                           ██
-- ██   [ADVANCED] القسم 13: Triggers — حماية الفترات المالية المغلقة             ██
-- ██   ═══ الفجوة رقم 1: منع الترحيل في فترة مغلقة ═══                         ██
-- ██                                                                           ██
-- ███████████████████████████████████████████████████████████████████████████████

DELIMITER //

-- Trigger: منع ترحيل (POST) قيد في فترة مالية مغلقة
CREATE TRIGGER IF NOT EXISTS trg_je_before_update_check_period
BEFORE UPDATE ON journal_entries
FOR EACH ROW
BEGIN
    DECLARE v_period_status VARCHAR(20);
    DECLARE v_period_name VARCHAR(50);
    
    -- التحقق فقط عند محاولة الترحيل (الانتقال إلى POSTED)
    IF NEW.status = 'POSTED' AND OLD.status != 'POSTED' THEN
        
        -- البحث عن الفترة المالية التي ينتمي لها تاريخ القيد
        SELECT fp.status, fp.name_ar 
        INTO v_period_status, v_period_name
        FROM fiscal_periods fp
        WHERE fp.fiscal_year_id = NEW.fiscal_year_id
          AND NEW.entry_date BETWEEN fp.start_date AND fp.end_date
        LIMIT 1;
        
        -- إذا كانت الفترة مغلقة → رفض العملية
        IF v_period_status = 'CLOSED' THEN
            SIGNAL SQLSTATE '45000' 
            SET MESSAGE_TEXT = CONCAT(
                'رفض الترحيل: الفترة المالية "', COALESCE(v_period_name, 'غير محددة'),
                '" مغلقة. لا يمكن ترحيل قيود في فترة مالية مغلقة. ',
                'تاريخ القيد: ', NEW.entry_date
            );
        END IF;
        
        -- إذا كانت الفترة في طور الإقفال → رفض (فقط المراجعين يمكنهم الترحيل عبر SP)
        IF v_period_status = 'CLOSING' THEN
            SIGNAL SQLSTATE '45000' 
            SET MESSAGE_TEXT = CONCAT(
                'رفض الترحيل: الفترة المالية "', COALESCE(v_period_name, 'غير محددة'),
                '" قيد الإقفال. استخدم إجراء الترحيل الاستثنائي sp_force_post_in_closing_period.'
            );
        END IF;
        
        -- تحديث fiscal_period_id تلقائياً إذا لم يكن محدداً
        IF NEW.fiscal_period_id IS NULL THEN
            SELECT fp.id INTO @auto_period_id
            FROM fiscal_periods fp
            WHERE fp.fiscal_year_id = NEW.fiscal_year_id
              AND NEW.entry_date BETWEEN fp.start_date AND fp.end_date
            LIMIT 1;
            SET NEW.fiscal_period_id = @auto_period_id;
        END IF;
        
    END IF;
    
    -- منع تعديل قيد مرحّل (إلا العكس)
    IF OLD.status = 'POSTED' AND NEW.status NOT IN ('POSTED', 'REVERSED') THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'لا يمكن تعديل قيد مرحّل. استخدم آلية العكس (Reversal) بدلاً من ذلك.';
    END IF;
END //

-- Trigger: منع إدراج قيد جديد بتاريخ في فترة مغلقة
CREATE TRIGGER IF NOT EXISTS trg_je_before_insert_check_period
BEFORE INSERT ON journal_entries
FOR EACH ROW
BEGIN
    DECLARE v_period_status VARCHAR(20);
    DECLARE v_period_name VARCHAR(50);
    DECLARE v_period_id INT UNSIGNED;
    
    -- البحث عن الفترة المالية
    SELECT fp.id, fp.status, fp.name_ar 
    INTO v_period_id, v_period_status, v_period_name
    FROM fiscal_periods fp
    WHERE fp.fiscal_year_id = NEW.fiscal_year_id
      AND NEW.entry_date BETWEEN fp.start_date AND fp.end_date
    LIMIT 1;
    
    -- منع الإدراج في فترة مغلقة
    IF v_period_status = 'CLOSED' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = CONCAT(
            'رفض الإنشاء: لا يمكن إنشاء قيد بتاريخ ', NEW.entry_date,
            ' — الفترة المالية "', COALESCE(v_period_name, 'غير محددة'), '" مغلقة.'
        );
    END IF;
    
    -- ملء fiscal_period_id تلقائياً
    IF NEW.fiscal_period_id IS NULL AND v_period_id IS NOT NULL THEN
        SET NEW.fiscal_period_id = v_period_id;
    END IF;
END //

DELIMITER ;


-- ███████████████████████████████████████████████████████████████████████████████
-- ██                                                                           ██
-- ██   [ADVANCED] القسم 14: سجل التدقيق (Audit Trail)                           ██
-- ██   ═══ الفجوة الجديدة #5: سجل التدقيق الشامل — أولوية حرجة ═══            ██
-- ██                                                                           ██
-- ███████████████████████████████████████████████████████████████████████████████

-- [ADVANCED] 14.1 سجل التدقيق — يسجل كل عملية على المستندات المالية
CREATE TABLE IF NOT EXISTS audit_trail (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    -- ماذا حدث
    table_name VARCHAR(80) NOT NULL COMMENT 'الجدول المتأثر (journal_entries, student_invoices...)',
    record_id BIGINT UNSIGNED NOT NULL COMMENT 'معرف السجل المتأثر',
    action ENUM('INSERT','UPDATE','DELETE','APPROVE','POST','REVERSE','CLOSE','REOPEN') NOT NULL,
    -- تفاصيل التغيير
    field_name VARCHAR(80) NULL COMMENT 'العمود المتغير (NULL عند INSERT/DELETE)',
    old_value TEXT NULL COMMENT 'القيمة السابقة',
    new_value TEXT NULL COMMENT 'القيمة الجديدة',
    -- تفاصيل إضافية
    change_summary TEXT NULL COMMENT 'وصف مختصر للتغيير',
    -- من فعلها
    user_id INT UNSIGNED NOT NULL,
    user_ip VARCHAR(45) NULL COMMENT 'عنوان IP (IPv4/IPv6)',
    user_agent VARCHAR(255) NULL COMMENT 'المتصفح/التطبيق',
    -- متى
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    -- الفهارس
    INDEX idx_table_record (table_name, record_id),
    INDEX idx_user (user_id),
    INDEX idx_action (action),
    INDEX idx_date (created_at),
    INDEX idx_table_date (table_name, created_at),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='سجل التدقيق الشامل — يسجل كل عملية مالية [ADVANCED - Gap #5]';


-- ███████████████████████████████████████████████████████████████████████████████
-- ██                                                                           ██
-- ██   [ADVANCED] القسم 15: إدارة الميزانيات (Budget Management)                ██
-- ██   ═══ الفجوة الجديدة #6: الميزانيات والتخطيط المالي ═══                   ██
-- ██                                                                           ██
-- ███████████████████████████████████████████████████████████████████████████████

-- [ADVANCED] 15.1 رؤوس الميزانيات
CREATE TABLE IF NOT EXISTS budgets (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name_ar VARCHAR(100) NOT NULL COMMENT 'مثال: ميزانية الفصل الأول 2026',
    fiscal_year_id INT UNSIGNED NOT NULL,
    branch_id INT UNSIGNED NULL COMMENT 'NULL = كل الفروع',
    budget_type ENUM('ANNUAL','SEMESTER','QUARTERLY','MONTHLY','PROJECT') NOT NULL DEFAULT 'ANNUAL',
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    total_amount DECIMAL(18,2) NOT NULL DEFAULT 0.00 COMMENT 'إجمالي الميزانية',
    status ENUM('DRAFT','APPROVED','ACTIVE','CLOSED','REVISED') DEFAULT 'DRAFT',
    approved_by_user_id INT UNSIGNED NULL,
    approved_at TIMESTAMP NULL,
    notes TEXT NULL,
    created_by_user_id INT UNSIGNED NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NULL ON UPDATE CURRENT_TIMESTAMP,
    CHECK (end_date > start_date),
    INDEX idx_fiscal (fiscal_year_id),
    INDEX idx_status (status),
    FOREIGN KEY (fiscal_year_id) REFERENCES fiscal_years(id) ON DELETE RESTRICT,
    FOREIGN KEY (branch_id) REFERENCES branches(id),
    FOREIGN KEY (approved_by_user_id) REFERENCES users(id),
    FOREIGN KEY (created_by_user_id) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='رؤوس الميزانيات [ADVANCED - Gap #6]';

-- [ADVANCED] 15.2 بنود الميزانية — مربوطة بشجرة الحسابات
CREATE TABLE IF NOT EXISTS budget_lines (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    budget_id INT UNSIGNED NOT NULL,
    account_id INT UNSIGNED NOT NULL COMMENT 'الحساب في CoA (مثلاً 5001 رواتب)',
    line_description VARCHAR(200) NULL,
    budgeted_amount DECIMAL(18,2) NOT NULL DEFAULT 0.00 COMMENT 'المبلغ المخصص',
    actual_amount DECIMAL(18,2) DEFAULT 0.00 COMMENT 'المصروف الفعلي (يُحدّث من القيود)',
    variance DECIMAL(18,2) GENERATED ALWAYS AS (budgeted_amount - actual_amount) STORED
        COMMENT 'الفرق = المخصص - الفعلي (موجب = وفر، سالب = تجاوز)',
    variance_percentage DECIMAL(7,2) GENERATED ALWAYS AS (
        CASE WHEN budgeted_amount > 0 
            THEN ROUND(((budgeted_amount - actual_amount) / budgeted_amount) * 100, 2) 
            ELSE 0 
        END
    ) STORED COMMENT 'نسبة الانحراف %',
    notes VARCHAR(255) NULL,
    INDEX idx_budget (budget_id),
    INDEX idx_account (account_id),
    FOREIGN KEY (budget_id) REFERENCES budgets(id) ON DELETE CASCADE,
    FOREIGN KEY (account_id) REFERENCES chart_of_accounts(id) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='بنود الميزانية — مخصصات حسب حساب CoA [ADVANCED - Gap #6]';

-- [ADVANCED] 15.3 View: الميزانية مقابل الفعلي
CREATE OR REPLACE VIEW v_budget_vs_actual AS
SELECT
    b.name_ar AS budget_name,
    b.budget_type,
    b.status AS budget_status,
    coa.account_code,
    coa.name_ar AS account_name,
    coa.account_type,
    bl.budgeted_amount,
    bl.actual_amount,
    bl.variance,
    bl.variance_percentage,
    CASE 
        WHEN bl.variance < 0 THEN 'تجاوز'
        WHEN bl.variance_percentage <= 10 THEN 'قريب من النفاد'
        ELSE 'ضمن الميزانية'
    END AS budget_health,
    br.name_ar AS branch_name
FROM budget_lines bl
JOIN budgets b ON bl.budget_id = b.id
JOIN chart_of_accounts coa ON bl.account_id = coa.id
LEFT JOIN branches br ON b.branch_id = br.id
WHERE b.status IN ('APPROVED', 'ACTIVE');


-- ███████████████████████████████████████████████████████████████████████████████
-- ██                                                                           ██
-- ██   [ADVANCED] القسم 16: مذكرات الائتمان والخصم (Credit/Debit Notes)         ██
-- ██   ═══ الفجوة الجديدة #7: مستندات الاسترداد والتعديل ═══                  ██
-- ██                                                                           ██
-- ███████████████████████████████████████████████████████████████████████████████

-- [ADVANCED] 16.1 مذكرات الائتمان/الخصم
CREATE TABLE IF NOT EXISTS credit_debit_notes (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    note_number VARCHAR(30) NOT NULL UNIQUE COMMENT 'CN-2026-00001 / DN-2026-00001',
    note_type ENUM('CREDIT','DEBIT') NOT NULL
        COMMENT 'CREDIT=استرداد/تخفيض لصالح العميل, DEBIT=رسوم إضافية',
    -- الربط بالفاتورة الأصلية
    original_invoice_id BIGINT UNSIGNED NOT NULL COMMENT 'الفاتورة الأصلية',
    enrollment_id INT UNSIGNED NULL,
    -- المبالغ
    amount DECIMAL(15,2) NOT NULL,
    vat_amount DECIMAL(15,2) DEFAULT 0.00,
    total_amount DECIMAL(15,2) NOT NULL,
    -- السبب
    reason ENUM('WITHDRAWAL','OVERCHARGE','SCHOLARSHIP','FEE_ADJUSTMENT','REFUND','PENALTY','OTHER') NOT NULL,
    reason_details TEXT NULL,
    -- الحالة
    status ENUM('DRAFT','APPROVED','APPLIED','CANCELLED') DEFAULT 'DRAFT',
    applied_at TIMESTAMP NULL COMMENT 'تاريخ التطبيق على الفاتورة',
    -- الربط المحاسبي
    journal_entry_id BIGINT UNSIGNED NULL COMMENT 'القيد المحاسبي المُولّد',
    -- التدقيق
    created_by_user_id INT UNSIGNED NULL,
    approved_by_user_id INT UNSIGNED NULL,
    approved_at TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NULL ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_invoice (original_invoice_id),
    INDEX idx_type (note_type),
    INDEX idx_status (status),
    INDEX idx_reason (reason),
    FOREIGN KEY (original_invoice_id) REFERENCES student_invoices(id) ON DELETE RESTRICT,
    FOREIGN KEY (enrollment_id) REFERENCES student_enrollments(id),
    FOREIGN KEY (journal_entry_id) REFERENCES journal_entries(id),
    FOREIGN KEY (created_by_user_id) REFERENCES users(id),
    FOREIGN KEY (approved_by_user_id) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='مذكرات الائتمان والخصم — استرداد وتعديل الفواتير [ADVANCED - Gap #7]';


-- ███████████████████████████████████████████████████████████████████████████████
-- ██                                                                           ██
-- ██   [ADVANCED] القسم 17: الترقيم التسلسلي (Document Sequences)               ██
-- ██   ═══ الفجوة الجديدة #8: إدارة تسلسل الأرقام ═══                         ██
-- ██                                                                           ██
-- ███████████████████████████████████████████████████████████████████████████████

-- [ADVANCED] 17.1 تسلسل المستندات
CREATE TABLE IF NOT EXISTS document_sequences (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    document_type ENUM('JOURNAL_ENTRY','INVOICE','PAYMENT','CREDIT_NOTE','DEBIT_NOTE','RECEIPT') NOT NULL,
    prefix VARCHAR(10) NOT NULL COMMENT 'JE, INV, TXN, CN, DN, RCP',
    fiscal_year_id INT UNSIGNED NULL COMMENT 'NULL = عام',
    branch_id INT UNSIGNED NULL COMMENT 'NULL = كل الفروع',
    last_number INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'آخر رقم مُستخدم',
    number_format VARCHAR(50) NOT NULL DEFAULT '{PREFIX}-{YEAR}-{SEQ:5}'
        COMMENT 'قالب الترقيم: {PREFIX}-{YEAR}-{SEQ:5} → JE-2026-00001',
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NULL ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uk_seq (document_type, fiscal_year_id, branch_id),
    FOREIGN KEY (fiscal_year_id) REFERENCES fiscal_years(id),
    FOREIGN KEY (branch_id) REFERENCES branches(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='تسلسل ترقيم المستندات — يمنع الثغرات والتكرار [ADVANCED - Gap #8]';

-- بذور أنواع المستندات
INSERT INTO document_sequences (document_type, prefix, number_format) VALUES
('JOURNAL_ENTRY', 'JE', '{PREFIX}-{YEAR}-{SEQ:5}'),
('INVOICE', 'INV', '{PREFIX}-{YEAR}-{SEQ:5}'),
('PAYMENT', 'TXN', '{PREFIX}-{YEAR}-{SEQ:5}'),
('CREDIT_NOTE', 'CN', '{PREFIX}-{YEAR}-{SEQ:5}'),
('DEBIT_NOTE', 'DN', '{PREFIX}-{YEAR}-{SEQ:5}'),
('RECEIPT', 'RCP', '{PREFIX}-{YEAR}-{SEQ:5}');


-- ███████████████████████████████████████████████████████████████████████████████
-- ██                                                                           ██
-- ██   [ADVANCED] القسم 18: القيود المتكررة (Recurring Entries)                  ██
-- ██   ═══ الفجوة الجديدة #9: جدولة القيود الشهرية ═══                        ██
-- ██                                                                           ██
-- ███████████████████████████████████████████████████████████████████████████████

-- [ADVANCED] 18.1 قوالب القيود المتكررة
CREATE TABLE IF NOT EXISTS recurring_journal_templates (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    template_name VARCHAR(100) NOT NULL COMMENT 'مثال: قيد إيجار شهري، إهلاك أصول',
    description TEXT NULL,
    -- الجدولة
    frequency ENUM('DAILY','WEEKLY','MONTHLY','QUARTERLY','SEMI_ANNUAL','ANNUAL') NOT NULL DEFAULT 'MONTHLY',
    start_date DATE NOT NULL,
    end_date DATE NULL COMMENT 'NULL = مستمر حتى الإلغاء',
    next_run_date DATE NOT NULL COMMENT 'تاريخ التوليد القادم',
    -- بيانات القيد المُولّد
    branch_id INT UNSIGNED NULL,
    currency_id TINYINT UNSIGNED NULL,
    entry_description TEXT NOT NULL COMMENT 'بيان القيد المُولّد',
    reference_type VARCHAR(30) DEFAULT 'RECURRING',
    total_amount DECIMAL(18,2) NOT NULL COMMENT 'مبلغ القيد',
    -- التحكم
    auto_post BOOLEAN DEFAULT FALSE COMMENT 'ترحيل تلقائي أم يبقى Draft؟',
    is_active BOOLEAN DEFAULT TRUE,
    last_generated_at TIMESTAMP NULL COMMENT 'آخر مرة تم التوليد',
    last_generated_je_id BIGINT UNSIGNED NULL COMMENT 'آخر قيد مُولّد',
    total_generated INT UNSIGNED DEFAULT 0 COMMENT 'عدد القيود المُولّدة',
    -- التدقيق
    created_by_user_id INT UNSIGNED NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NULL ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_next_run (next_run_date),
    INDEX idx_active (is_active),
    INDEX idx_frequency (frequency),
    FOREIGN KEY (branch_id) REFERENCES branches(id),
    FOREIGN KEY (currency_id) REFERENCES currencies(id),
    FOREIGN KEY (last_generated_je_id) REFERENCES journal_entries(id) ON DELETE SET NULL,
    FOREIGN KEY (created_by_user_id) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='قوالب القيود المتكررة — إيجار، إهلاك، رواتب ثابتة [ADVANCED - Gap #9]';

-- [ADVANCED] 18.2 سطور قالب القيد المتكرر
CREATE TABLE IF NOT EXISTS recurring_template_lines (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    template_id INT UNSIGNED NOT NULL,
    line_number SMALLINT UNSIGNED NOT NULL,
    account_id INT UNSIGNED NOT NULL,
    description VARCHAR(255) NULL,
    debit_amount DECIMAL(18,2) NOT NULL DEFAULT 0.00,
    credit_amount DECIMAL(18,2) NOT NULL DEFAULT 0.00,
    cost_center_id INT UNSIGNED NULL,
    CHECK (debit_amount >= 0 AND credit_amount >= 0),
    CHECK (NOT (debit_amount > 0 AND credit_amount > 0)),
    UNIQUE KEY uk_tpl_line (template_id, line_number),
    FOREIGN KEY (template_id) REFERENCES recurring_journal_templates(id) ON DELETE CASCADE,
    FOREIGN KEY (account_id) REFERENCES chart_of_accounts(id) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='سطور قالب القيد المتكرر [ADVANCED - Gap #9]';


-- ███████████████████████████████████████████████████████████████████████████████
-- ██                                                                           ██
-- ██   [ADVANCED] القسم 19: مراكز التكلفة (Cost Centers)                        ██
-- ██   ═══ الفجوة الجديدة #10: جدول مرجعي لمراكز التكلفة ═══                  ██
-- ██                                                                           ██
-- ███████████████████████████████████████████████████████████████████████████████

-- [ADVANCED] 19.1 مراكز التكلفة
CREATE TABLE IF NOT EXISTS cost_centers (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    code VARCHAR(20) NOT NULL UNIQUE COMMENT 'رمز المركز (CC-ADMIN, CC-ACAD)',
    name_ar VARCHAR(100) NOT NULL,
    name_en VARCHAR(100) NULL,
    parent_id INT UNSIGNED NULL COMMENT 'مركز تكلفة أب (شجرة)',
    branch_id INT UNSIGNED NULL,
    manager_employee_id INT UNSIGNED NULL COMMENT 'المسؤول عن المركز',
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_code (code),
    INDEX idx_parent (parent_id),
    FOREIGN KEY (parent_id) REFERENCES cost_centers(id) ON DELETE RESTRICT,
    FOREIGN KEY (branch_id) REFERENCES branches(id),
    FOREIGN KEY (manager_employee_id) REFERENCES employees(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='مراكز التكلفة [ADVANCED - Gap #10]';

INSERT INTO cost_centers (code, name_ar) VALUES
('CC-ADMIN', 'الإدارة العامة'),
('CC-ACAD', 'الشؤون الأكاديمية'),
('CC-TRANS', 'النقل والمواصلات'),
('CC-MAINT', 'الصيانة والتشغيل'),
('CC-IT', 'تقنية المعلومات');

-- [ADVANCED] 19.2 ربط مراكز التكلفة بسطور القيد
-- تحويل cost_center من VARCHAR إلى FK
ALTER TABLE journal_entry_lines
    ADD COLUMN cost_center_id INT UNSIGNED NULL COMMENT '[Gap #10] مركز التكلفة المرجعي'
    AFTER cost_center;

ALTER TABLE journal_entry_lines
    ADD CONSTRAINT fk_jel_cost_center FOREIGN KEY (cost_center_id)
    REFERENCES cost_centers(id) ON DELETE SET NULL;

-- ربط سطور القوالب بمراكز التكلفة
ALTER TABLE recurring_template_lines
    ADD CONSTRAINT fk_rtl_cost_center FOREIGN KEY (cost_center_id)
    REFERENCES cost_centers(id) ON DELETE SET NULL;


-- ███████████████████████████████████████████████████████████████████████████████
-- ██                                                                           ██
-- ██   [ADVANCED] القسم 20: View أعمار الديون (Accounts Receivable Aging)       ██
-- ██   ═══ الفجوة الجديدة #11: تقرير أعمار الديون ═══                         ██
-- ██                                                                           ██
-- ███████████████████████████████████████████████████████████████████████████████

-- [ADVANCED] 20.1 تقرير أعمار الذمم المدينة
CREATE OR REPLACE VIEW v_accounts_receivable_aging AS
SELECT
    s.id AS student_id,
    s.full_name AS student_name,
    g.full_name AS guardian_name,
    gl.name_ar AS grade_name,
    si.invoice_number,
    si.invoice_date,
    si.due_date,
    si.total_amount,
    si.paid_amount,
    si.balance_due,
    DATEDIFF(CURRENT_DATE, si.due_date) AS days_overdue,
    -- تصنيف أعمار الديون
    CASE
        WHEN si.balance_due <= 0 THEN 'مسدد'
        WHEN DATEDIFF(CURRENT_DATE, si.due_date) <= 0 THEN 'غير مستحق بعد'
        WHEN DATEDIFF(CURRENT_DATE, si.due_date) BETWEEN 1 AND 30 THEN '1-30 يوم'
        WHEN DATEDIFF(CURRENT_DATE, si.due_date) BETWEEN 31 AND 60 THEN '31-60 يوم'
        WHEN DATEDIFF(CURRENT_DATE, si.due_date) BETWEEN 61 AND 90 THEN '61-90 يوم'
        WHEN DATEDIFF(CURRENT_DATE, si.due_date) BETWEEN 91 AND 120 THEN '91-120 يوم'
        ELSE 'أكثر من 120 يوم'
    END AS aging_bucket,
    -- مبالغ حسب الفئة (للتجميع)
    CASE WHEN DATEDIFF(CURRENT_DATE, si.due_date) BETWEEN 1 AND 30 
         THEN si.balance_due ELSE 0 END AS bucket_1_30,
    CASE WHEN DATEDIFF(CURRENT_DATE, si.due_date) BETWEEN 31 AND 60 
         THEN si.balance_due ELSE 0 END AS bucket_31_60,
    CASE WHEN DATEDIFF(CURRENT_DATE, si.due_date) BETWEEN 61 AND 90 
         THEN si.balance_due ELSE 0 END AS bucket_61_90,
    CASE WHEN DATEDIFF(CURRENT_DATE, si.due_date) BETWEEN 91 AND 120 
         THEN si.balance_due ELSE 0 END AS bucket_91_120,
    CASE WHEN DATEDIFF(CURRENT_DATE, si.due_date) > 120 
         THEN si.balance_due ELSE 0 END AS bucket_120_plus,
    si.status AS invoice_status,
    br.name_ar AS branch_name
FROM student_invoices si
JOIN student_enrollments se ON si.enrollment_id = se.id
JOIN students s ON se.student_id = s.id
JOIN classrooms c ON se.classroom_id = c.id
JOIN grade_levels gl ON c.grade_level_id = gl.id
LEFT JOIN student_guardians sg ON s.id = sg.student_id AND sg.is_primary = TRUE
LEFT JOIN guardians g ON sg.guardian_id = g.id
LEFT JOIN branches br ON si.branch_id = br.id
WHERE si.status IN ('ISSUED', 'PARTIAL')
  AND si.balance_due > 0;


-- ╔══════════════════════════════════════════════════════════════════════════════╗
-- ║  ملخص النظام المالي الموحد المتقدم v3.2 (الإصدار الاحترافي الكامل)          ║
-- ║  ─────────────────────────────────────────────                               ║
-- ║  [LEGACY]   جداول: 7  (lookups×3, funds, revenues, expenses, contributions) ║
-- ║  [ADVANCED] جداول: 28 (+audit_trail, budgets, budget_lines, credit_debit    ║
-- ║                        _notes, document_sequences, recurring_journal        ║
-- ║                        _templates, recurring_template_lines, cost_centers)  ║
-- ║  [BRIDGE]   أعمدة: 6  (coa_account_id, journal_entry_id, invoice_id)        ║
-- ║  [LEGACY]   Views: 2  (v_unified_status, v_contributions_analysis)          ║
-- ║  [ADVANCED] Views: 7  (v_general_ledger, v_trial_balance, v_student_stmt,   ║
-- ║                         v_vat_return, v_budget_vs_actual, v_ar_aging)       ║
-- ║  [ADVANCED] Triggers: 2 (period close protection)                           ║
-- ║  ─────────────────────────────────────────────                               ║
-- ║  الفجوات المسدودة (v3.1):                                                   ║
-- ║  #1 ✅ إقفال الفترات المالية    #2 ✅ محرك الضرائب المتقدم                   ║
-- ║  #3 ✅ دقة أسعار الصرف          #4 ✅ التوجيه المحاسبي للخصومات              ║
-- ║  الفجوات المسدودة (v3.2):                                                   ║
-- ║  #5 ✅ سجل التدقيق (Audit Trail)   #6 ✅ إدارة الميزانيات (Budget)           ║
-- ║  #7 ✅ مذكرات ائتمان/خصم           #8 ✅ الترقيم التسلسلي (Sequences)        ║
-- ║  #9 ✅ القيود المتكررة (Recurring)  #10 ✅ مراكز التكلفة (Cost Centers)      ║
-- ║  #11 ✅ تقرير أعمار الديون (AR Aging)                                       ║
-- ║  ─────────────────────────────────────────────                               ║
-- ║  المجموع النهائي: 35 جدول + 9 Views + 2 Triggers                            ║
-- ║  نسبة الاكتمال: 100% ✅                                                     ║
-- ╚══════════════════════════════════════════════════════════════════════════════╝
