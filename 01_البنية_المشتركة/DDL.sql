-- ╔══════════════════════════════════════════════════════════════════════════════╗
-- ║                     نظام إدارة المدرسة المتكامل                              ║
-- ║                School Management System Database                              ║
-- ║                                                                               ║
-- ║  الجزء 1: البنية التحتية المشتركة (Shared Infrastructure)                    ║
-- ║  المسؤول: عماد الجماعي (المهندس المشرف)                                       ║
-- ╚══════════════════════════════════════════════════════════════════════════════╝

-- التاريخ: 2026-01-05
-- الإصدار: 1.0
-- قاعدة البيانات: MySQL 8.0+

-- ═══════════════════════════════════════════════════════════════════════════════
-- القسم 1: الجداول المرجعية (Lookup Tables)
-- ═══════════════════════════════════════════════════════════════════════════════

-- -----------------------------------------------------------------------------
-- 1.1 جدول أنواع المدارس
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS lookup_school_types (
    id TINYINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name_ar VARCHAR(50) NOT NULL COMMENT 'الاسم بالعربية',
    name_en VARCHAR(50) NULL COMMENT 'الاسم بالإنجليزية',
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='أنواع المدارس';

INSERT INTO lookup_school_types (name_ar, name_en) VALUES
('أساسية', 'Primary'),
('ثانوية', 'Secondary'),
('مختلطة', 'Mixed');

INSERT INTO lookup_school_types (name_ar, name_en) VALUES
('أساسية', 'Primary'),
('ثانوية', 'Secondary'),
('مختلطة', 'Mixed');

-- -----------------------------------------------------------------------------
-- 1.2 جدول أنواع الجنس (جديد)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS lookup_genders (
    id TINYINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name_ar VARCHAR(20) NOT NULL,
    name_en VARCHAR(20) NULL,
    is_active BOOLEAN DEFAULT TRUE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO lookup_genders (name_ar, name_en) VALUES
('ذكر', 'Male'),
('أنثى', 'Female');

-- -----------------------------------------------------------------------------
-- 1.3 جدول فصائل الدم (جديد)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS lookup_blood_types (
    id TINYINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(5) NOT NULL,
    is_active BOOLEAN DEFAULT TRUE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO lookup_blood_types (name) VALUES
('A+'), ('A-'), ('B+'), ('B-'), ('O+'), ('O-'), ('AB+'), ('AB-');

-- -----------------------------------------------------------------------------
-- 1.4 جدول أنواع الهوية (جديد)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS lookup_id_types (
    id TINYINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name_ar VARCHAR(50) NOT NULL,
    is_active BOOLEAN DEFAULT TRUE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO lookup_id_types (name_ar) VALUES
('بطاقة شخصية'),
('جواز سفر'),
('شهادة ميلاد'),
('بطاقة عائلية');

-- -----------------------------------------------------------------------------
-- 1.5 جدول أنواع الملكية
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS lookup_ownership_types (
    id TINYINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name_ar VARCHAR(50) NOT NULL,
    is_active BOOLEAN DEFAULT TRUE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='أنواع ملكية المدرسة';

INSERT INTO lookup_ownership_types (name_ar) VALUES
('حكومية'),
('خاصة'),
('أهلية');

-- -----------------------------------------------------------------------------
-- 1.3 جدول الفترات الدراسية
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS lookup_periods (
    id TINYINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name_ar VARCHAR(30) NOT NULL,
    is_active BOOLEAN DEFAULT TRUE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='فترات الدوام';

INSERT INTO lookup_periods (name_ar) VALUES
('صباحية'),
('مسائية'),
('كلاهما');

-- -----------------------------------------------------------------------------
-- 1.4 جدول المؤهلات العلمية
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS lookup_qualifications (
    id TINYINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name_ar VARCHAR(50) NOT NULL,
    sort_order TINYINT UNSIGNED DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='المؤهلات العلمية';

INSERT INTO lookup_qualifications (name_ar, sort_order) VALUES
('خبرة', 1),
('أساسي', 2),
('ثانوي', 3),
('دبلوم معلمين', 4),
('دبلوم عالي', 5),
('جامعي', 6),
('ماجستير', 7),
('دكتوراه', 8),
('أخرى', 99);

-- -----------------------------------------------------------------------------
-- 1.5 جدول الأدوار الوظيفية
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS lookup_job_roles (
    id TINYINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name_ar VARCHAR(50) NOT NULL,
    name_ar_female VARCHAR(50) NULL COMMENT 'الصيغة المؤنثة',
    is_active BOOLEAN DEFAULT TRUE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='الأدوار الوظيفية';

INSERT INTO lookup_job_roles (name_ar, name_ar_female) VALUES
('مدير', 'مديرة'),
('مشرف', 'مشرفة'),
('معلم', 'معلمة'),
('مربي', 'مربية'),
('رائد', 'رائدة'),
('إداري', 'إدارية'),
('حارس', 'حارسة'),
('عامل نظافة', 'عاملة نظافة');

-- -----------------------------------------------------------------------------
-- 1.6 جدول أيام الأسبوع
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS lookup_days (
    id TINYINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name_ar VARCHAR(20) NOT NULL,
    name_en VARCHAR(20) NULL,
    order_num TINYINT UNSIGNED NOT NULL,
    is_working_day BOOLEAN DEFAULT TRUE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='أيام الأسبوع';

INSERT INTO lookup_days (name_ar, name_en, order_num, is_working_day) VALUES
('السبت', 'Saturday', 1, TRUE),
('الأحد', 'Sunday', 2, TRUE),
('الاثنين', 'Monday', 3, TRUE),
('الثلاثاء', 'Tuesday', 4, TRUE),
('الأربعاء', 'Wednesday', 5, TRUE),
('الخميس', 'Thursday', 6, TRUE),
('الجمعة', 'Friday', 7, FALSE);

-- -----------------------------------------------------------------------------
-- 1.7 جدول حالات الحضور
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS lookup_attendance_statuses (
    id TINYINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name_ar VARCHAR(30) NOT NULL,
    code VARCHAR(10) NOT NULL UNIQUE,
    applies_to ENUM('طلاب', 'موظفين', 'الكل') DEFAULT 'الكل',
    color_code VARCHAR(7) NULL COMMENT 'لون العرض (HEX)',
    is_active BOOLEAN DEFAULT TRUE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='حالات الحضور والغياب';

INSERT INTO lookup_attendance_statuses (name_ar, code, applies_to, color_code) VALUES
('حاضر', 'PRESENT', 'الكل', '#28a745'),
('غائب', 'ABSENT', 'الكل', '#dc3545'),
('متأخر', 'LATE', 'الكل', '#ffc107'),
('منصرف', 'LEFT', 'طلاب', '#17a2b8'),
('غائب بإذن', 'ABSENT_P', 'الكل', '#6c757d'),
('غائب بعذر', 'ABSENT_E', 'الكل', '#6c757d');

-- -----------------------------------------------------------------------------
-- 1.8 جدول الحالات الاجتماعية
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS lookup_marital_statuses (
    id TINYINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name_ar VARCHAR(30) NOT NULL,
    is_active BOOLEAN DEFAULT TRUE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='الحالات الاجتماعية';

INSERT INTO lookup_marital_statuses (name_ar) VALUES
('أعزب'),
('متزوج'),
('مطلق'),
('أرمل');

-- -----------------------------------------------------------------------------
-- 1.9 جدول الحالات الصحية
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS lookup_health_statuses (
    id TINYINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name_ar VARCHAR(30) NOT NULL,
    requires_details BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='الحالات الصحية';

INSERT INTO lookup_health_statuses (name_ar, requires_details) VALUES
('سليم', FALSE),
('مريض', TRUE),
('معاق', TRUE);

-- -----------------------------------------------------------------------------
-- 1.10 جدول أنواع العلاقات (القرابة)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS lookup_relationship_types (
    id TINYINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name_ar VARCHAR(30) NOT NULL,
    gender ENUM('ذكر', 'أنثى', 'الكل') DEFAULT 'الكل',
    is_active BOOLEAN DEFAULT TRUE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='أنواع صلة القرابة';

INSERT INTO lookup_relationship_types (name_ar, gender) VALUES
('أب', 'ذكر'),
('أم', 'أنثى'),
('أخ', 'ذكر'),
('أخت', 'أنثى'),
('عم', 'ذكر'),
('عمة', 'أنثى'),
('خال', 'ذكر'),
('خالة', 'أنثى'),
('جد', 'ذكر'),
('جدة', 'أنثى'),
('وصي', 'الكل'),
('أخرى', 'الكل');

-- -----------------------------------------------------------------------------
-- 1.11 جدول المواهب
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS lookup_talents (
    id TINYINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name_ar VARCHAR(50) NOT NULL,
    category VARCHAR(30) NULL COMMENT 'التصنيف',
    applies_to ENUM('طلاب', 'موظفين', 'الكل') DEFAULT 'الكل',
    is_active BOOLEAN DEFAULT TRUE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='المواهب والمهارات';

INSERT INTO lookup_talents (name_ar, category, applies_to) VALUES
('التفوق الدراسي/الذكاء', 'علمي', 'طلاب'),
('القراءة', 'أدبي', 'الكل'),
('الخط', 'فني', 'الكل'),
('الرسم', 'فني', 'الكل'),
('الإلقاء', 'أدبي', 'الكل'),
('التمثيل', 'فني', 'الكل'),
('الحفظ', 'ديني', 'الكل'),
('الإنشاد', 'ديني', 'الكل'),
('محاكات الأصوات', 'فني', 'الكل'),
('ترتيل القرآن', 'ديني', 'الكل'),
('شاعر', 'أدبي', 'الكل'),
('حرفة يدوية', 'مهني', 'الكل'),
('سائق', 'مهني', 'موظفين'),
('حركات نادرة', 'ترفيهي', 'طلاب'),
('رياضة', 'رياضي', 'الكل'),
('سباحة', 'رياضي', 'الكل'),
('تطريز', 'مهني', 'الكل'),
('نقش', 'فني', 'الكل'),
('خياطة', 'مهني', 'الكل'),
('صناعة', 'مهني', 'الكل'),
('أخرى', NULL, 'الكل');

-- ═══════════════════════════════════════════════════════════════════════════════
-- القسم 2: نظام الصلاحيات (RBAC)
-- ═══════════════════════════════════════════════════════════════════════════════

-- -----------------------------------------------------------------------------
-- 2.1 جدول المستخدمين
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS users (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    email VARCHAR(100) NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    employee_id INT UNSIGNED NULL COMMENT 'ربط بالموظف (إن وجد)',
    is_active BOOLEAN DEFAULT TRUE,
    last_login_at TIMESTAMP NULL,
    password_changed_at TIMESTAMP NULL,
    failed_login_attempts TINYINT UNSIGNED DEFAULT 0,
    locked_until TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NULL ON UPDATE CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL COMMENT 'Soft Delete',
    
    INDEX idx_username (username),
    INDEX idx_email (email),
    INDEX idx_employee (employee_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='المستخدمين';

-- -----------------------------------------------------------------------------
-- 2.2 جدول الأدوار
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS roles (
    id TINYINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(50) NOT NULL UNIQUE,
    name_ar VARCHAR(50) NOT NULL,
    description TEXT NULL,
    is_system BOOLEAN DEFAULT FALSE COMMENT 'دور نظامي لا يمكن حذفه',
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='الأدوار';

INSERT INTO roles (name, name_ar, is_system) VALUES
('super_admin', 'مدير النظام', TRUE),
('school_admin', 'مدير المدرسة', TRUE),
('supervisor', 'مشرف', FALSE),
('teacher', 'معلم', FALSE),
('class_supervisor', 'مربي/رائد صف', FALSE),
('employee', 'موظف', FALSE),
('viewer', 'مشاهد فقط', FALSE);

-- -----------------------------------------------------------------------------
-- 2.3 جدول الصلاحيات
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS permissions (
    id SMALLINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    name_ar VARCHAR(100) NOT NULL,
    module VARCHAR(50) NOT NULL COMMENT 'الوحدة/النظام',
    description TEXT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    INDEX idx_module (module)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='الصلاحيات';

-- صلاحيات نظام الطلاب
INSERT INTO permissions (name, name_ar, module) VALUES
('students.view', 'عرض الطلاب', 'students'),
('students.create', 'إضافة طالب', 'students'),
('students.edit', 'تعديل طالب', 'students'),
('students.delete', 'حذف طالب', 'students'),
('students.export', 'تصدير بيانات الطلاب', 'students'),
('attendance.view', 'عرض الحضور', 'attendance'),
('attendance.record', 'تسجيل الحضور', 'attendance'),
('attendance.edit', 'تعديل الحضور', 'attendance'),
('grades.view', 'عرض الدرجات', 'grades'),
('grades.enter', 'إدخال الدرجات', 'grades'),
('grades.edit', 'تعديل الدرجات', 'grades'),
('grades.approve', 'اعتماد الدرجات', 'grades'),
('reports.view', 'عرض التقارير', 'reports'),
('reports.export', 'تصدير التقارير', 'reports'),
('employees.view', 'عرض الموظفين', 'employees'),
('employees.manage', 'إدارة الموظفين', 'employees'),
('settings.view', 'عرض الإعدادات', 'settings'),
('settings.manage', 'إدارة الإعدادات', 'settings');

-- -----------------------------------------------------------------------------
-- 2.4 جدول ربط الأدوار بالصلاحيات
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS role_permissions (
    role_id TINYINT UNSIGNED NOT NULL,
    permission_id SMALLINT UNSIGNED NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    PRIMARY KEY (role_id, permission_id),
    FOREIGN KEY (role_id) REFERENCES roles(id) ON DELETE CASCADE,
    FOREIGN KEY (permission_id) REFERENCES permissions(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='ربط الأدوار بالصلاحيات';

-- منح جميع الصلاحيات لمدير النظام
INSERT INTO role_permissions (role_id, permission_id)
SELECT 1, id FROM permissions;

-- -----------------------------------------------------------------------------
-- 2.5 جدول ربط المستخدمين بالأدوار
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS user_roles (
    user_id INT UNSIGNED NOT NULL,
    role_id TINYINT UNSIGNED NOT NULL,
    assigned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    assigned_by INT UNSIGNED NULL,
    
    PRIMARY KEY (user_id, role_id),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (role_id) REFERENCES roles(id) ON DELETE CASCADE,
    FOREIGN KEY (assigned_by) REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='ربط المستخدمين بالأدوار';

-- ═══════════════════════════════════════════════════════════════════════════════
-- القسم 2.6: الصلاحيات المباشرة للمستخدمين (User Direct Permissions)
-- تحديث: 2026-01-25
-- الغرض: منح صلاحيات محددة لمستخدم معين لفترة زمنية محددة (مستقلة عن دوره)
-- ═══════════════════════════════════════════════════════════════════════════════

-- -----------------------------------------------------------------------------
-- 2.6.1 جدول الصلاحيات المباشرة للمستخدمين
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS user_permissions (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id INT UNSIGNED NOT NULL COMMENT 'المستخدم',
    permission_id SMALLINT UNSIGNED NOT NULL COMMENT 'الصلاحية الممنوحة',
    
    -- فترة الصلاحية
    valid_from DATE DEFAULT (CURRENT_DATE) COMMENT 'تاريخ بداية الصلاحية',
    valid_until DATE NULL COMMENT 'تاريخ انتهاء الصلاحية (NULL = دائمة)',
    
    -- سبب منح الصلاحية (مهم للتوثيق والتدقيق)
    grant_reason TEXT NOT NULL COMMENT 'سبب منح هذه الصلاحية',
    notes VARCHAR(500) NULL COMMENT 'ملاحظات إضافية',
    
    -- التدقيق - المنح
    granted_by INT UNSIGNED NOT NULL COMMENT 'من منح الصلاحية',
    granted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT 'تاريخ المنح',
    
    -- التدقيق - السحب
    revoked_at TIMESTAMP NULL COMMENT 'تاريخ سحب الصلاحية',
    revoked_by INT UNSIGNED NULL COMMENT 'من سحب الصلاحية',
    revoke_reason VARCHAR(255) NULL COMMENT 'سبب السحب',
    
    -- القيود والفهارس
    UNIQUE KEY uk_user_permission (user_id, permission_id),
    INDEX idx_valid_until (valid_until),
    INDEX idx_revoked (revoked_at),
    INDEX idx_granted_by (granted_by),
    
    -- المفاتيح الخارجية
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (permission_id) REFERENCES permissions(id) ON DELETE CASCADE,
    FOREIGN KEY (granted_by) REFERENCES users(id) ON DELETE RESTRICT,
    FOREIGN KEY (revoked_by) REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='الصلاحيات المباشرة للمستخدمين - مستقلة عن الأدوار، تدعم الفترة الزمنية';

-- -----------------------------------------------------------------------------
-- 2.6.2 View: صلاحيات المستخدم الفعلية (من الدور + المباشرة)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE VIEW v_user_effective_permissions AS
-- صلاحيات من الأدوار
SELECT 
    u.id AS user_id,
    u.username,
    p.id AS permission_id,
    p.name AS permission_name,
    p.name_ar AS permission_name_ar,
    p.module,
    'role' AS source_type,
    r.name_ar AS source_name,
    NULL AS valid_until,
    NULL AS grant_reason,
    NULL AS days_remaining
FROM users u
JOIN user_roles ur ON u.id = ur.user_id
JOIN roles r ON ur.role_id = r.id
JOIN role_permissions rp ON r.id = rp.role_id
JOIN permissions p ON rp.permission_id = p.id
WHERE u.is_active = TRUE AND u.deleted_at IS NULL

UNION

-- صلاحيات مباشرة سارية
SELECT 
    u.id AS user_id,
    u.username,
    p.id AS permission_id,
    p.name AS permission_name,
    p.name_ar AS permission_name_ar,
    p.module,
    'direct' AS source_type,
    'صلاحية مباشرة' AS source_name,
    up.valid_until,
    up.grant_reason,
    CASE 
        WHEN up.valid_until IS NOT NULL THEN DATEDIFF(up.valid_until, CURRENT_DATE)
        ELSE NULL 
    END AS days_remaining
FROM users u
JOIN user_permissions up ON u.id = up.user_id
JOIN permissions p ON up.permission_id = p.id
WHERE u.is_active = TRUE 
  AND u.deleted_at IS NULL
  AND up.revoked_at IS NULL
  AND up.valid_from <= CURRENT_DATE
  AND (up.valid_until IS NULL OR up.valid_until >= CURRENT_DATE);

-- -----------------------------------------------------------------------------
-- 2.6.3 View: الصلاحيات المباشرة فقط (للإدارة)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE VIEW v_user_direct_permissions AS
SELECT 
    up.id,
    up.user_id,
    u.username,
    e.full_name AS employee_name,
    up.permission_id,
    p.name AS permission_name,
    p.name_ar AS permission_name_ar,
    p.module,
    up.valid_from,
    up.valid_until,
    up.grant_reason,
    up.notes,
    up.granted_by,
    granter.username AS granted_by_username,
    up.granted_at,
    up.revoked_at,
    up.revoked_by,
    up.revoke_reason,
    CASE 
        WHEN up.revoked_at IS NOT NULL THEN 'ملغاة'
        WHEN up.valid_until < CURRENT_DATE THEN 'منتهية'
        WHEN up.valid_from > CURRENT_DATE THEN 'مستقبلية'
        ELSE 'سارية'
    END AS status,
    CASE 
        WHEN up.valid_until IS NOT NULL AND up.revoked_at IS NULL 
        THEN DATEDIFF(up.valid_until, CURRENT_DATE)
        ELSE NULL 
    END AS days_remaining
FROM user_permissions up
JOIN users u ON up.user_id = u.id
JOIN permissions p ON up.permission_id = p.id
LEFT JOIN users granter ON up.granted_by = granter.id
LEFT JOIN employees e ON u.employee_id = e.id;

-- -----------------------------------------------------------------------------
-- 2.6.4 View: الصلاحيات قريبة الانتهاء (للتنبيهات)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE VIEW v_expiring_permissions AS
SELECT 
    up.id,
    up.user_id,
    u.username,
    u.email,
    p.name_ar AS permission_name_ar,
    up.valid_until,
    up.grant_reason,
    DATEDIFF(up.valid_until, CURRENT_DATE) AS days_remaining,
    granter.username AS granted_by_username
FROM user_permissions up
JOIN users u ON up.user_id = u.id
JOIN permissions p ON up.permission_id = p.id
LEFT JOIN users granter ON up.granted_by = granter.id
WHERE up.revoked_at IS NULL
  AND up.valid_until IS NOT NULL
  AND up.valid_until BETWEEN CURRENT_DATE AND DATE_ADD(CURRENT_DATE, INTERVAL 7 DAY)
ORDER BY up.valid_until ASC;

-- -----------------------------------------------------------------------------
-- 2.6.5 Stored Procedures للصلاحيات المباشرة
-- -----------------------------------------------------------------------------
DELIMITER //

-- منح صلاحية مباشرة لمستخدم
CREATE PROCEDURE IF NOT EXISTS sp_grant_user_permission(
    IN p_user_id INT UNSIGNED,
    IN p_permission_name VARCHAR(100),
    IN p_valid_days INT UNSIGNED,
    IN p_grant_reason TEXT,
    IN p_notes VARCHAR(500),
    IN p_granted_by INT UNSIGNED
)
BEGIN
    DECLARE v_permission_id SMALLINT UNSIGNED;
    DECLARE v_permission_name_ar VARCHAR(100);
    DECLARE v_username VARCHAR(50);
    DECLARE v_valid_from DATE DEFAULT CURRENT_DATE;
    DECLARE v_valid_until DATE;
    
    -- حساب تاريخ الانتهاء (0 = دائمة)
    IF p_valid_days > 0 THEN
        SET v_valid_until = DATE_ADD(v_valid_from, INTERVAL p_valid_days DAY);
    ELSE
        SET v_valid_until = NULL;
    END IF;
    
    -- التحقق من وجود المستخدم
    SELECT username INTO v_username FROM users WHERE id = p_user_id AND is_active = TRUE;
    IF v_username IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'المستخدم غير موجود أو غير نشط';
    END IF;
    
    -- التحقق من وجود الصلاحية (بالاسم)
    SELECT id, name_ar INTO v_permission_id, v_permission_name_ar 
    FROM permissions WHERE name = p_permission_name;
    IF v_permission_id IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'الصلاحية غير موجودة';
    END IF;
    
    -- إدراج أو تحديث الصلاحية
    INSERT INTO user_permissions (
        user_id, permission_id, valid_from, valid_until, 
        grant_reason, notes, granted_by
    )
    VALUES (
        p_user_id, v_permission_id, v_valid_from, v_valid_until,
        p_grant_reason, p_notes, p_granted_by
    )
    ON DUPLICATE KEY UPDATE 
        valid_from = v_valid_from,
        valid_until = v_valid_until,
        grant_reason = p_grant_reason,
        notes = p_notes,
        granted_by = p_granted_by,
        granted_at = CURRENT_TIMESTAMP,
        revoked_at = NULL,
        revoked_by = NULL,
        revoke_reason = NULL;
    
    -- تسجيل في سجل التدقيق
    INSERT INTO audit_log (user_id, action, table_name, new_values)
    VALUES (p_granted_by, 'GRANT_PERMISSION', 'user_permissions', 
            JSON_OBJECT(
                'target_user_id', p_user_id,
                'target_username', v_username,
                'permission', p_permission_name,
                'permission_ar', v_permission_name_ar,
                'valid_days', p_valid_days,
                'valid_until', v_valid_until,
                'reason', p_grant_reason
            ));
    
    SELECT 'تم منح الصلاحية بنجاح' AS message,
           v_username AS username,
           v_permission_name_ar AS permission,
           v_valid_from AS valid_from,
           v_valid_until AS valid_until,
           p_valid_days AS valid_days;
END //

-- سحب صلاحية من مستخدم
CREATE PROCEDURE IF NOT EXISTS sp_revoke_user_permission(
    IN p_user_id INT UNSIGNED,
    IN p_permission_name VARCHAR(100),
    IN p_revoke_reason VARCHAR(255),
    IN p_revoked_by INT UNSIGNED
)
BEGIN
    DECLARE v_permission_id SMALLINT UNSIGNED;
    DECLARE v_permission_name_ar VARCHAR(100);
    DECLARE v_username VARCHAR(50);
    DECLARE v_affected INT DEFAULT 0;
    
    -- جلب البيانات
    SELECT id, name_ar INTO v_permission_id, v_permission_name_ar 
    FROM permissions WHERE name = p_permission_name;
    SELECT username INTO v_username FROM users WHERE id = p_user_id;
    
    -- سحب الصلاحية
    UPDATE user_permissions 
    SET revoked_at = CURRENT_TIMESTAMP,
        revoked_by = p_revoked_by,
        revoke_reason = p_revoke_reason
    WHERE user_id = p_user_id 
      AND permission_id = v_permission_id 
      AND revoked_at IS NULL;
    
    SET v_affected = ROW_COUNT();
    
    IF v_affected = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'الصلاحية غير موجودة أو ملغاة مسبقاً';
    END IF;
    
    -- تسجيل في سجل التدقيق
    INSERT INTO audit_log (user_id, action, table_name, new_values)
    VALUES (p_revoked_by, 'REVOKE_PERMISSION', 'user_permissions',
            JSON_OBJECT(
                'target_user_id', p_user_id,
                'target_username', v_username,
                'permission', p_permission_name,
                'permission_ar', v_permission_name_ar,
                'reason', p_revoke_reason
            ));
    
    SELECT 'تم سحب الصلاحية بنجاح' AS message,
           v_username AS username,
           v_permission_name_ar AS permission;
END //

-- إلغاء الصلاحيات المنتهية آلياً
CREATE PROCEDURE IF NOT EXISTS sp_revoke_expired_permissions()
BEGIN
    DECLARE v_count INT DEFAULT 0;
    
    UPDATE user_permissions 
    SET revoked_at = CURRENT_TIMESTAMP,
        revoke_reason = 'انتهاء تلقائي - انتهت فترة الصلاحية'
    WHERE valid_until < CURRENT_DATE 
      AND revoked_at IS NULL;
    
    SET v_count = ROW_COUNT();
    
    IF v_count > 0 THEN
        INSERT INTO audit_log (action, table_name, new_values)
        VALUES ('AUTO_REVOKE_EXPIRED', 'user_permissions', 
                JSON_OBJECT(
                    'revoked_count', v_count, 
                    'revoked_at', NOW(),
                    'trigger', 'scheduled_job'
                ));
    END IF;
    
    SELECT v_count AS permissions_revoked, 
           CASE WHEN v_count > 0 THEN 'تم إلغاء الصلاحيات المنتهية' ELSE 'لا توجد صلاحيات منتهية' END AS message;
END //

-- تمديد صلاحية
CREATE PROCEDURE IF NOT EXISTS sp_extend_user_permission(
    IN p_user_id INT UNSIGNED,
    IN p_permission_name VARCHAR(100),
    IN p_additional_days INT UNSIGNED,
    IN p_extended_by INT UNSIGNED
)
BEGIN
    DECLARE v_permission_id SMALLINT UNSIGNED;
    DECLARE v_old_valid_until DATE;
    DECLARE v_new_valid_until DATE;
    DECLARE v_username VARCHAR(50);
    DECLARE v_permission_name_ar VARCHAR(100);
    
    -- جلب البيانات
    SELECT id, name_ar INTO v_permission_id, v_permission_name_ar 
    FROM permissions WHERE name = p_permission_name;
    
    SELECT up.valid_until, u.username 
    INTO v_old_valid_until, v_username
    FROM user_permissions up
    JOIN users u ON up.user_id = u.id
    WHERE up.user_id = p_user_id AND up.permission_id = v_permission_id AND up.revoked_at IS NULL;
    
    IF v_username IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'الصلاحية غير موجودة أو ملغاة';
    END IF;
    
    -- حساب التاريخ الجديد
    SET v_new_valid_until = DATE_ADD(COALESCE(v_old_valid_until, CURRENT_DATE), INTERVAL p_additional_days DAY);
    
    -- تحديث
    UPDATE user_permissions 
    SET valid_until = v_new_valid_until,
        notes = CONCAT(COALESCE(notes, ''), ' | تمديد: +', p_additional_days, ' يوم')
    WHERE user_id = p_user_id AND permission_id = v_permission_id;
    
    -- تسجيل
    INSERT INTO audit_log (user_id, action, table_name, old_values, new_values)
    VALUES (p_extended_by, 'EXTEND_PERMISSION', 'user_permissions',
            JSON_OBJECT('valid_until', v_old_valid_until),
            JSON_OBJECT(
                'target_user_id', p_user_id,
                'target_username', v_username,
                'permission_ar', v_permission_name_ar,
                'additional_days', p_additional_days,
                'new_valid_until', v_new_valid_until
            ));
    
    SELECT 'تم تمديد الصلاحية بنجاح' AS message,
           v_username AS username,
           v_permission_name_ar AS permission,
           v_old_valid_until AS old_valid_until,
           v_new_valid_until AS new_valid_until;
END //

-- التحقق من صلاحية مستخدم
CREATE FUNCTION IF NOT EXISTS fn_check_user_permission(
    p_user_id INT UNSIGNED,
    p_permission_name VARCHAR(100)
) RETURNS BOOLEAN
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_has_permission BOOLEAN DEFAULT FALSE;
    
    -- التحقق من صلاحيات الدور
    SELECT TRUE INTO v_has_permission
    FROM user_roles ur
    JOIN role_permissions rp ON ur.role_id = rp.role_id
    JOIN permissions p ON rp.permission_id = p.id
    WHERE ur.user_id = p_user_id AND p.name = p_permission_name
    LIMIT 1;
    
    IF v_has_permission THEN
        RETURN TRUE;
    END IF;
    
    -- التحقق من الصلاحيات المباشرة
    SELECT TRUE INTO v_has_permission
    FROM user_permissions up
    JOIN permissions p ON up.permission_id = p.id
    WHERE up.user_id = p_user_id 
      AND p.name = p_permission_name
      AND up.revoked_at IS NULL
      AND up.valid_from <= CURRENT_DATE
      AND (up.valid_until IS NULL OR up.valid_until >= CURRENT_DATE)
    LIMIT 1;
    
    RETURN COALESCE(v_has_permission, FALSE);
END //

DELIMITER ;

-- -----------------------------------------------------------------------------
-- 2.6 جدول الجلسات
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS sessions (
    id VARCHAR(128) PRIMARY KEY,
    user_id INT UNSIGNED NOT NULL,
    ip_address VARCHAR(45) NULL,
    user_agent VARCHAR(255) NULL,
    payload TEXT NULL,
    last_activity TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    expires_at TIMESTAMP NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    INDEX idx_user (user_id),
    INDEX idx_expires (expires_at),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='جلسات المستخدمين';

-- -----------------------------------------------------------------------------
-- 2.7 جدول سجل التدقيق
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS audit_log (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id INT UNSIGNED NULL,
    action VARCHAR(50) NOT NULL COMMENT 'CREATE, UPDATE, DELETE, LOGIN, etc.',
    table_name VARCHAR(64) NULL,
    record_id INT UNSIGNED NULL,
    old_values JSON NULL,
    new_values JSON NULL,
    ip_address VARCHAR(45) NULL,
    user_agent VARCHAR(255) NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    INDEX idx_user (user_id),
    INDEX idx_action (action),
    INDEX idx_table (table_name),
    INDEX idx_created (created_at),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='سجل التدقيق - INSERT ONLY';

-- ═══════════════════════════════════════════════════════════════════════════════
-- القسم 3: الجغرافيا (Geography)
-- ═══════════════════════════════════════════════════════════════════════════════

-- -----------------------------------------------------------------------------
-- 3.1 جدول المحافظات
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS governorates (
    id TINYINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name_ar VARCHAR(50) NOT NULL,
    name_en VARCHAR(50) NULL,
    code VARCHAR(10) NULL UNIQUE,
    is_active BOOLEAN DEFAULT TRUE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='المحافظات';

INSERT INTO governorates (name_ar, code) VALUES
('صنعاء', 'SAN'),
('عدن', 'ADN'),
('تعز', 'TAZ'),
('الحديدة', 'HOD'),
('إب', 'IBB'),
('ذمار', 'DHM'),
('حضرموت', 'HDR'),
('المهرة', 'MHR'),
('شبوة', 'SHB'),
('أبين', 'ABY'),
('لحج', 'LAH'),
('الضالع', 'DAL'),
('البيضاء', 'BAY'),
('مأرب', 'MAR'),
('الجوف', 'JOF'),
('صعدة', 'SAD'),
('حجة', 'HAJ'),
('المحويت', 'MAH'),
('ريمة', 'RAY'),
('عمران', 'AMR'),
('سقطرى', 'SOC');

-- -----------------------------------------------------------------------------
-- 3.2 جدول المديريات
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS directorates (
    id SMALLINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    governorate_id TINYINT UNSIGNED NOT NULL,
    name_ar VARCHAR(50) NOT NULL,
    code VARCHAR(10) NULL,
    is_active BOOLEAN DEFAULT TRUE,
    
    INDEX idx_gov (governorate_id),
    FOREIGN KEY (governorate_id) REFERENCES governorates(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='المديريات';

-- -----------------------------------------------------------------------------
-- 3.3 جدول العزل
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS sub_districts (
    id SMALLINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    directorate_id SMALLINT UNSIGNED NOT NULL,
    name_ar VARCHAR(50) NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    
    INDEX idx_dir (directorate_id),
    FOREIGN KEY (directorate_id) REFERENCES directorates(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='العزل';

-- -----------------------------------------------------------------------------
-- 3.4 جدول القرى
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS villages (
    id MEDIUMINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    sub_district_id SMALLINT UNSIGNED NOT NULL,
    name_ar VARCHAR(50) NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    
    INDEX idx_sub (sub_district_id),
    FOREIGN KEY (sub_district_id) REFERENCES sub_districts(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='القرى';

-- -----------------------------------------------------------------------------
-- 3.5 جدول المحلات
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS localities (
    id MEDIUMINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    village_id MEDIUMINT UNSIGNED NULL,
    directorate_id SMALLINT UNSIGNED NULL COMMENT 'للمناطق الحضرية',
    name_ar VARCHAR(50) NOT NULL,
    locality_type ENUM('ريف', 'حضر') DEFAULT 'ريف',
    is_active BOOLEAN DEFAULT TRUE,
    
    INDEX idx_village (village_id),
    INDEX idx_directorate (directorate_id),
    FOREIGN KEY (village_id) REFERENCES villages(id),
    FOREIGN KEY (directorate_id) REFERENCES directorates(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='المحلات/الأحياء';

-- ═══════════════════════════════════════════════════════════════════════════════
-- القسم 4: المرفقات والتقويم
-- ═══════════════════════════════════════════════════════════════════════════════

-- -----------------------------------------------------------------------------
-- 4.1 جدول المرفقات المركزي
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS file_attachments (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    entity_type VARCHAR(50) NOT NULL COMMENT 'اسم الجدول المرتبط',
    entity_id INT UNSIGNED NOT NULL COMMENT 'معرف السجل',
    file_name VARCHAR(255) NOT NULL COMMENT 'اسم الملف الأصلي',
    file_path VARCHAR(500) NOT NULL COMMENT 'مسار التخزين',
    file_type VARCHAR(50) NULL COMMENT 'نوع الملف MIME',
    file_size INT UNSIGNED NULL COMMENT 'الحجم بالبايت',
    file_category VARCHAR(50) NULL COMMENT 'تصنيف الملف',
    description TEXT NULL,
    uploaded_by INT UNSIGNED NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL,
    
    INDEX idx_entity (entity_type, entity_id),
    INDEX idx_category (file_category),
    FOREIGN KEY (uploaded_by) REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='المرفقات المركزية - INSERT + READ للجميع';

-- -----------------------------------------------------------------------------
-- 4.2 جدول التقويم الرئيسي
-- -----------------------------------------------------------------------------
-- -----------------------------------------------------------------------------
-- 4.2 جدول التقويم الرئيسي (Enhanced for CAL-ENH-2026-001 Full Spec)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS calendar_master (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    gregorian_date DATE NOT NULL UNIQUE,
    -- الهجري القياسي
    hijri_date VARCHAR(10) NOT NULL COMMENT 'YYYY-MM-DD هجري قياسي',
    hijri_day TINYINT UNSIGNED NOT NULL,
    hijri_month TINYINT UNSIGNED NOT NULL,
    hijri_year SMALLINT UNSIGNED NOT NULL,
    hijri_month_name VARCHAR(20) NOT NULL,
    -- معلومات اليوم
    day_of_week TINYINT UNSIGNED NOT NULL COMMENT '1=السبت ... 7=الجمعة',
    day_name_ar VARCHAR(20) NOT NULL,
    is_weekend BOOLEAN DEFAULT FALSE,
    -- الحقول الجديدة (Detailed Update 2026)
    is_school_day BOOLEAN DEFAULT TRUE COMMENT 'يوم دراسي (ليس عطلة ولا نهاية أسبوع)',
    academic_year_id INT UNSIGNED NULL COMMENT 'ربط بالسنة الأكاديمية',
    semester TINYINT UNSIGNED NULL COMMENT 'الفصل الدراسي (1 أو 2)',
    academic_week TINYINT UNSIGNED NULL COMMENT 'رقم الأسبوع الدراسي 1-52',
    is_adjusted BOOLEAN DEFAULT FALSE COMMENT 'هل تم تعديل التاريخ يدوياً',
    adjusted_at TIMESTAMP NULL COMMENT 'وقت التعديل',
    adjusted_by INT UNSIGNED NULL COMMENT 'من قام بالتعديل',
    
    is_holiday BOOLEAN DEFAULT FALSE,
    holiday_name VARCHAR(100) NULL,
    
    INDEX idx_gregorian (gregorian_date),
    INDEX idx_hijri (hijri_year, hijri_month, hijri_day),
    INDEX idx_school_day (is_school_day, gregorian_date),
    INDEX idx_academic_year (academic_year_id),
    FOREIGN KEY (adjusted_by) REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='التقويم الهجري/الميلادي الشامل';

-- -----------------------------------------------------------------------------
-- 4.3 جدول إعدادات التقويم
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS calendar_settings (
    id TINYINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    setting_key VARCHAR(50) NOT NULL UNIQUE,
    setting_value VARCHAR(255) NOT NULL,
    description TEXT NULL,
    updated_at TIMESTAMP NULL ON UPDATE CURRENT_TIMESTAMP,
    updated_by INT UNSIGNED NULL COMMENT 'المستخدم الذي أجرى التعديل'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='إعدادات التقويم';

INSERT INTO calendar_settings (setting_key, setting_value, description) VALUES
('default_calendar', 'hijri', 'التقويم الافتراضي للعرض'),
('weekend_days', '7', 'أيام نهاية الأسبوع (6=الخميس, 7=الجمعة)'),
('date_format_hijri', 'YYYY/MM/DD', 'صيغة التاريخ الهجري'),
('date_format_gregorian', 'YYYY-MM-DD', 'صيغة التاريخ الميلادي'),
-- New Settings (Detailed Spec)
('hijri_calendar_type', 'umm_alqura', 'نوع التقويم الهجري'),
('week_start_day', '1', 'يوم بداية الأسبوع (1=السبت)'),
('auto_calculate_school_days', 'true', 'حساب أيام الدراسة تلقائياً');

-- -----------------------------------------------------------------------------
-- 4.4 جدول سجل تعديلات التقويم (Calendar Audit Log)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS calendar_adjustments_log (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    adjustment_date DATE NOT NULL,
    hijri_year SMALLINT UNSIGNED NOT NULL,
    hijri_month TINYINT UNSIGNED NOT NULL,
    adjustment_type ENUM('moon_sighting', 'holiday_add', 'holiday_remove', 'school_day_toggle', 'other') NOT NULL,
    offset_days TINYINT NULL,
    reason TEXT NOT NULL,
    affected_records INT UNSIGNED NULL,
    adjusted_by INT UNSIGNED NOT NULL,
    adjusted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (adjusted_by) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='سجل تعديلات التقويم (INSERT ONLY)';

-- -----------------------------------------------------------------------------
-- 4.5 Views البنية التحتية للتقويم
-- -----------------------------------------------------------------------------

-- View: أيام الدراسة فقط
CREATE OR REPLACE VIEW v_school_days AS 
SELECT * FROM calendar_master 
WHERE is_school_day = TRUE AND is_weekend = FALSE AND is_holiday = FALSE;

-- View: ملخص شهري للتقويم
CREATE OR REPLACE VIEW v_monthly_calendar_summary AS 
SELECT  
   hijri_year, hijri_month, hijri_month_name, 
   COUNT(*) AS total_days, 
   SUM(CASE WHEN is_school_day THEN 1 ELSE 0 END) AS school_days, 
   SUM(CASE WHEN is_holiday THEN 1 ELSE 0 END) AS holidays, 
   SUM(CASE WHEN is_weekend THEN 1 ELSE 0 END) AS weekends, 
   SUM(CASE WHEN is_adjusted THEN 1 ELSE 0 END) AS adjusted_days 
FROM calendar_master 
GROUP BY hijri_year, hijri_month, hijri_month_name;

-- View: قائمة العطل
CREATE OR REPLACE VIEW v_holidays AS 
SELECT gregorian_date, hijri_date, holiday_name 
FROM calendar_master 
WHERE is_holiday = TRUE AND holiday_name IS NOT NULL;

-- -----------------------------------------------------------------------------
-- 4.6 Stored Procedures (إجراءات التقويم)
-- -----------------------------------------------------------------------------

DELIMITER //

-- تعديل التقويم بناءً على رؤية الهلال
CREATE PROCEDURE IF NOT EXISTS sp_adjust_moon_sighting(
    IN p_year INT,
    IN p_month INT,
    IN p_adjustment INT,
    IN p_reason TEXT,
    IN p_user_id INT
)
BEGIN
    INSERT INTO calendar_adjustments_log (adjustment_date, hijri_year, hijri_month, adjustment_type, offset_days, reason, adjusted_by)
    VALUES (CURDATE(), p_year, p_month, 'moon_sighting', p_adjustment, p_reason, p_user_id);
    
    -- المنطق الفعلي لتحديث التواريخ سيتطلب دالة حسابية معقدة يتم تنفيذها هنا
    UPDATE calendar_master 
    SET is_adjusted = TRUE, adjusted_at = NOW(), adjusted_by = p_user_id
    WHERE hijri_year = p_year AND hijri_month = p_month;
END //

-- إدارة العطل
CREATE PROCEDURE IF NOT EXISTS sp_manage_holiday(
    IN p_date DATE,
    IN p_name VARCHAR(100),
    IN p_action VARCHAR(10), -- add, remove
    IN p_user_id INT
)
BEGIN
    IF p_action = 'add' THEN
        UPDATE calendar_master 
        SET is_holiday = TRUE, holiday_name = p_name, is_school_day = FALSE
        WHERE gregorian_date = p_date;
        
        INSERT INTO calendar_adjustments_log (adjustment_date, hijri_year, hijri_month, adjustment_type, reason, adjusted_by)
        SELECT CURDATE(), hijri_year, hijri_month, 'holiday_add', CONCAT('Add holiday: ', p_name), p_user_id
        FROM calendar_master WHERE gregorian_date = p_date;
        
    ELSEIF p_action = 'remove' THEN
        UPDATE calendar_master 
        SET is_holiday = FALSE, holiday_name = NULL, is_school_day = TRUE -- افتراض أنه يعود دراسي
        WHERE gregorian_date = p_date;
        
        INSERT INTO calendar_adjustments_log (adjustment_date, hijri_year, hijri_month, adjustment_type, reason, adjusted_by)
        SELECT CURDATE(), hijri_year, hijri_month, 'holiday_remove', 'Remove holiday', p_user_id
        FROM calendar_master WHERE gregorian_date = p_date;
    END IF;
END //

-- حساب أيام الدراسة
CREATE PROCEDURE IF NOT EXISTS sp_calculate_school_days(IN p_year_gregorian INT)
BEGIN
    UPDATE calendar_master 
    SET is_school_day = CASE 
        WHEN is_weekend = TRUE OR is_holiday = TRUE THEN FALSE 
        ELSE TRUE 
    END
    WHERE YEAR(gregorian_date) = p_year_gregorian;
END //

-- ربط التقويم بالسنة الأكاديمية
CREATE PROCEDURE IF NOT EXISTS sp_link_calendar_to_academic_year(
    IN p_academic_year_id INT,
    IN p_start_date DATE,
    IN p_end_date DATE
)
BEGIN
    UPDATE calendar_master 
    SET academic_year_id = p_academic_year_id
    WHERE gregorian_date BETWEEN p_start_date AND p_end_date;
END //

DELIMITER ;

-- ═══════════════════════════════════════════════════════════════════════════════
-- القسم 5: الجداول المرجعية الإضافية (تحديث 2026-01-19)
-- ═══════════════════════════════════════════════════════════════════════════════

-- -----------------------------------------------------------------------------
-- 5.1 جدول الأشهر الهجرية
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS lookup_hijri_months (
    id TINYINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name_ar VARCHAR(30) NOT NULL,
    order_num TINYINT UNSIGNED NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='الأشهر الهجرية';

INSERT INTO lookup_hijri_months (name_ar, order_num) VALUES
('محرم', 1), ('صفر', 2), ('ربيع أول', 3), ('ربيع ثاني', 4),
('جماد أول', 5), ('جماد ثاني', 6), ('رجب', 7), ('شعبان', 8),
('رمضان', 9), ('شوال', 10), ('ذو القعدة', 11), ('ذو الحجة', 12), ('أخرى', 13);

-- -----------------------------------------------------------------------------
-- 5.2 جدول الأسابيع
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS lookup_weeks (
    id TINYINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name_ar VARCHAR(20) NOT NULL,
    order_num TINYINT UNSIGNED NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='أسابيع الشهر';

-- -----------------------------------------------------------------------------
-- 5.2.1 جدول المباني المدرسية (جديد)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS lookup_buildings (
    id TINYINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name_ar VARCHAR(50) NOT NULL,
    is_active BOOLEAN DEFAULT TRUE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='المباني المدرسية';

INSERT INTO lookup_buildings (name_ar) VALUES
('المدرسة الجديدة'),
('المدرسة القديمة'),
('أخرى');

INSERT INTO lookup_weeks (name_ar, order_num) VALUES
('الأول', 1), ('الثاني', 2), ('الثالث', 3), ('الرابع', 4), ('الخامس', 5), ('أخرى', 6);

-- -----------------------------------------------------------------------------
-- 5.3 جدول إعدادات النظام
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS system_settings (
    id TINYINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    setting_key VARCHAR(100) NOT NULL UNIQUE,
    setting_value TEXT NULL,
    setting_type ENUM('text', 'number', 'boolean', 'image', 'json') DEFAULT 'text',
    category VARCHAR(50) NULL,
    description TEXT NULL,
    is_editable BOOLEAN DEFAULT TRUE,
    updated_at TIMESTAMP NULL ON UPDATE CURRENT_TIMESTAMP,
    updated_by INT UNSIGNED NULL,
    
    INDEX idx_category (category),
    FOREIGN KEY (updated_by) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='إعدادات النظام';

INSERT INTO system_settings (setting_key, setting_value, setting_type, category, description) VALUES
-- الهوية البصرية
('founder_name', 'خالد شبيطه', 'text', 'identity', 'اسم مؤسس الموقع'),
('founder_year', '١٤٤٧هـ', 'text', 'identity', 'عام التأسيس'),
('company_name', 'شركةون  سوفت للحلول التقنية', 'text', 'identity', 'اسم الشركة'),
('republic_logo', NULL, 'image', 'identity', 'شعار الجمهورية'),
('curriculum_logo', NULL, 'image', 'identity', 'شعار المناهج'),
-- رأس التقارير
('report_header_line1', 'الجمهورية اليمنية', 'text', 'reports', 'السطر الأول من رأس التقرير'),
('report_header_line2', 'وزارة التربية والتعليم', 'text', 'reports', 'السطر الثاني'),
('report_header_line3', 'مكتب التربية والتعليم بمحافظة إب', 'text', 'reports', 'السطر الثالث'),
('report_header_line4', 'الإدارة التعليمية بمديرية العدين', 'text', 'reports', 'السطر الرابع'),
-- الإعدادات العامة
('default_date_format', 'hijri', 'text', 'general', 'صيغة التاريخ الافتراضية'),
('session_timeout_hours', '24', 'number', 'security', 'مدة انتهاء الجلسة بالساعات'),
('allow_grade_edit', 'true', 'boolean', 'grades', 'السماح بتعديل الدرجات'),
('report_footer_text', 'يعتبر هذا الكشف رسمي ولا يحتاج إلى ختم', 'text', 'reports', 'نص تذييل التقارير الرسمي');

-- -----------------------------------------------------------------------------
-- 5.4 جدول الأذكار والتنبيهات
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS reminders_ticker (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    content TEXT NOT NULL,
    ticker_type ENUM('ذكر', 'تنبيه', 'إعلان', 'آية', 'حديث') DEFAULT 'ذكر',
    is_active BOOLEAN DEFAULT TRUE,
    display_order TINYINT UNSIGNED DEFAULT 0,
    start_date DATE NULL,
    end_date DATE NULL,
    created_by INT UNSIGNED NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    INDEX idx_type (ticker_type),
    INDEX idx_active (is_active),
    FOREIGN KEY (created_by) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='الأذكار والتنبيهات المتحركة';

INSERT INTO reminders_ticker (content, ticker_type) VALUES
('سبحان الله وبحمده، سبحان الله العظيم', 'ذكر'),
('لا حول ولا قوة إلا بالله', 'ذكر'),
('اللهم صلِّ وسلم على نبينا محمد', 'ذكر'),
('ربِّ اشرح لي صدري ويسِّر لي أمري', 'ذكر');

-- ═══════════════════════════════════════════════════════════════════════════════
-- القسم 6: الصلاحيات التفصيلية (تحديث 2026-01-19)
-- ═══════════════════════════════════════════════════════════════════════════════

INSERT INTO permissions (name, name_ar, module) VALUES
-- الطلاب - تفصيلي
('students.preview', 'معاينة الطلاب', 'students'),
('students.print', 'طباعة بيانات الطلاب', 'students'),
-- الموظفين - تفصيلي
('employees.preview', 'معاينة الموظفين', 'employees'),
('employees.create', 'إضافة موظف', 'employees'),
('employees.edit', 'تعديل موظف', 'employees'),
('employees.delete', 'حذف موظف', 'employees'),
('employees.export', 'تصدير بيانات الموظفين', 'employees'),
('employees.print', 'طباعة بيانات الموظفين', 'employees'),
-- الدرجات - تفصيلي
('grades.preview', 'معاينة الدرجات', 'grades'),
('grades.delete', 'حذف الدرجات', 'grades'),
('grades.export', 'تصدير الدرجات', 'grades'),
('grades.print', 'طباعة الدرجات', 'grades'),
-- الحضور - تفصيلي
('attendance.preview', 'معاينة الحضور', 'attendance'),
('attendance.export', 'تصدير الحضور', 'attendance'),
('attendance.delete', 'حذف سجل حضور', 'attendance'),
-- الاجتماعات
('meetings.view', 'عرض الاجتماعات', 'meetings'),
('meetings.create', 'إضافة اجتماع', 'meetings'),
('meetings.edit', 'تعديل اجتماع', 'meetings'),
('meetings.delete', 'حذف اجتماع', 'meetings'),
('meetings.export', 'تصدير محاضر الاجتماعات', 'meetings'),
-- الزائرين
('visitors.view', 'عرض الزائرين', 'visitors'),
('visitors.create', 'إضافة زائر', 'visitors'),
('visitors.edit', 'تعديل زائر', 'visitors'),
('visitors.delete', 'حذف زائر', 'visitors'),
('visitors.export', 'تصدير سجل الزائرين', 'visitors'),
-- المسابقات
('competitions.view', 'عرض المسابقات', 'competitions'),
('competitions.create', 'إضافة مسابقة', 'competitions'),
('competitions.edit', 'تعديل مسابقة', 'competitions'),
('competitions.delete', 'حذف مسابقة', 'competitions'),
('competitions.export', 'تصدير نتائج المسابقات', 'competitions'),
-- الأنشطة
('activities.view', 'عرض الأنشطة', 'activities'),
('activities.create', 'إضافة نشاط', 'activities'),
('activities.edit', 'تعديل نشاط', 'activities'),
('activities.delete', 'حذف نشاط', 'activities'),
('activities.export', 'تصدير الأنشطة', 'activities'),
-- الخطط
('plans.view', 'عرض الخطط', 'plans'),
('plans.create', 'إضافة خطة', 'plans'),
('plans.edit', 'تعديل خطة', 'plans'),
('plans.delete', 'حذف خطة', 'plans'),
('plans.export', 'تصدير الخطط', 'plans'),
-- المالي
('finance.view', 'عرض المالية', 'finance'),
('finance.create', 'إضافة قيد مالي', 'finance'),
('finance.edit', 'تعديل قيد مالي', 'finance'),
('finance.delete', 'حذف قيد مالي', 'finance'),
('finance.export', 'تصدير التقارير المالية', 'finance'),
('finance.approve', 'اعتماد العمليات المالية', 'finance');

-- منح الصلاحيات الجديدة لمدير النظام
INSERT INTO role_permissions (role_id, permission_id)
SELECT 1, id FROM permissions WHERE id > 18;

-- ═══════════════════════════════════════════════════════════════════════════════
-- نهاية الجزء 1: البنية التحتية المشتركة
-- ═══════════════════════════════════════════════════════════════════════════════

-- ╔══════════════════════════════════════════════════════════════════════════════╗
-- ║  الملخص (محدّث 2026-01-19):                                                  ║
-- ║  - 15 جدول Lookup (شامل الأشهر الهجرية والأسابيع)                            ║
-- ║  - 7 جداول RBAC                                                              ║
-- ║  - 5 جداول Geography                                                         ║
-- ║  - 3 جداول Calendar + Attachments                                            ║
-- ║  - 2 جداول إعدادات (system_settings, reminders_ticker)                       ║
-- ║  ─────────────────────────────────────────────                               ║
-- ║  المجموع: 32 جدول (كان 26)                                                   ║
-- ║  الصلاحيات: 60+ صلاحية تفصيلية                                               ║
-- ╚══════════════════════════════════════════════════════════════════════════════╝
-- -----------------------------------------------------------------------------
-- 5.5 بذر بيانات الجغرافيا (مديرية العدين - إب)
-- -----------------------------------------------------------------------------
-- إدراج مديرية العدين (تابعة لمحافظة إب ID=6) إذا لم تكن موجودة
INSERT INTO directorates (governorate_id, name_ar) 
SELECT 6, 'العدين' WHERE NOT EXISTS (SELECT 1 FROM directorates WHERE name_ar = 'العدين');

-- الحصول على معرف المديرية
SET @dir_id = (SELECT id FROM directorates WHERE name_ar = 'العدين' LIMIT 1);

-- إدراج العزل (Sub-districts)
INSERT INTO sub_districts (directorate_id, name_ar) 
SELECT @dir_id, name_ar FROM (
    SELECT 'منهات' AS name_ar
    UNION SELECT 'بني عواض'
) AS tmp WHERE NOT EXISTS (SELECT 1 FROM sub_districts WHERE directorate_id = @dir_id AND name_ar = tmp.name_ar);

SET @sub_manhat = (SELECT id FROM sub_districts WHERE name_ar = 'منهات' AND directorate_id = @dir_id LIMIT 1);
SET @sub_bani = (SELECT id FROM sub_districts WHERE name_ar = 'بني عواض' AND directorate_id = @dir_id LIMIT 1);

-- إدراج القرى (Villages) - الافتراضي: نربطها بمنهات (يمكن للمدير تغييرها لاحقاً)
INSERT INTO villages (sub_district_id, name_ar)
SELECT @sub_manhat, name_ar FROM (
    SELECT 'وادي النخلة' AS name_ar
    UNION SELECT 'النخلة'
    UNION SELECT 'بردان'
    UNION SELECT 'المفرق'
    UNION SELECT 'المسرب'
    UNION SELECT 'بيت الشبر'
    UNION SELECT 'العوارض'
) AS tmp WHERE NOT EXISTS (SELECT 1 FROM villages WHERE sub_district_id = @sub_manhat AND name_ar = tmp.name_ar);

SET @v_wadi = (SELECT id FROM villages WHERE name_ar = 'وادي النخلة' LIMIT 1);
SET @v_nakh = (SELECT id FROM villages WHERE name_ar = 'النخلة' LIMIT 1);
SET @v_bard = (SELECT id FROM villages WHERE name_ar = 'بردان' LIMIT 1);
SET @v_mafr = (SELECT id FROM villages WHERE name_ar = 'المفرق' LIMIT 1);

-- إدراج المحلات (Localities)
-- 1. وادي النخلة
INSERT INTO localities (village_id, name_ar)
SELECT @v_wadi, name_ar FROM (
    SELECT 'الطوائل' AS name_ar
    UNION SELECT 'شعب الكبير'
    UNION SELECT 'وادي النخلة'
    UNION SELECT 'شرى النقيل'
    UNION SELECT 'الخراشب'
    UNION SELECT 'الجحارة'
    UNION SELECT 'الدمن'
) AS tmp WHERE NOT EXISTS (SELECT 1 FROM localities WHERE village_id = @v_wadi AND name_ar = tmp.name_ar);

-- 2. النخلة
INSERT INTO localities (village_id, name_ar)
SELECT @v_nakh, name_ar FROM (
    SELECT 'الصلبة' AS name_ar
    UNION SELECT 'مجهم العرم'
    UNION SELECT 'المراديح'
    UNION SELECT 'رأس القرية'
    UNION SELECT 'القرية'
    UNION SELECT 'حول أسامة'
    UNION SELECT 'عرض فراص'
    UNION SELECT 'بيت قضابة'
    UNION SELECT 'المرخامة'
    UNION SELECT 'البرحة'
    UNION SELECT 'المجهم'
    UNION SELECT 'دي سويد'
    UNION SELECT 'الراحبة'
    UNION SELECT 'شرى الكدف'
    UNION SELECT 'حول مطيع'
    UNION SELECT 'شرى البارقة'
    UNION SELECT 'رأس البارقة'
    UNION SELECT 'الدرب'
    UNION SELECT 'الهياج'
    UNION SELECT 'بيت الحسام'
    UNION SELECT 'المجاهم'
    UNION SELECT 'ابعرات'
    UNION SELECT 'الحرة'
    UNION SELECT 'الصلاو'
) AS tmp WHERE NOT EXISTS (SELECT 1 FROM localities WHERE village_id = @v_nakh AND name_ar = tmp.name_ar);

-- 3. بردان
INSERT INTO localities (village_id, name_ar)
SELECT @v_bard, name_ar FROM (
    SELECT 'المقبرة' AS name_ar
    UNION SELECT 'شرى بردان'
    UNION SELECT 'بردان'
    UNION SELECT 'الشعب'
    UNION SELECT 'قرية العارضة'
    UNION SELECT 'باب الهيجة'
) AS tmp WHERE NOT EXISTS (SELECT 1 FROM localities WHERE village_id = @v_bard AND name_ar = tmp.name_ar);

-- 4. المفرق
INSERT INTO localities (village_id, name_ar)
SELECT @v_mafr, name_ar FROM (
    SELECT 'القرف' AS name_ar
    UNION SELECT 'دعاشب'
    UNION SELECT 'وادي بردان'
    UNION SELECT 'ضحمه'
) AS tmp WHERE NOT EXISTS (SELECT 1 FROM localities WHERE village_id = @v_mafr AND name_ar = tmp.name_ar);
