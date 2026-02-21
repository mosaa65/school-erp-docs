-- ╔══════════════════════════════════════════════════════════════════════════════╗
-- ║                    جسر المنصة التعليمية المساندة                             ║
-- ║            Learning Platform Bridge Database Schema                           ║
-- ║                                                                               ║
-- ║    يشمل: ربط المحتوى، ربط الواجبات، تتبع المشاهدة                            ║
-- ║    ملاحظة: المنصة التعليمية نظام مستقل - هذا جسر الربط فقط                   ║
-- ╚══════════════════════════════════════════════════════════════════════════════╝

-- التاريخ: 2026-01-12
-- الإصدار: 1.0
-- المهندس المسؤول: موسى العواضي (تصميم واعتماد)
-- قاعدة البيانات: MySQL 8.0+

-- ═══════════════════════════════════════════════════════════════════════════════
-- ملاحظة مهمة:
-- ═══════════════════════════════════════════════════════════════════════════════
-- المنصة التعليمية (LMS) نظام مستقل بقاعدة بيانات منفصلة
-- هذا الملف يوفر فقط:
-- 1. جداول الربط بين النظامين
-- 2. مراجع للمحتوى الخارجي
-- 3. تتبع تفاعل الطلاب (اختياري)
-- ═══════════════════════════════════════════════════════════════════════════════

-- ═══════════════════════════════════════════════════════════════════════════════
-- القسم 1: جداول Lookup للمنصة
-- ═══════════════════════════════════════════════════════════════════════════════

