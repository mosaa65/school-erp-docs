-- ╔══════════════════════════════════════════════════════════════════════════════╗
-- ║                          نظام النقل المدرسي (الباصات)                        ║
-- ║                   Transportation System Database Schema                        ║
-- ║                                                                               ║
-- ║         يشمل: الباصات، خطوط السير، المحطات، الاشتراكات، الحضور               ║
-- ╚══════════════════════════════════════════════════════════════════════════════╝

-- التاريخ: 2026-01-10
-- الإصدار: 1.0
-- المهندس المسؤول: يونس العفيف / فيصل الجماعي
-- قاعدة البيانات: MySQL 8.0+

-- ═══════════════════════════════════════════════════════════════════════════════
-- القسم 1: جداول Lookup للنقل
-- ═══════════════════════════════════════════════════════════════════════════════

-- جدول أنواع الاشتراك
CREATE TABLE IF NOT EXISTS lookup_subscription_types (
    id TINYINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name_ar VARCHAR(30) NOT NULL COMMENT 'النوع بالعربية',
    code VARCHAR(20) NOT NULL UNIQUE COMMENT 'رمز النوع',
    description VARCHAR(100) COMMENT 'وصف النوع',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='أنواع اشتراك الباص';

INSERT INTO lookup_subscription_types (name_ar, code, description) VALUES
('ذهاب فقط', 'ONE_WAY_TO', 'من المنزل إلى المدرسة فقط'),
('إياب فقط', 'ONE_WAY_FROM', 'من المدرسة إلى المنزل فقط'),
('ذهاب وإياب', 'TWO_WAY', 'ذهاباً وإياباً');

-- جدول حالات ركوب الباص
CREATE TABLE IF NOT EXISTS lookup_bus_attendance_statuses (
    id TINYINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name_ar VARCHAR(30) NOT NULL COMMENT 'الحالة بالعربية',
    code VARCHAR(20) NOT NULL UNIQUE COMMENT 'رمز الحالة',
    color VARCHAR(10) COMMENT 'لون للعرض',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='حالات حضور الباص';

INSERT INTO lookup_bus_attendance_statuses (name_ar, code, color) VALUES
('ركب', 'BOARDED', '#2ecc71'),
('لم يركب', 'NOT_BOARDED', '#f39c12'),
('غائب', 'ABSENT', '#e74c3c'),
('تأخر', 'LATE', '#9b59b6');

-- ═══════════════════════════════════════════════════════════════════════════════
-- القسم 2: الباصات
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS buses (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    
    -- معلومات الباص
    bus_number VARCHAR(20) NOT NULL COMMENT 'رقم الباص (داخلي)',
    plate_number VARCHAR(20) UNIQUE COMMENT 'رقم اللوحة',
    brand VARCHAR(50) COMMENT 'الماركة',
    model VARCHAR(50) COMMENT 'الموديل',
    model_year YEAR COMMENT 'سنة الصنع',
    color VARCHAR(30) COMMENT 'اللون',
    
    -- السعة
    capacity TINYINT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'السعة الكلية',
    
    -- الطاقم
    driver_id INT UNSIGNED COMMENT 'السائق (موظف)',
    assistant_id INT UNSIGNED COMMENT 'المساعد/المرافق',
    
    -- معلومات الترخيص
    license_number VARCHAR(50) COMMENT 'رقم الترخيص',
    license_expiry DATE COMMENT 'تاريخ انتهاء الترخيص',
    insurance_expiry DATE COMMENT 'تاريخ انتهاء التأمين',
    
    -- الحالة
    is_active BOOLEAN DEFAULT TRUE COMMENT 'نشط',
    status ENUM('عامل', 'معطل', 'صيانة') DEFAULT 'عامل' COMMENT 'حالة الباص',
    
    -- ملاحظات
    notes TEXT COMMENT 'ملاحظات',
    
    -- التدقيق
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NULL ON UPDATE CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL COMMENT 'Soft Delete',
    created_by_user_id INT UNSIGNED COMMENT 'أنشأه',
    
    -- المفاتيح الخارجية
    CONSTRAINT fk_bus_driver FOREIGN KEY (driver_id) 
        REFERENCES employees(id) ON DELETE SET NULL,
    CONSTRAINT fk_bus_assistant FOREIGN KEY (assistant_id) 
        REFERENCES employees(id) ON DELETE SET NULL,
    CONSTRAINT fk_bus_creator FOREIGN KEY (created_by_user_id) 
        REFERENCES users(id) ON DELETE SET NULL,
    
    -- الفهارس
    INDEX idx_bus_number (bus_number),
    INDEX idx_bus_active (is_active)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='الباصات المدرسية';

-- ═══════════════════════════════════════════════════════════════════════════════
-- القسم 3: خطوط السير
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS bus_routes (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    
    -- الربط بالباص
    bus_id INT UNSIGNED NOT NULL COMMENT 'الباص',
    
    -- معلومات الخط
    route_name VARCHAR(100) NOT NULL COMMENT 'اسم الخط',
    route_code VARCHAR(20) UNIQUE COMMENT 'رمز الخط',
    direction ENUM('ذهاب', 'إياب') NOT NULL COMMENT 'الاتجاه',
    period_id TINYINT UNSIGNED COMMENT 'الفترة (صباحية/مسائية)',
    
    -- الأوقات
    departure_time TIME NOT NULL COMMENT 'وقت الانطلاق',
    arrival_time TIME COMMENT 'وقت الوصول المتوقع',
    estimated_duration SMALLINT UNSIGNED COMMENT 'المدة المتوقعة بالدقائق',
    
    -- المسافة
    total_distance_km DECIMAL(5,2) COMMENT 'المسافة الكلية بالكيلومتر',
    
    -- الحالة
    is_active BOOLEAN DEFAULT TRUE COMMENT 'نشط',
    
    -- ملاحظات
    notes TEXT COMMENT 'ملاحظات',
    
    -- التدقيق
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NULL ON UPDATE CURRENT_TIMESTAMP,
    
    -- المفاتيح الخارجية
    CONSTRAINT fk_route_bus FOREIGN KEY (bus_id) 
        REFERENCES buses(id) ON DELETE RESTRICT,
    CONSTRAINT fk_route_period FOREIGN KEY (period_id) 
        REFERENCES lookup_periods(id) ON DELETE SET NULL,
    
    -- القيود
    UNIQUE KEY uk_route_bus_direction (bus_id, direction, period_id),
    INDEX idx_route_active (is_active)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='خطوط سير الباصات';

-- ═══════════════════════════════════════════════════════════════════════════════
-- القسم 4: محطات الخط
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS route_stops (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    
    route_id INT UNSIGNED NOT NULL COMMENT 'خط السير',
    
    -- معلومات المحطة
    stop_order TINYINT UNSIGNED NOT NULL COMMENT 'ترتيب المحطة',
    stop_name VARCHAR(100) NOT NULL COMMENT 'اسم المحطة',
    locality_id MEDIUMINT UNSIGNED COMMENT 'المحلة/الحي',
    
    -- الموقع الجغرافي (اختياري)
    latitude DECIMAL(10, 8) COMMENT 'خط العرض',
    longitude DECIMAL(11, 8) COMMENT 'خط الطول',
    
    -- الأوقات
    arrival_time TIME COMMENT 'وقت الوصول المتوقع',
    waiting_time TINYINT UNSIGNED DEFAULT 2 COMMENT 'وقت الانتظار بالدقائق',
    
    -- ملاحظات
    notes TEXT COMMENT 'ملاحظات أو علامات مميزة',
    
    -- التدقيق
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- المفاتيح الخارجية
    CONSTRAINT fk_stop_route FOREIGN KEY (route_id) 
        REFERENCES bus_routes(id) ON DELETE CASCADE,
    CONSTRAINT fk_stop_locality FOREIGN KEY (locality_id) 
        REFERENCES localities(id) ON DELETE SET NULL,
    
    -- القيود
    UNIQUE KEY uk_stop_order (route_id, stop_order),
    INDEX idx_stop_route (route_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='محطات خطوط الباصات';

-- ═══════════════════════════════════════════════════════════════════════════════
-- القسم 5: اشتراكات الطلاب
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS bus_subscriptions (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    
    -- الربط بالطالب والخط
    enrollment_id INT UNSIGNED NOT NULL COMMENT 'تسجيل الطالب',
    route_id INT UNSIGNED NOT NULL COMMENT 'خط السير',
    stop_id INT UNSIGNED NOT NULL COMMENT 'المحطة',
    
    -- نوع الاشتراك
    subscription_type_id TINYINT UNSIGNED NOT NULL COMMENT 'نوع الاشتراك',
    
    -- الرسوم
    monthly_fee DECIMAL(10,2) DEFAULT 0.00 COMMENT 'الرسوم الشهرية',
    
    -- الفترة
    start_date DATE NOT NULL COMMENT 'تاريخ بداية الاشتراك',
    end_date DATE COMMENT 'تاريخ نهاية الاشتراك',
    
    -- الحالة
    is_active BOOLEAN DEFAULT TRUE COMMENT 'نشط',
    cancellation_reason TEXT COMMENT 'سبب الإلغاء',
    
    -- معلومات الاتصال للطوارئ
    emergency_contact_name VARCHAR(100) COMMENT 'اسم جهة اتصال الطوارئ',
    emergency_contact_phone VARCHAR(20) COMMENT 'رقم هاتف الطوارئ',
    
    -- ملاحظات
    notes TEXT COMMENT 'ملاحظات',
    
    -- التدقيق
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NULL ON UPDATE CURRENT_TIMESTAMP,
    created_by_user_id INT UNSIGNED COMMENT 'أنشأه',
    
    -- المفاتيح الخارجية
    CONSTRAINT fk_subscription_enrollment FOREIGN KEY (enrollment_id) 
        REFERENCES student_enrollments(id) ON DELETE CASCADE,
    CONSTRAINT fk_subscription_route FOREIGN KEY (route_id) 
        REFERENCES bus_routes(id) ON DELETE RESTRICT,
    CONSTRAINT fk_subscription_stop FOREIGN KEY (stop_id) 
        REFERENCES route_stops(id) ON DELETE RESTRICT,
    CONSTRAINT fk_subscription_type FOREIGN KEY (subscription_type_id) 
        REFERENCES lookup_subscription_types(id) ON DELETE RESTRICT,
    CONSTRAINT fk_subscription_creator FOREIGN KEY (created_by_user_id) 
        REFERENCES users(id) ON DELETE SET NULL,
    
    -- القيود
    UNIQUE KEY uk_subscription_enrollment (enrollment_id, route_id),
    INDEX idx_subscription_route (route_id),
    INDEX idx_subscription_active (is_active),
    INDEX idx_subscription_dates (start_date, end_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='اشتراكات الطلاب في الباصات';

-- ═══════════════════════════════════════════════════════════════════════════════
-- القسم 6: حضور الباص
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS bus_attendance (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    
    subscription_id INT UNSIGNED NOT NULL COMMENT 'الاشتراك',
    
    -- معلومات الحضور
    attendance_date DATE NOT NULL COMMENT 'التاريخ',
    direction ENUM('ذهاب', 'إياب') NOT NULL COMMENT 'الاتجاه',
    status_id TINYINT UNSIGNED NOT NULL COMMENT 'الحالة',
    
    -- الوقت الفعلي
    actual_pickup_time TIME COMMENT 'وقت الركوب الفعلي',
    actual_dropoff_time TIME COMMENT 'وقت النزول الفعلي',
    
    -- ملاحظات
    notes TEXT COMMENT 'ملاحظات',
    
    -- التدقيق
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by_user_id INT UNSIGNED COMMENT 'سجله',
    
    -- المفاتيح الخارجية
    CONSTRAINT fk_busattend_subscription FOREIGN KEY (subscription_id) 
        REFERENCES bus_subscriptions(id) ON DELETE CASCADE,
    CONSTRAINT fk_busattend_status FOREIGN KEY (status_id) 
        REFERENCES lookup_bus_attendance_statuses(id) ON DELETE RESTRICT,
    CONSTRAINT fk_busattend_creator FOREIGN KEY (created_by_user_id) 
        REFERENCES users(id) ON DELETE SET NULL,
    
    -- القيود
    UNIQUE KEY uk_busattend_daily (subscription_id, attendance_date, direction),
    INDEX idx_busattend_date (attendance_date),
    INDEX idx_busattend_status (status_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='حضور الطلاب في الباصات';

-- ═══════════════════════════════════════════════════════════════════════════════
-- القسم 7: صيانة الباصات
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS bus_maintenance (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    
    bus_id INT UNSIGNED NOT NULL COMMENT 'الباص',
    
    -- معلومات الصيانة
    maintenance_type ENUM('دورية', 'طارئة', 'إصلاح', 'فحص') DEFAULT 'دورية',
    maintenance_date DATE NOT NULL COMMENT 'تاريخ الصيانة',
    description TEXT COMMENT 'وصف الصيانة',
    
    -- التكلفة
    cost DECIMAL(10,2) DEFAULT 0.00 COMMENT 'التكلفة',
    vendor_name VARCHAR(100) COMMENT 'اسم الورشة/المورد',
    
    -- الحالة
    status ENUM('مجدول', 'جاري', 'مكتمل', 'ملغي') DEFAULT 'مجدول',
    completion_date DATE COMMENT 'تاريخ الإكمال',
    
    -- ملاحظات
    notes TEXT COMMENT 'ملاحظات',
    
    -- التدقيق
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by_user_id INT UNSIGNED COMMENT 'أنشأه',
    
    -- المفاتيح الخارجية
    CONSTRAINT fk_maintenance_bus FOREIGN KEY (bus_id) 
        REFERENCES buses(id) ON DELETE CASCADE,
    CONSTRAINT fk_maintenance_creator FOREIGN KEY (created_by_user_id) 
        REFERENCES users(id) ON DELETE SET NULL,
    
    -- الفهارس
    INDEX idx_maintenance_bus (bus_id),
    INDEX idx_maintenance_date (maintenance_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='صيانة الباصات';

-- ═══════════════════════════════════════════════════════════════════════════════
-- القسم 8: Views للتقارير
-- ═══════════════════════════════════════════════════════════════════════════════

-- View قائمة ركاب الخط
CREATE OR REPLACE VIEW v_route_passengers AS
SELECT 
    br.id AS route_id,
    br.route_name,
    br.direction,
    b.bus_number,
    rs.stop_name,
    rs.stop_order,
    s.full_name AS student_name,
    s.gender,
    gl.name_ar AS grade_name,
    c.name_ar AS classroom_name,
    lst.name_ar AS subscription_type,
    bs.monthly_fee,
    bs.is_active
FROM bus_subscriptions bs
JOIN bus_routes br ON bs.route_id = br.id
JOIN buses b ON br.bus_id = b.id
JOIN route_stops rs ON bs.stop_id = rs.id
JOIN student_enrollments se ON bs.enrollment_id = se.id
JOIN students s ON se.student_id = s.id
JOIN classrooms c ON se.classroom_id = c.id
JOIN grade_levels gl ON c.grade_level_id = gl.id
JOIN lookup_subscription_types lst ON bs.subscription_type_id = lst.id
ORDER BY br.route_name, rs.stop_order, s.full_name;

-- View ملخص الباصات
CREATE OR REPLACE VIEW v_bus_summary AS
SELECT 
    b.id AS bus_id,
    b.bus_number,
    b.plate_number,
    b.capacity,
    e.full_name AS driver_name,
    (SELECT COUNT(*) FROM bus_subscriptions bs 
     JOIN bus_routes br ON bs.route_id = br.id 
     WHERE br.bus_id = b.id AND bs.is_active = TRUE) AS active_subscribers,
    b.status,
    b.is_active
FROM buses b
LEFT JOIN employees e ON b.driver_id = e.id;

-- View تقرير الحضور اليومي للباص
CREATE OR REPLACE VIEW v_bus_daily_attendance AS
SELECT 
    ba.attendance_date,
    br.route_name,
    ba.direction,
    b.bus_number,
    COUNT(*) AS total_students,
    SUM(CASE WHEN lbas.code = 'BOARDED' THEN 1 ELSE 0 END) AS boarded_count,
    SUM(CASE WHEN lbas.code = 'NOT_BOARDED' THEN 1 ELSE 0 END) AS not_boarded_count,
    SUM(CASE WHEN lbas.code = 'ABSENT' THEN 1 ELSE 0 END) AS absent_count
FROM bus_attendance ba
JOIN bus_subscriptions bs ON ba.subscription_id = bs.id
JOIN bus_routes br ON bs.route_id = br.id
JOIN buses b ON br.bus_id = b.id
JOIN lookup_bus_attendance_statuses lbas ON ba.status_id = lbas.id
GROUP BY ba.attendance_date, br.route_name, ba.direction, b.bus_number;

-- ═══════════════════════════════════════════════════════════════════════════════

-- -----------------------------------------------------------------------------
-- 9. (ملحق) Views التقويم التشغيلية (Transport)
-- -----------------------------------------------------------------------------

-- View: تقويم النقل المدرسي
CREATE OR REPLACE VIEW v_bus_attendance_calendar AS 
SELECT  
   ba.id, ba.subscription_id, s.full_name AS student_name, 
   br.route_name, ba.direction, 
   ba.attendance_date, 
   cm.hijri_date, cm.day_name_ar, 
   cm.is_school_day, cm.is_holiday, 
   lbas.name_ar AS status_name, lbas.code AS status_code 
FROM bus_attendance ba 
LEFT JOIN calendar_master cm ON ba.attendance_date = cm.gregorian_date 
LEFT JOIN lookup_bus_attendance_statuses lbas ON ba.status_id = lbas.id 
LEFT JOIN bus_subscriptions bs ON ba.subscription_id = bs.id 
LEFT JOIN student_enrollments se ON bs.enrollment_id = se.id 
LEFT JOIN students s ON se.student_id = s.id 
LEFT JOIN bus_routes br ON bs.route_id = br.id;

-- ═══════════════════════════════════════════════════════════════════════════════
-- رسالة اكتمال التنفيذ
-- ═══════════════════════════════════════════════════════════════════════════════

SELECT '✅ تم إنشاء جداول نظام النقل المدرسي بنجاح!' AS message;
SELECT CONCAT('📊 عدد الجداول: 9 جداول + 4 Views') AS summary;
