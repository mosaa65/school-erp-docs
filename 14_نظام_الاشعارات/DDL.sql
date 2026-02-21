/*
    ========================================================================
    🔴 نظام الإشعارات الذكي (Smart Notification System) - System 14
    ========================================================================
    المهمة: إدارة جميع الاتصالات الصادرة (واتساب، تطبيق) بذكاء ومركزية.
    الفلسفة: ضمان وصول المعلومة للشخص الصحيح في الوقت الصحيح، دون إزعاج.
    ========================================================================
*/

-- 1. القنوات والتصنيفات (Lookups)
CREATE TABLE IF NOT EXISTS lookup_notification_channels (
    id TINYINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name_ar VARCHAR(50) NOT NULL, -- واتساب، تطبيق المعلم، تطبيق الإدارة، تطبيق الوالد
    code VARCHAR(20) UNIQUE NOT NULL, -- WHATSAPP, TEACHER_APP, ADMIN_APP, PARENT_APP
    is_active BOOLEAN DEFAULT TRUE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='قنوات الإرسال';

-- ملاحظة: تم نقل جداول Lookup الخاصة بالأنواع والقنوات إلى "البنية المشتركة" (System 01).

-- 2. القوالب الذكية (Templates)
CREATE TABLE IF NOT EXISTS notification_templates (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    type_id TINYINT UNSIGNED NOT NULL,
    title_template VARCHAR(100) NOT NULL, -- "غياب الطالب {student_name}"
    body_template TEXT NOT NULL, -- "نود إشعاركم بغياب ابنكم اليوم {date} الساعة {time}."
    whatsapp_template_id VARCHAR(100), -- معرف القالب في Facebook Business API
    parameters_schema JSON, -- الحقول المطلوبة: ["student_name", "date", "time"]
    is_active BOOLEAN DEFAULT TRUE,
    FOREIGN KEY (type_id) REFERENCES lookup_notification_types(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='قوالب الإشعارات الذكية';

-- 3. قواعد التجميع والتفضيلات (Logic & Preferences)
CREATE TABLE IF NOT EXISTS notification_rules (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    rule_name VARCHAR(100),
    condition_json JSON, -- شروط التجميع (مثلاً: إذا تجاوز عدد الغيابات 10 في نفس اليوم)
    action_type ENUM('SEND_IMMEDIATELY', 'GROUP_SUMMARY', 'DELAY'),
    grouping_window_minutes INT DEFAULT 0, -- تجميع الإشعارات خلال X دقيقة
    target_channel_id TINYINT UNSIGNED,
    FOREIGN KEY (target_channel_id) REFERENCES lookup_notification_channels(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='قواعد الإرسال الآلي';

CREATE TABLE IF NOT EXISTS user_notification_preferences (
    user_id INT NOT NULL, -- يمكن أن يكون ولي أمر (عبر حساب الوالد) أو موظف
    user_type ENUM('PARENT', 'EMPLOYEE') NOT NULL,
    channel_id TINYINT UNSIGNED NOT NULL,
    is_enabled BOOLEAN DEFAULT TRUE,
    do_not_disturb_start TIME, -- وقت بداية عدم الإزعاج
    do_not_disturb_end TIME, -- وقت نهاية عدم الإزعاج
    PRIMARY KEY (user_id, user_type, channel_id),
    FOREIGN KEY (channel_id) REFERENCES lookup_notification_channels(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='تفضيلات المستخدمين للإشعارات';

-- 4. المحرك الرئيسي (Engine)
CREATE TABLE IF NOT EXISTS notifications_queue (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    recipient_id INT UNSIGNED NOT NULL, -- معرف المستقبل (ولي أمر / موظف)
    recipient_type ENUM('PARENT', 'EMPLOYEE') NOT NULL,
    recipient_phone VARCHAR(20), -- رقم الهاتف (للواتساب)
    
    type_id TINYINT UNSIGNED NOT NULL,
    template_id INT UNSIGNED NULL COMMENT 'القالب الأصلي',
    
    -- المحتوى الفعلي (Rendered Content)
    title VARCHAR(150),
    body TEXT,
    
    related_entity_table VARCHAR(50), -- الجدول المرتبط (مثل student_attendance)
    related_entity_id BIGINT UNSIGNED, -- معرف السجل المرتبط
    
    status_id TINYINT UNSIGNED NOT NULL DEFAULT 1 COMMENT 'FK to lookup_notification_statuses',
    channel_id TINYINT UNSIGNED NOT NULL,
    
    priority ENUM('CRITICAL', 'HIGH', 'MEDIUM', 'LOW') DEFAULT 'MEDIUM',
    
    -- الجدولة والزمن
    scheduled_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, -- وقت الإرسال المجدول
    expires_at TIMESTAMP NULL COMMENT 'تاريخ انتهاء صلاحية الرسالة',
    sent_at TIMESTAMP NULL,
    delivered_at TIMESTAMP NULL,
    read_at TIMESTAMP NULL,
    
    -- محاولات الإرسال (Retry Logic)
    retry_count TINYINT UNSIGNED DEFAULT 0,
    max_retries TINYINT UNSIGNED DEFAULT 3,
    last_retry_at TIMESTAMP NULL,
    error_message TEXT,
    
    group_id VARCHAR(50) NULL, -- معرف التجميع (إذا كان جزءاً من ملخص)
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (type_id) REFERENCES lookup_notification_types(id),
    FOREIGN KEY (template_id) REFERENCES notification_templates(id),
    FOREIGN KEY (channel_id) REFERENCES lookup_notification_channels(id),
    FOREIGN KEY (status_id) REFERENCES lookup_notification_statuses(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='طابور الإشعارات (المحرك الرئيسي)';

-- 5. سجلات واتساب (WhatsApp Logs - تغذية راجعة)
CREATE TABLE IF NOT EXISTS whatsapp_interactions (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    notification_id BIGINT,
    whatsapp_message_id VARCHAR(100), -- المعرف من API
    status VARCHAR(50), -- sent, delivered, read, failed
    interaction_type ENUM('STATUS_UPDATE', 'REPLY'),
    payload JSON, -- البيانات الخام من Webhook
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (notification_id) REFERENCES notifications_queue(id)
);

-- 6. تقارير الأداء (Views)

-- تقرير التفاعل اليومي
DROP VIEW IF EXISTS v_daily_notification_stats;
CREATE VIEW v_daily_notification_stats AS
SELECT 
    DATE(nq.created_at) as log_date,
    nq.channel_id,
    COUNT(*) as total_sent,
    SUM(CASE WHEN lns.code = 'READ' THEN 1 ELSE 0 END) as total_read,
    SUM(CASE WHEN lns.code = 'FAILED' THEN 1 ELSE 0 END) as total_failed
FROM notifications_queue nq
JOIN lookup_notification_statuses lns ON nq.status_id = lns.id
GROUP BY DATE(nq.created_at), nq.channel_id;

-- تقرير استجابة أولياء الأمور
DROP VIEW IF EXISTS v_parent_engagement;
CREATE VIEW v_parent_engagement AS
SELECT 
    nq.recipient_id as parent_id,
    COUNT(*) as total_received,
    SUM(CASE WHEN lns.code = 'READ' THEN 1 ELSE 0 END) as read_count,
    ROUND((SUM(CASE WHEN lns.code = 'READ' THEN 1 ELSE 0 END) / COUNT(*)) * 100, 2) as read_percentage
FROM notifications_queue nq
JOIN lookup_notification_statuses lns ON nq.status_id = lns.id
WHERE nq.recipient_type = 'PARENT'
GROUP BY nq.recipient_id;

-- 6. جدول الرسائل الداخلية (منقول من نظام التعليم)
CREATE TABLE IF NOT EXISTS communication_messages (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    sender_user_id INT UNSIGNED NOT NULL, 
    recipient_type ENUM('USER', 'ROLE', 'ALL') DEFAULT 'USER',
    recipient_id INT UNSIGNED DEFAULT NULL,
    title VARCHAR(255),
    body TEXT,
    priority ENUM('NORMAL', 'HIGH', 'URGENT') DEFAULT 'NORMAL',
    sent_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_read BOOLEAN DEFAULT FALSE,
    FOREIGN KEY (sender_user_id) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='الرسائل الداخلية والتعاميم';

/*
    ========================================================================
    ملاحظات التكامل:
    - يتم إدراج إشعار في notifications_queue تلقائياً عبر Triggers في الأنظمة الأخرى
      (مثلاً: عند إدراج غياب في student_attendance، يتم تفعيل Trigger يضيف صفاً هنا).
    - أو عبر تطبيق (Service) يعمل في الخلفية ويراقب الجداول.
    ========================================================================
*/
