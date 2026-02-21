-- ╔══════════════════════════════════════════════════════════════════════════════╗
-- ║                         تطبيق أولياء الأمور                                  ║
-- ║                   Parents App Database Schema                                 ║
-- ║                                                                               ║
-- ║    يشمل: تسجيل الدخول، الجلسات، الإشعارات، الرسائل، طلبات الاستئذان          ║
-- ╚══════════════════════════════════════════════════════════════════════════════╝

-- التاريخ: 2026-01-12
-- الإصدار: 1.0
-- المهندس المسؤول: أحمد الهتار (تصميم) / موسى العواضي (اعتماد)
-- قاعدة البيانات: MySQL 8.0+

-- ═══════════════════════════════════════════════════════════════════════════════
-- القسم 1: جداول Lookup لتطبيق أولياء الأمور
-- ═══════════════════════════════════════════════════════════════════════════════

-- ملاحظة: تم نقل جداول Lookup الخاصة بالإشعارات إلى "البنية المشتركة" (System 01) لتوحيد منطق الاتصال.

-- جدول حالات طلب الاستئذان
CREATE TABLE IF NOT EXISTS lookup_leave_request_statuses (
    id TINYINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name_ar VARCHAR(30) NOT NULL COMMENT 'الحالة بالعربية',
    code VARCHAR(20) NOT NULL UNIQUE COMMENT 'رمز الحالة',
    color VARCHAR(10) COMMENT 'لون العرض',
    is_final BOOLEAN DEFAULT FALSE COMMENT 'حالة نهائية',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='حالات طلب الاستئذان';

INSERT INTO lookup_leave_request_statuses (name_ar, code, color, is_final) VALUES
('قيد المراجعة', 'PENDING', '#FFC107', FALSE),
('موافق عليه', 'APPROVED', '#4CAF50', TRUE),
('مرفوض', 'REJECTED', '#F44336', TRUE),
('ملغي', 'CANCELLED', '#9E9E9E', TRUE);

-- جدول أنواع الاستئذان
CREATE TABLE IF NOT EXISTS lookup_leave_types (
    id TINYINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name_ar VARCHAR(50) NOT NULL COMMENT 'النوع بالعربية',
    code VARCHAR(30) NOT NULL UNIQUE COMMENT 'رمز النوع',
    requires_attachment BOOLEAN DEFAULT FALSE COMMENT 'يتطلب مرفق',
    max_days TINYINT UNSIGNED COMMENT 'الحد الأقصى للأيام',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='أنواع الاستئذان';

INSERT INTO lookup_leave_types (name_ar, code, requires_attachment, max_days) VALUES
('مرض', 'SICK', TRUE, 7),
('موعد طبي', 'MEDICAL_APPOINTMENT', FALSE, 1),
('ظروف عائلية', 'FAMILY', FALSE, 3),
('سفر', 'TRAVEL', FALSE, 14),
('انصراف مبكر', 'EARLY_LEAVE', FALSE, NULL),
('تأخر صباحي', 'LATE_ARRIVAL', FALSE, NULL),
('أخرى', 'OTHER', FALSE, NULL);

-- ═══════════════════════════════════════════════════════════════════════════════
-- القسم 2: حسابات أولياء الأمور
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS parent_accounts (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    
    -- الربط بولي الأمر
    guardian_id INT UNSIGNED NOT NULL COMMENT 'ولي الأمر',
    
    -- بيانات الدخول
    phone_number VARCHAR(20) NOT NULL UNIQUE COMMENT 'رقم الجوال للدخول',
    password_hash VARCHAR(255) NULL COMMENT 'كلمة المرور المشفرة',
    pin_code VARCHAR(10) NULL COMMENT 'رمز PIN للدخول السريع',
    
    -- التحقق
    is_verified BOOLEAN DEFAULT FALSE COMMENT 'تم التحقق من الرقم',
    verification_code VARCHAR(10) NULL COMMENT 'رمز التحقق',
    verification_expires_at TIMESTAMP NULL COMMENT 'انتهاء صلاحية الرمز',
    
    -- الحالة
    is_active BOOLEAN DEFAULT TRUE COMMENT 'الحساب نشط',
    is_locked BOOLEAN DEFAULT FALSE COMMENT 'الحساب مقفل',
    locked_until TIMESTAMP NULL COMMENT 'مقفل حتى',
    failed_login_attempts TINYINT UNSIGNED DEFAULT 0 COMMENT 'محاولات الدخول الفاشلة',
    
    -- آخر نشاط
    last_login_at TIMESTAMP NULL COMMENT 'آخر دخول',
    last_activity_at TIMESTAMP NULL COMMENT 'آخر نشاط',
    
    -- الإعدادات
    language VARCHAR(5) DEFAULT 'ar' COMMENT 'اللغة المفضلة',
    notifications_enabled BOOLEAN DEFAULT TRUE COMMENT 'الإشعارات مفعلة',
    
    -- التدقيق
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NULL ON UPDATE CURRENT_TIMESTAMP,
    created_by_user_id INT UNSIGNED COMMENT 'أنشأه (النظام)',
    
    -- المفاتيح الخارجية
    CONSTRAINT fk_parentacc_guardian FOREIGN KEY (guardian_id) 
        REFERENCES guardians(id) ON DELETE CASCADE,
    CONSTRAINT fk_parentacc_creator FOREIGN KEY (created_by_user_id) 
        REFERENCES users(id) ON DELETE SET NULL,
    
    -- الفهارس
    UNIQUE KEY uk_parentacc_guardian (guardian_id),
    INDEX idx_parentacc_phone (phone_number),
    INDEX idx_parentacc_active (is_active)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='حسابات أولياء الأمور';

-- ═══════════════════════════════════════════════════════════════════════════════
-- القسم 3: جلسات التطبيق
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS parent_sessions (
    id VARCHAR(128) PRIMARY KEY COMMENT 'معرف الجلسة (Token)',
    
    parent_account_id INT UNSIGNED NOT NULL COMMENT 'حساب ولي الأمر',
    
    -- معلومات الجهاز
    device_id VARCHAR(100) COMMENT 'معرف الجهاز',
    device_name VARCHAR(100) COMMENT 'اسم الجهاز',
    device_type ENUM('android', 'ios', 'web') COMMENT 'نوع الجهاز',
    app_version VARCHAR(20) COMMENT 'إصدار التطبيق',
    
    -- الموقع والشبكة
    ip_address VARCHAR(45) COMMENT 'عنوان IP',
    user_agent VARCHAR(255) COMMENT 'معلومات المتصفح',
    
    -- الصلاحية
    expires_at TIMESTAMP NOT NULL COMMENT 'تاريخ انتهاء الجلسة',
    is_active BOOLEAN DEFAULT TRUE COMMENT 'الجلسة نشطة',
    
    -- التوقيت
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_activity_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    -- المفاتيح الخارجية
    CONSTRAINT fk_parentsess_account FOREIGN KEY (parent_account_id) 
        REFERENCES parent_accounts(id) ON DELETE CASCADE,
    
    -- الفهارس
    INDEX idx_parentsess_account (parent_account_id),
    INDEX idx_parentsess_expires (expires_at),
    INDEX idx_parentsess_active (is_active)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='جلسات تطبيق أولياء الأمور';

-- ═══════════════════════════════════════════════════════════════════════════════
-- القسم 4: أجهزة الإشعارات (Push Notifications)
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS parent_devices (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    
    parent_account_id INT UNSIGNED NOT NULL COMMENT 'حساب ولي الأمر',
    
    -- معلومات الجهاز
    device_token VARCHAR(500) NOT NULL COMMENT 'رمز الجهاز للإشعارات',
    device_type ENUM('android', 'ios', 'web') NOT NULL COMMENT 'نوع الجهاز',
    device_name VARCHAR(100) COMMENT 'اسم الجهاز',
    device_model VARCHAR(100) COMMENT 'موديل الجهاز',
    os_version VARCHAR(20) COMMENT 'إصدار نظام التشغيل',
    
    -- الحالة
    is_active BOOLEAN DEFAULT TRUE COMMENT 'نشط',
    last_used_at TIMESTAMP NULL COMMENT 'آخر استخدام',
    
    -- التدقيق
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NULL ON UPDATE CURRENT_TIMESTAMP,
    
    -- المفاتيح الخارجية
    CONSTRAINT fk_parentdev_account FOREIGN KEY (parent_account_id) 
        REFERENCES parent_accounts(id) ON DELETE CASCADE,
    
    -- الفهارس
    UNIQUE KEY uk_parentdev_token (device_token(255)),
    INDEX idx_parentdev_account (parent_account_id),
    INDEX idx_parentdev_active (is_active)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='أجهزة أولياء الأمور للإشعارات';

-- ═══════════════════════════════════════════════════════════════════════════════
-- القسم 5: الإشعارات
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS parent_notifications (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    
    -- المستلم
    parent_account_id INT UNSIGNED NOT NULL COMMENT 'حساب ولي الأمر',
    student_id INT UNSIGNED NULL COMMENT 'الطالب المعني (إن وجد)',
    
    -- نوع ومحتوى الإشعار
    notification_type_id TINYINT UNSIGNED NOT NULL COMMENT 'نوع الإشعار',
    title VARCHAR(200) NOT NULL COMMENT 'عنوان الإشعار',
    body TEXT NOT NULL COMMENT 'محتوى الإشعار',
    
    -- البيانات الإضافية
    data JSON COMMENT 'بيانات إضافية (للتطبيق)',
    action_url VARCHAR(500) COMMENT 'رابط الإجراء',
    
    -- المصدر
    source_type ENUM('نظام', 'معلم', 'إدارة', 'آلي') DEFAULT 'نظام',
    source_id INT UNSIGNED NULL COMMENT 'معرف المصدر',
    
    -- الحالة
    is_read BOOLEAN DEFAULT FALSE COMMENT 'تم القراءة',
    read_at TIMESTAMP NULL COMMENT 'وقت القراءة',
    is_pushed BOOLEAN DEFAULT FALSE COMMENT 'تم الإرسال',
    pushed_at TIMESTAMP NULL COMMENT 'وقت الإرسال',
    
    -- الأهمية
    priority ENUM('عادي', 'مهم', 'عاجل') DEFAULT 'عادي',
    
    -- التدقيق
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP NULL COMMENT 'تاريخ انتهاء الإشعار',
    
    -- المفاتيح الخارجية
    CONSTRAINT fk_parentnotif_account FOREIGN KEY (parent_account_id) 
        REFERENCES parent_accounts(id) ON DELETE CASCADE,
    CONSTRAINT fk_parentnotif_student FOREIGN KEY (student_id) 
        REFERENCES students(id) ON DELETE SET NULL,
    CONSTRAINT fk_parentnotif_type FOREIGN KEY (notification_type_id) 
        REFERENCES lookup_notification_types(id) ON DELETE RESTRICT,
    
    -- الفهارس
    INDEX idx_parentnotif_account (parent_account_id),
    INDEX idx_parentnotif_student (student_id),
    INDEX idx_parentnotif_read (is_read),
    INDEX idx_parentnotif_type (notification_type_id),
    INDEX idx_parentnotif_created (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='إشعارات تطبيق أولياء الأمور';

-- ═══════════════════════════════════════════════════════════════════════════════
-- القسم 6: رسائل المعلم - ولي الأمر
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS parent_teacher_messages (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    
    -- الأطراف
    student_id INT UNSIGNED NOT NULL COMMENT 'الطالب',
    parent_account_id INT UNSIGNED NOT NULL COMMENT 'حساب ولي الأمر',
    employee_id INT UNSIGNED NOT NULL COMMENT 'المعلم',
    
    -- المحادثة
    thread_id VARCHAR(50) COMMENT 'معرف المحادثة',
    
    -- الرسالة
    sender_type ENUM('معلم', 'ولي_أمر') NOT NULL COMMENT 'المرسل',
    message_text TEXT NOT NULL COMMENT 'نص الرسالة',
    
    -- المرفقات
    has_attachment BOOLEAN DEFAULT FALSE COMMENT 'يوجد مرفق',
    attachment_type ENUM('صورة', 'ملف', 'صوت') NULL COMMENT 'نوع المرفق',
    attachment_path VARCHAR(500) NULL COMMENT 'مسار المرفق',
    
    -- الحالة
    is_read BOOLEAN DEFAULT FALSE COMMENT 'تم القراءة',
    read_at TIMESTAMP NULL COMMENT 'وقت القراءة',
    
    -- الأرشفة
    is_archived_by_teacher BOOLEAN DEFAULT FALSE COMMENT 'مؤرشف من المعلم',
    is_archived_by_parent BOOLEAN DEFAULT FALSE COMMENT 'مؤرشف من ولي الأمر',
    
    -- السجل الطلابي
    save_to_student_file BOOLEAN DEFAULT FALSE COMMENT 'حفظ في ملف الطالب',
    saved_at TIMESTAMP NULL COMMENT 'تاريخ الحفظ',
    saved_by_user_id INT UNSIGNED NULL COMMENT 'حفظه',
    
    -- التدقيق
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- المفاتيح الخارجية
    CONSTRAINT fk_ptmsg_student FOREIGN KEY (student_id) 
        REFERENCES students(id) ON DELETE CASCADE,
    CONSTRAINT fk_ptmsg_parent FOREIGN KEY (parent_account_id) 
        REFERENCES parent_accounts(id) ON DELETE CASCADE,
    CONSTRAINT fk_ptmsg_employee FOREIGN KEY (employee_id) 
        REFERENCES employees(id) ON DELETE CASCADE,
    CONSTRAINT fk_ptmsg_saver FOREIGN KEY (saved_by_user_id) 
        REFERENCES users(id) ON DELETE SET NULL,
    
    -- الفهارس
    INDEX idx_ptmsg_thread (thread_id),
    INDEX idx_ptmsg_student (student_id),
    INDEX idx_ptmsg_parent (parent_account_id),
    INDEX idx_ptmsg_employee (employee_id),
    INDEX idx_ptmsg_created (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='رسائل المعلم - ولي الأمر';

-- ═══════════════════════════════════════════════════════════════════════════════
-- القسم 7: طلبات الاستئذان
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS leave_requests (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    
    -- الطالب والطالب
    student_id INT UNSIGNED NOT NULL COMMENT 'الطالب',
    parent_account_id INT UNSIGNED NOT NULL COMMENT 'ولي الأمر المقدم',
    
    -- نوع وتفاصيل الطلب
    leave_type_id TINYINT UNSIGNED NOT NULL COMMENT 'نوع الاستئذان',
    reason TEXT NOT NULL COMMENT 'السبب',
    
    -- التاريخ
    start_date DATE NOT NULL COMMENT 'من تاريخ',
    end_date DATE NOT NULL COMMENT 'حتى تاريخ',
    start_time TIME NULL COMMENT 'من وقت (للانصراف المبكر)',
    
    -- المرفقات
    has_attachment BOOLEAN DEFAULT FALSE COMMENT 'يوجد مرفق',
    attachment_path VARCHAR(500) NULL COMMENT 'مسار المرفق',
    
    -- الحالة
    status_id TINYINT UNSIGNED NOT NULL DEFAULT 1 COMMENT 'حالة الطلب',
    
    -- الرد والقرار (Governance Enhancement)
    response_notes TEXT COMMENT 'ملاحظات الرد',
    approved_by_user_id INT UNSIGNED NULL COMMENT 'صاحب القرار',
    decision_at TIMESTAMP NULL COMMENT 'تاريخ القرار',
    
    -- التدقيق
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NULL ON UPDATE CURRENT_TIMESTAMP,
    
    -- المفاتيح الخارجية
    CONSTRAINT fk_leavereq_student FOREIGN KEY (student_id) 
        REFERENCES students(id) ON DELETE CASCADE,
    CONSTRAINT fk_leavereq_parent FOREIGN KEY (parent_account_id) 
        REFERENCES parent_accounts(id) ON DELETE CASCADE,
    CONSTRAINT fk_leavereq_type FOREIGN KEY (leave_type_id) 
        REFERENCES lookup_leave_types(id) ON DELETE RESTRICT,
    CONSTRAINT fk_leavereq_status FOREIGN KEY (status_id) 
        REFERENCES lookup_leave_request_statuses(id) ON DELETE RESTRICT,
    CONSTRAINT fk_leavereq_responder FOREIGN KEY (approved_by_user_id) 
        REFERENCES users(id) ON DELETE SET NULL,
    
    -- الفهارس
    INDEX idx_leavereq_student (student_id),
    INDEX idx_leavereq_parent (parent_account_id),
    INDEX idx_leavereq_status (status_id),
    INDEX idx_leavereq_dates (start_date, end_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='طلبات استئذان الطلاب';

-- ═══════════════════════════════════════════════════════════════════════════════
-- القسم 8: صلاحيات الوصول للبيانات
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS parent_data_permissions (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    
    parent_account_id INT UNSIGNED NOT NULL COMMENT 'حساب ولي الأمر',
    student_id INT UNSIGNED NOT NULL COMMENT 'الطالب',
    
    -- الصلاحيات
    can_view_grades BOOLEAN DEFAULT TRUE COMMENT 'عرض الدرجات',
    can_view_attendance BOOLEAN DEFAULT TRUE COMMENT 'عرض الحضور',
    can_view_homework BOOLEAN DEFAULT TRUE COMMENT 'عرض الواجبات',
    can_view_behavior BOOLEAN DEFAULT TRUE COMMENT 'عرض السلوك',
    can_view_fees BOOLEAN DEFAULT TRUE COMMENT 'عرض الرسوم',
    can_message_teachers BOOLEAN DEFAULT TRUE COMMENT 'مراسلة المعلمين',
    can_submit_leave_requests BOOLEAN DEFAULT TRUE COMMENT 'تقديم طلبات استئذان',
    can_download_reports BOOLEAN DEFAULT TRUE COMMENT 'تحميل التقارير',
    
    -- فترة الصلاحية
    valid_from DATE DEFAULT (CURRENT_DATE) COMMENT 'صالح من',
    valid_until DATE NULL COMMENT 'صالح حتى',
    
    -- التدقيق
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NULL ON UPDATE CURRENT_TIMESTAMP,
    created_by_user_id INT UNSIGNED COMMENT 'أنشأه',
    
    -- المفاتيح الخارجية
    CONSTRAINT fk_parentperm_account FOREIGN KEY (parent_account_id) 
        REFERENCES parent_accounts(id) ON DELETE CASCADE,
    CONSTRAINT fk_parentperm_student FOREIGN KEY (student_id) 
        REFERENCES students(id) ON DELETE CASCADE,
    CONSTRAINT fk_parentperm_creator FOREIGN KEY (created_by_user_id) 
        REFERENCES users(id) ON DELETE SET NULL,
    
    -- القيود
    UNIQUE KEY uk_parentperm (parent_account_id, student_id),
    INDEX idx_parentperm_student (student_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='صلاحيات وصول أولياء الأمور للبيانات';

-- ═══════════════════════════════════════════════════════════════════════════════
-- القسم 9: إعدادات التطبيق
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS parent_app_settings (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    
    setting_key VARCHAR(50) NOT NULL UNIQUE COMMENT 'مفتاح الإعداد',
    setting_value TEXT COMMENT 'قيمة الإعداد',
    setting_type ENUM('text', 'number', 'boolean', 'json') DEFAULT 'text',
    description VARCHAR(200) COMMENT 'وصف الإعداد',
    
    -- التدقيق
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NULL ON UPDATE CURRENT_TIMESTAMP,
    updated_by_user_id INT UNSIGNED COMMENT 'حدّثه',
    
    -- المفاتيح الخارجية
    CONSTRAINT fk_parentappsetting_updater FOREIGN KEY (updated_by_user_id) 
        REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='إعدادات تطبيق أولياء الأمور';

-- البيانات الأولية للإعدادات
INSERT INTO parent_app_settings (setting_key, setting_value, setting_type, description) VALUES
('session_timeout_minutes', '60', 'number', 'مدة انتهاء الجلسة بالدقائق'),
('max_login_attempts', '5', 'number', 'الحد الأقصى لمحاولات الدخول'),
('lockout_duration_minutes', '30', 'number', 'مدة قفل الحساب بالدقائق'),
('verification_code_expiry_minutes', '10', 'number', 'مدة صلاحية رمز التحقق'),
('enable_push_notifications', 'true', 'boolean', 'تفعيل الإشعارات الفورية'),
('enable_sms_notifications', 'false', 'boolean', 'تفعيل إشعارات SMS'),
('enable_leave_requests', 'true', 'boolean', 'تفعيل طلبات الاستئذان'),
('enable_teacher_messaging', 'true', 'boolean', 'تفعيل رسائل المعلمين'),
('auto_register_guardians', 'true', 'boolean', 'تسجيل أولياء الأمور تلقائياً'),
('min_app_version', '1.0.0', 'text', 'الحد الأدنى لإصدار التطبيق');

-- ═══════════════════════════════════════════════════════════════════════════════
-- القسم 10: سجل تدقيق التطبيق
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS parent_activity_logs (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    
    parent_account_id INT UNSIGNED NULL COMMENT 'حساب ولي الأمر',
    
    -- نوع الإجراء
    action VARCHAR(50) NOT NULL COMMENT 'الإجراء (LOGIN, VIEW_GRADES, etc.)',
    entity_type VARCHAR(50) COMMENT 'نوع الكيان',
    entity_id INT UNSIGNED COMMENT 'معرف الكيان',
    
    -- التفاصيل
    description TEXT COMMENT 'وصف الإجراء',
    request_data JSON COMMENT 'بيانات الطلب',
    response_status SMALLINT UNSIGNED COMMENT 'حالة الاستجابة',
    
    -- معلومات الجهاز
    ip_address VARCHAR(45) COMMENT 'عنوان IP',
    user_agent VARCHAR(255) COMMENT 'معلومات المتصفح',
    device_id VARCHAR(100) COMMENT 'معرف الجهاز',
    
    -- التدقيق
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- المفاتيح الخارجية
    CONSTRAINT fk_parentactivity_account FOREIGN KEY (parent_account_id) 
        REFERENCES parent_accounts(id) ON DELETE SET NULL,
    
    -- الفهارس
    INDEX idx_parentactivity_account (parent_account_id),
    INDEX idx_parentactivity_action (action),
    INDEX idx_parentactivity_date (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='سجل نشاط أولياء الأمور - ACTIVITY Audit';

-- ═══════════════════════════════════════════════════════════════════════════════
-- القسم 11: Views للـ API
-- ═══════════════════════════════════════════════════════════════════════════════

-- View أبناء ولي الأمر
CREATE OR REPLACE VIEW v_parent_children AS
SELECT 
    pa.id AS parent_account_id,
    pa.phone_number,
    g.full_name AS guardian_name,
    s.id AS student_id,
    s.full_name AS student_name,
    lg.name_ar AS gender_name,
    gl.name_ar AS grade_name,
    c.name_ar AS classroom_name,
    les.name_ar AS enrollment_status,
    pdp.can_view_grades,
    pdp.can_view_attendance,
    pdp.can_message_teachers
FROM parent_accounts pa
JOIN guardians g ON pa.guardian_id = g.id
JOIN student_guardians sg ON g.id = sg.guardian_id
JOIN students s ON sg.student_id = s.id
JOIN lookup_genders lg ON s.gender_id = lg.id
JOIN student_enrollments se ON s.id = se.student_id AND se.is_active = TRUE
JOIN lookup_enrollment_statuses les ON se.enrollment_status_id = les.id
JOIN classrooms c ON se.classroom_id = c.id
JOIN grade_levels gl ON c.grade_level_id = gl.id
LEFT JOIN parent_data_permissions pdp ON pa.id = pdp.parent_account_id AND s.id = pdp.student_id
WHERE pa.is_active = TRUE AND s.is_active = TRUE;

-- View درجات الطالب (للتطبيق)
CREATE OR REPLACE VIEW v_student_grades_for_parent AS
SELECT 
    s.id AS student_id,
    sub.name_ar AS subject_name,
    sub.code AS subject_code,
    am.name_ar AS month_name,
    mg.attendance_score AS attendance_grade,
    mg.homework_score AS homework_grade,
    mg.activity_score AS activity_grade,
    mg.exam_score AS test_grade,
    mg.contribution_score,
    mg.custom_components_score,
    
    ( IFNULL(mg.attendance_score,0) + IFNULL(mg.homework_score,0) + 
      IFNULL(mg.activity_score,0) + IFNULL(mg.exam_score,0) + 
      IFNULL(mg.contribution_score,0) + IFNULL(mg.custom_components_score,0) 
    ) AS monthly_total,
    
    CASE 
        WHEN ( IFNULL(mg.attendance_score,0) + IFNULL(mg.homework_score,0) + 
               IFNULL(mg.activity_score,0) + IFNULL(mg.exam_score,0) + 
               IFNULL(mg.contribution_score,0) + IFNULL(mg.custom_components_score,0) 
             ) < 17.5 THEN TRUE 
        ELSE FALSE 
    END AS is_failing,
    sg.semester_work_total,
    sg.final_exam_score AS semester_exam,
    sg.semester_total
FROM students s
JOIN student_enrollments se ON s.id = se.student_id AND se.is_active = TRUE
LEFT JOIN monthly_grades mg ON se.id = mg.enrollment_id
LEFT JOIN academic_months am ON mg.month_id = am.id
LEFT JOIN subjects sub ON mg.subject_id = sub.id
LEFT JOIN semester_grades sg ON se.id = sg.enrollment_id AND mg.subject_id = sg.subject_id;

-- View حضور الطالب (للتطبيق)
CREATE OR REPLACE VIEW v_student_attendance_for_parent AS
SELECT 
    s.id AS student_id,
    sa.attendance_date,
    las.name_ar AS status,
    las.code AS status_code,
    las.color_code,
    sa.has_permission,
    sa.has_excuse,
    sa.late_minutes,
    sa.notes
FROM students s
JOIN student_enrollments se ON s.id = se.student_id AND se.is_active = TRUE
JOIN student_attendance sa ON se.id = sa.enrollment_id
JOIN lookup_attendance_statuses las ON sa.status_id = las.id
ORDER BY sa.attendance_date DESC;

-- View إشعارات ولي الأمر (غير مقروءة)
CREATE OR REPLACE VIEW v_parent_unread_notifications AS
SELECT 
    pa.id AS parent_account_id,
    pn.id AS notification_id,
    lnt.name_ar AS notification_type,
    lnt.icon,
    lnt.color_code AS color,
    pn.title,
    pn.body,
    pn.priority,
    s.full_name AS student_name,
    pn.created_at
FROM parent_notifications pn
JOIN parent_accounts pa ON pn.parent_account_id = pa.id
JOIN lookup_notification_types lnt ON pn.notification_type_id = lnt.id
LEFT JOIN students s ON pn.student_id = s.id
WHERE pn.is_read = FALSE 
  AND (pn.expires_at IS NULL OR pn.expires_at > CURRENT_TIMESTAMP)
ORDER BY pn.priority DESC, pn.created_at DESC;

-- ═══════════════════════════════════════════════════════════════════════════════
-- رسالة اكتمال التنفيذ
-- ═══════════════════════════════════════════════════════════════════════════════

SELECT '✅ تم إنشاء جداول تطبيق أولياء الأمور بنجاح!' AS message;
SELECT CONCAT('📊 عدد الجداول: 13 جدول + 4 Views') AS summary;

-- ╔══════════════════════════════════════════════════════════════════════════════╗
-- ║  الملخص:                                                                     ║
-- ║  Lookup: lookup_parent_notification_types, lookup_leave_request_statuses,    ║
-- ║          lookup_leave_types (3)                                              ║
-- ║  الحسابات: parent_accounts, parent_sessions, parent_devices (3)             ║
-- ║  الإشعارات: parent_notifications (1)                                         ║
-- ║  الرسائل: parent_teacher_messages (1)                                        ║
-- ║  الاستئذان: leave_requests (1)                                               ║
-- ║  الصلاحيات: parent_data_permissions (1)                                      ║
-- ║  الإعدادات: parent_app_settings (1)                                          ║
-- ║  التدقيق: parent_app_audit_log (1)                                           ║
-- ║  ─────────────────────────────────────────────                               ║
-- ║  المجموع: 13 جدول + 4 Views                                                  ║
-- ║                                                                               ║
-- ║  إعداد واعتماد: المهندس موسى العواضي                                           ║
-- ╚══════════════════════════════════════════════════════════════════════════════╝