-- جدول أنواع المحتوى
CREATE TABLE IF NOT EXISTS lookup_lms_content_types (
    id TINYINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name_ar VARCHAR(50) NOT NULL COMMENT 'النوع بالعربية',
    code VARCHAR(30) NOT NULL UNIQUE COMMENT 'رمز النوع',
    icon VARCHAR(50) COMMENT 'أيقونة',
    mime_types VARCHAR(200) COMMENT 'أنواع MIME المسموحة',
    max_size_mb INT UNSIGNED COMMENT 'الحد الأقصى بـ MB',
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='أنواع محتوى المنصة التعليمية';

INSERT INTO lookup_lms_content_types (name_ar, code, icon, mime_types, max_size_mb) VALUES
('فيديو', 'VIDEO', 'video_library', 'video/mp4,video/webm', 500),
('صوت', 'AUDIO', 'audiotrack', 'audio/mp3,audio/wav,audio/ogg', 50),
('PDF', 'PDF', 'picture_as_pdf', 'application/pdf', 20),
('عرض تقديمي', 'PRESENTATION', 'slideshow', 'application/pptx,application/ppt', 50),
('صورة', 'IMAGE', 'image', 'image/jpeg,image/png,image/gif', 10),
('رابط خارجي', 'EXTERNAL_LINK', 'link', NULL, NULL),
('ملف تفاعلي', 'INTERACTIVE', 'touch_app', 'text/html', 100),
('اختبار إلكتروني', 'QUIZ', 'quiz', NULL, NULL);

-- جدول حالات المحتوى
CREATE TABLE IF NOT EXISTS lookup_lms_content_statuses (
    id TINYINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name_ar VARCHAR(30) NOT NULL COMMENT 'الحالة بالعربية',
    code VARCHAR(20) NOT NULL UNIQUE COMMENT 'رمز الحالة',
    color VARCHAR(10) COMMENT 'لون العرض',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='حالات المحتوى';

INSERT INTO lookup_lms_content_statuses (name_ar, code, color) VALUES
('مسودة', 'DRAFT', '#6c757d'),
('منشور', 'PUBLISHED', '#28a745'),
('معلق', 'SUSPENDED', '#ffc107'),
('محذوف', 'DELETED', '#dc3545');

-- ═══════════════════════════════════════════════════════════════════════════════
-- القسم 2: ربط المحتوى بالدروس
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS lms_content_links (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    
    -- الربط بالدرس
    lesson_prep_id INT UNSIGNED NULL COMMENT 'تحضير الدرس (للربط بدرس)',
    subject_id INT UNSIGNED NULL COMMENT 'المادة (للربط بوحدة)',
    grade_level_id INT UNSIGNED NULL COMMENT 'الصف',
    
    -- معلومات المحتوى
    content_title VARCHAR(255) NOT NULL COMMENT 'عنوان المحتوى',
    content_type_id TINYINT UNSIGNED NOT NULL COMMENT 'نوع المحتوى',
    content_description TEXT COMMENT 'وصف المحتوى',
    
    -- موقع المحتوى
    content_source ENUM('محلي', 'خارجي', 'LMS') DEFAULT 'محلي' COMMENT 'مصدر المحتوى',
    content_url VARCHAR(1000) COMMENT 'رابط المحتوى (للخارجي)',
    content_path VARCHAR(500) COMMENT 'مسار المحتوى (للمحلي)',
    external_id VARCHAR(100) COMMENT 'معرف المحتوى في LMS الخارجي',
    
    -- البيانات الوصفية
    duration_minutes INT UNSIGNED COMMENT 'المدة بالدقائق',
    file_size_bytes BIGINT UNSIGNED COMMENT 'حجم الملف',
    thumbnail_url VARCHAR(500) COMMENT 'صورة مصغرة',
    
    -- الترتيب
    sort_order SMALLINT DEFAULT 0 COMMENT 'ترتيب العرض',
    
    -- الحالة
    status_id TINYINT UNSIGNED NOT NULL DEFAULT 1 COMMENT 'حالة المحتوى',
    is_mandatory BOOLEAN DEFAULT FALSE COMMENT 'إلزامي للطالب',
    
    -- الرؤية
    visible_from TIMESTAMP NULL COMMENT 'ظاهر من',
    visible_until TIMESTAMP NULL COMMENT 'ظاهر حتى',
    
    -- التدقيق
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NULL ON UPDATE CURRENT_TIMESTAMP,
    created_by_user_id INT UNSIGNED COMMENT 'أنشأه',
    
    -- المفاتيح الخارجية
    CONSTRAINT fk_lmslink_lesson FOREIGN KEY (lesson_prep_id) 
        REFERENCES lesson_preparation(id) ON DELETE CASCADE,
    CONSTRAINT fk_lmslink_subject FOREIGN KEY (subject_id) 
        REFERENCES subjects(id) ON DELETE CASCADE,
    CONSTRAINT fk_lmslink_grade FOREIGN KEY (grade_level_id) 
        REFERENCES grade_levels(id) ON DELETE CASCADE,
    CONSTRAINT fk_lmslink_type FOREIGN KEY (content_type_id) 
        REFERENCES lookup_lms_content_types(id) ON DELETE RESTRICT,
    CONSTRAINT fk_lmslink_status FOREIGN KEY (status_id) 
        REFERENCES lookup_lms_content_statuses(id) ON DELETE RESTRICT,
    CONSTRAINT fk_lmslink_creator FOREIGN KEY (created_by_user_id) 
        REFERENCES users(id) ON DELETE SET NULL,
    
    -- الفهارس
    INDEX idx_lmslink_lesson (lesson_prep_id),
    INDEX idx_lmslink_subject (subject_id),
    INDEX idx_lmslink_grade (grade_level_id),
    INDEX idx_lmslink_type (content_type_id),
    INDEX idx_lmslink_status (status_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='ربط المحتوى التعليمي بالدروس';

-- ═══════════════════════════════════════════════════════════════════════════════
-- القسم 3: ربط الواجبات بالمحتوى
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS lms_homework_content (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    
    homework_id INT UNSIGNED NOT NULL COMMENT 'الواجب',
    
    -- المحتوى
    content_type_id TINYINT UNSIGNED NOT NULL COMMENT 'نوع المحتوى',
    content_title VARCHAR(255) NOT NULL COMMENT 'عنوان المحتوى',
    content_description TEXT COMMENT 'وصف/تعليمات',
    
    -- موقع المحتوى
    content_source ENUM('محلي', 'خارجي', 'LMS') DEFAULT 'محلي',
    content_url VARCHAR(1000) COMMENT 'رابط المحتوى',
    content_path VARCHAR(500) COMMENT 'مسار المحتوى',
    
    -- خيارات
    is_required_to_view BOOLEAN DEFAULT FALSE COMMENT 'يجب مشاهدته قبل الحل',
    is_submission_link BOOLEAN DEFAULT FALSE COMMENT 'رابط تسليم الواجب',
    
    -- الترتيب
    sort_order SMALLINT DEFAULT 0,
    
    -- التدقيق
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by_user_id INT UNSIGNED COMMENT 'أنشأه',
    
    -- المفاتيح الخارجية
    CONSTRAINT fk_lmshw_homework FOREIGN KEY (homework_id) 
        REFERENCES homework(id) ON DELETE CASCADE,
    CONSTRAINT fk_lmshw_type FOREIGN KEY (content_type_id) 
        REFERENCES lookup_lms_content_types(id) ON DELETE RESTRICT,
    CONSTRAINT fk_lmshw_creator FOREIGN KEY (created_by_user_id) 
        REFERENCES users(id) ON DELETE SET NULL,
    
    -- الفهارس
    INDEX idx_lmshw_homework (homework_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='ربط محتوى الواجبات';

-- ═══════════════════════════════════════════════════════════════════════════════
-- القسم 4: تتبع مشاهدة الطلاب (اختياري)
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS lms_student_content_views (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    
    -- الطالب والمحتوى
    enrollment_id INT UNSIGNED NOT NULL COMMENT 'تسجيل الطالب',
    content_link_id INT UNSIGNED NOT NULL COMMENT 'المحتوى',
    
    -- معلومات المشاهدة
    first_viewed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT 'أول مشاهدة',
    last_viewed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'آخر مشاهدة',
    view_count INT UNSIGNED DEFAULT 1 COMMENT 'عدد المشاهدات',
    
    -- التقدم (للفيديو/الصوت)
    progress_percentage TINYINT UNSIGNED DEFAULT 0 COMMENT 'نسبة الإكمال %',
    last_position_seconds INT UNSIGNED DEFAULT 0 COMMENT 'آخر موضع (ثانية)',
    is_completed BOOLEAN DEFAULT FALSE COMMENT 'مكتمل',
    completed_at TIMESTAMP NULL COMMENT 'وقت الإكمال',
    
    -- الجهاز
    device_type ENUM('android', 'ios', 'web', 'desktop') COMMENT 'نوع الجهاز',
    
    -- المفاتيح الخارجية
    CONSTRAINT fk_lmsview_enrollment FOREIGN KEY (enrollment_id) 
        REFERENCES student_enrollments(id) ON DELETE CASCADE,
    CONSTRAINT fk_lmsview_content FOREIGN KEY (content_link_id) 
        REFERENCES lms_content_links(id) ON DELETE CASCADE,
    
    -- القيود
    UNIQUE KEY uk_lmsview (enrollment_id, content_link_id),
    INDEX idx_lmsview_enrollment (enrollment_id),
    INDEX idx_lmsview_content (content_link_id),
    INDEX idx_lmsview_completed (is_completed)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='تتبع مشاهدة الطلاب للمحتوى';

-- ═══════════════════════════════════════════════════════════════════════════════
-- القسم 5: سجل المزامنة مع LMS الخارجي
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS lms_sync_log (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    
    -- نوع المزامنة
    sync_type ENUM('استيراد', 'تصدير', 'تحديث') NOT NULL COMMENT 'نوع المزامنة',
    entity_type VARCHAR(50) NOT NULL COMMENT 'نوع الكيان',
    entity_id INT UNSIGNED COMMENT 'معرف الكيان المحلي',
    external_id VARCHAR(100) COMMENT 'معرف الكيان الخارجي',
    
    -- النتيجة
    status ENUM('ناجح', 'فاشل', 'جزئي') NOT NULL,
    records_processed INT UNSIGNED DEFAULT 0 COMMENT 'السجلات المعالجة',
    records_failed INT UNSIGNED DEFAULT 0 COMMENT 'السجلات الفاشلة',
    error_message TEXT COMMENT 'رسالة الخطأ',
    
    -- التدقيق
    started_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP NULL,
    sync_by_user_id INT UNSIGNED COMMENT 'نفذها',
    
    -- المفاتيح الخارجية
    CONSTRAINT fk_lmssync_user FOREIGN KEY (sync_by_user_id) 
        REFERENCES users(id) ON DELETE SET NULL,
    
    -- الفهارس
    INDEX idx_lmssync_date (started_at),
    INDEX idx_lmssync_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='سجل مزامنة المنصة التعليمية';

-- ═══════════════════════════════════════════════════════════════════════════════
-- القسم 6: إعدادات الربط
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS lms_bridge_settings (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    
    setting_key VARCHAR(50) NOT NULL UNIQUE COMMENT 'مفتاح الإعداد',
    setting_value TEXT COMMENT 'قيمة الإعداد',
    setting_type ENUM('text', 'number', 'boolean', 'json', 'url') DEFAULT 'text',
    description VARCHAR(200) COMMENT 'وصف الإعداد',
    is_sensitive BOOLEAN DEFAULT FALSE COMMENT 'بيانات حساسة',
    
    -- التدقيق
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NULL ON UPDATE CURRENT_TIMESTAMP,
    updated_by_user_id INT UNSIGNED COMMENT 'حدّثه',
    
    -- المفاتيح الخارجية
    CONSTRAINT fk_lmssetting_updater FOREIGN KEY (updated_by_user_id) 
        REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='إعدادات جسر المنصة التعليمية';

-- البيانات الأولية للإعدادات
INSERT INTO lms_bridge_settings (setting_key, setting_value, setting_type, description, is_sensitive) VALUES
('lms_enabled', 'false', 'boolean', 'تفعيل الربط مع LMS', FALSE),
('lms_provider', 'none', 'text', 'مزود LMS (moodle, canvas, google_classroom)', FALSE),
('lms_api_url', '', 'url', 'رابط API للـ LMS', FALSE),
('lms_api_key', '', 'text', 'مفتاح API', TRUE),
('lms_api_secret', '', 'text', 'المفتاح السري', TRUE),
('auto_sync_enabled', 'false', 'boolean', 'المزامنة التلقائية', FALSE),
('sync_interval_minutes', '60', 'number', 'فترة المزامنة بالدقائق', FALSE),
('track_student_views', 'true', 'boolean', 'تتبع مشاهدات الطلاب', FALSE),
('default_content_visibility', 'immediate', 'text', 'الرؤية الافتراضية (immediate, scheduled)', FALSE),
('max_file_size_mb', '100', 'number', 'الحد الأقصى لحجم الملف MB', FALSE);

-- ═══════════════════════════════════════════════════════════════════════════════
-- القسم 7: Views للتقارير
-- ═══════════════════════════════════════════════════════════════════════════════

-- View المحتوى المتاح للطالب
CREATE OR REPLACE VIEW v_student_available_content AS
SELECT 
    se.id AS enrollment_id,
    se.student_id,
    s.full_name AS student_name,
    sub.name_ar AS subject_name,
    lc.content_title,
    lct.name_ar AS content_type,
    lct.icon AS type_icon,
    lc.duration_minutes,
    lc.is_mandatory,
    COALESCE(scv.is_completed, FALSE) AS is_completed,
    COALESCE(scv.progress_percentage, 0) AS progress_percentage,
    scv.last_viewed_at
FROM student_enrollments se
JOIN students s ON se.student_id = s.id
JOIN classrooms c ON se.classroom_id = c.id
JOIN grade_levels gl ON c.grade_level_id = gl.id
JOIN lms_content_links lc ON (lc.grade_level_id = gl.id OR lc.subject_id IN 
    (SELECT gs.subject_id FROM grade_subjects gs WHERE gs.grade_level_id = gl.id))
JOIN lookup_lms_content_types lct ON lc.content_type_id = lct.id
JOIN lookup_lms_content_statuses lcs ON lc.status_id = lcs.id
LEFT JOIN subjects sub ON lc.subject_id = sub.id
LEFT JOIN lms_student_content_views scv ON se.id = scv.enrollment_id AND lc.id = scv.content_link_id
WHERE se.is_active = TRUE 
  AND lcs.code = 'PUBLISHED'
  AND (lc.visible_from IS NULL OR lc.visible_from <= CURRENT_TIMESTAMP)
  AND (lc.visible_until IS NULL OR lc.visible_until >= CURRENT_TIMESTAMP);

-- View تقدم الطلاب في المحتوى
CREATE OR REPLACE VIEW v_content_completion_report AS
SELECT 
    lc.id AS content_id,
    lc.content_title,
    lct.name_ar AS content_type,
    sub.name_ar AS subject_name,
    gl.name_ar AS grade_name,
    COUNT(DISTINCT se.id) AS total_students,
    COUNT(DISTINCT CASE WHEN scv.is_completed = TRUE THEN scv.enrollment_id END) AS completed_count,
    ROUND(COUNT(DISTINCT CASE WHEN scv.is_completed = TRUE THEN scv.enrollment_id END) * 100.0 / 
          NULLIF(COUNT(DISTINCT se.id), 0), 1) AS completion_rate,
    AVG(scv.progress_percentage) AS avg_progress
FROM lms_content_links lc
JOIN lookup_lms_content_types lct ON lc.content_type_id = lct.id
LEFT JOIN subjects sub ON lc.subject_id = sub.id
LEFT JOIN grade_levels gl ON lc.grade_level_id = gl.id
LEFT JOIN student_enrollments se ON se.is_active = TRUE AND 
    (gl.id IS NULL OR se.classroom_id IN (SELECT id FROM classrooms WHERE grade_level_id = gl.id))
LEFT JOIN lms_student_content_views scv ON lc.id = scv.content_link_id AND se.id = scv.enrollment_id
GROUP BY lc.id, lc.content_title, lct.name_ar, sub.name_ar, gl.name_ar;

-- ═══════════════════════════════════════════════════════════════════════════════
-- رسالة اكتمال التنفيذ
-- ═══════════════════════════════════════════════════════════════════════════════

SELECT '✅ تم إنشاء جداول جسر المنصة التعليمية بنجاح!' AS message;
SELECT CONCAT('📊 عدد الجداول: 8 جداول + 2 Views') AS summary;

-- ╔══════════════════════════════════════════════════════════════════════════════╗
-- ║  الملخص:                                                                     ║
-- ║  Lookup: lookup_lms_content_types, lookup_lms_content_statuses (2)           ║
-- ║  الربط: lms_content_links, lms_homework_content (2)                          ║
-- ║  التتبع: lms_student_content_views (1)                                       ║
-- ║  المزامنة: lms_sync_log (1)                                                  ║
-- ║  الإعدادات: lms_bridge_settings (1)                                          ║
-- ║  ─────────────────────────────────────────────                               ║
-- ║  المجموع: 8 جداول + 2 Views                                                  ║
-- ║                                                                               ║
-- ║  ملاحظة: المنصة التعليمية (LMS) نظام مستقل - هذا جسر الربط فقط              ║
-- ║                                                                               ║
-- ║  إعداد واعتماد: المهندس موسى العواضي                                           ║
-- ╚══════════════════════════════════════════════════════════════════════════════╝
