-- ╔══════════════════════════════════════════════════════════════════════════════╗
-- ║           نظام الدرجات والتقويم الذكي (SGAS) - v3.1                        ║
-- ║           ملف 6: تحضير الدروس (Lesson Preparation)                         ║
-- ╚══════════════════════════════════════════════════════════════════════════════╝

-- التاريخ: 2026-02-14
-- الإصدار: 3.1 (Enhanced — employee_id → created_by)
-- الاعتمادات: System 01 (users), System 02 (النواة)
-- التغييرات عن v3.0:
--   ✅ employee_id → created_by (FK → users.id)

-- ═══════════════════════════════════════════════════════════════════════════════
-- 1. تحضير الدروس
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS lesson_preparation (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    created_by INT UNSIGNED NOT NULL COMMENT 'المستخدم الذي حضّر الدرس (FK → users)',
    subject_id INT UNSIGNED NOT NULL COMMENT 'المادة',
    classroom_id INT UNSIGNED NOT NULL COMMENT 'الفصل/الشعبة',
    prep_date DATE NOT NULL COMMENT 'تاريخ التحضير',
    lesson_title VARCHAR(255) NOT NULL COMMENT 'عنوان الدرس',
    objectives TEXT COMMENT 'الأهداف السلوكية',
    strategies TEXT COMMENT 'استراتيجيات التدريس',
    aids TEXT COMMENT 'الوسائل التعليمية',
    is_approved BOOLEAN DEFAULT FALSE COMMENT 'هل تمت الموافقة عليه من المشرف؟',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    INDEX idx_prep_creator (created_by),
    INDEX idx_prep_classroom (classroom_id),
    INDEX idx_prep_date (prep_date),
    
    FOREIGN KEY (created_by) REFERENCES users(id),
    FOREIGN KEY (subject_id) REFERENCES subjects(id),
    FOREIGN KEY (classroom_id) REFERENCES classrooms(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='تحضير خطط الدروس (مرتبط بمستخدم + مادة + فصل)';

-- ═══════════════════════════════════════════════════════════════════════════════
SELECT '✅ DDL_LESSON_PREP v3.1: تم إنشاء جدول تحضير الدروس بنجاح' AS message;
