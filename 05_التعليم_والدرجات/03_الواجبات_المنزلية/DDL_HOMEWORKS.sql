-- ╔══════════════════════════════════════════════════════════════════════════════╗
-- ║           نظام الدرجات والتقويم الذكي (SGAS) - v3.3                        ║
-- ║           ملف 3: الواجبات المنزلية (Homeworks - Enhanced)                   ║
-- ╚══════════════════════════════════════════════════════════════════════════════╝

-- التاريخ: 2026-02-14
-- الإصدار: 3.3 (Auto month mapping + strict grade validation)
-- الاعتمادات: System 01 (users), System 02 (النواة), System 04 (الطلاب)

-- ═══════════════════════════════════════════════════════════════════════════════
-- 1. جدول Lookup: أنواع الواجبات
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS lookup_homework_types (
    id TINYINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name_ar VARCHAR(30) NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    UNIQUE KEY uk_lht_name (name_ar)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='أنواع الواجبات (واجب، بحث، مشروع...)';

INSERT INTO lookup_homework_types (name_ar) VALUES
('واجب منزلي'), ('بحث'), ('مشروع'), ('تقرير'), ('نشاط صفي'), ('أخرى')
ON DUPLICATE KEY UPDATE
    is_active = TRUE;

-- ═══════════════════════════════════════════════════════════════════════════════
-- 2. تعريف الواجبات
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS homeworks (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    academic_year_id INT UNSIGNED NOT NULL,
    semester_id INT UNSIGNED NOT NULL COMMENT 'الفصل الدراسي',
    month_id INT UNSIGNED NOT NULL COMMENT 'الشهر الأكاديمي (يُحسب آلياً من homework_date)',
    created_by INT UNSIGNED NOT NULL COMMENT 'المستخدم الذي أنشأ الواجب (FK → users)',
    classroom_id INT UNSIGNED NOT NULL COMMENT 'الفصل/الشعبة',
    subject_id INT UNSIGNED NOT NULL COMMENT 'المادة الدراسية',

    -- تصنيف الواجب
    homework_type_id TINYINT UNSIGNED DEFAULT 1 COMMENT 'نوع الواجب (FK → lookup_homework_types)',

    -- بيانات الواجب
    homework_date DATE NULL COMMENT 'تاريخ إعطاء الواجب',
    due_date DATE NULL COMMENT 'تاريخ التسليم المطلوب',
    title VARCHAR(200) NOT NULL COMMENT 'عنوان الواجب',
    content TEXT COMMENT 'وصف أو تفاصيل الواجب (اختياري)',
    max_grade DECIMAL(5,2) DEFAULT 5.0 COMMENT 'الدرجة المستحقة لهذا الواجب',

    -- حالة الحذف الناعم
    is_active BOOLEAN DEFAULT TRUE COMMENT 'FALSE = محذوف (حذف ناعم)',

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NULL ON UPDATE CURRENT_TIMESTAMP,

    CHECK (max_grade > 0),

    INDEX idx_hw_classroom (classroom_id),
    INDEX idx_hw_subject (subject_id),
    INDEX idx_hw_creator (created_by),
    INDEX idx_hw_month (month_id),
    INDEX idx_hw_type (homework_type_id),
    INDEX idx_hw_active (is_active),
    INDEX idx_hw_due (due_date),

    FOREIGN KEY (academic_year_id) REFERENCES academic_years(id),
    FOREIGN KEY (semester_id) REFERENCES semesters(id),
    FOREIGN KEY (month_id) REFERENCES academic_months(id),
    FOREIGN KEY (created_by) REFERENCES users(id),
    FOREIGN KEY (classroom_id) REFERENCES classrooms(id),
    FOREIGN KEY (subject_id) REFERENCES subjects(id),
    FOREIGN KEY (homework_type_id) REFERENCES lookup_homework_types(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='تعريف الواجبات المنزلية (مرتبط بمادة + فصل + شهر)';

-- ═══════════════════════════════════════════════════════════════════════════════
-- 3. رصد الواجبات للطلاب
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS student_homeworks (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    homework_id INT UNSIGNED NOT NULL,
    enrollment_id INT UNSIGNED NOT NULL COMMENT 'FK → student_enrollments',

    -- الأساسي: هل نفّذ الطالب الواجب؟
    is_completed BOOLEAN DEFAULT FALSE COMMENT 'نفّذ = TRUE / لم ينفّذ = FALSE',

    -- وقت التسليم
    submitted_at TIMESTAMP NULL COMMENT 'وقت تسليم الطالب للواجب',

    -- اختياري: درجة يدوية من المعلم
    manual_grade DECIMAL(5,2) NULL COMMENT 'درجة يدوية اختيارية — NULL = حساب آلي',

    -- ملاحظات
    notes VARCHAR(255) NULL COMMENT 'ملاحظة مختصرة من المعلم',

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NULL ON UPDATE CURRENT_TIMESTAMP,

    UNIQUE KEY uk_student_homework (homework_id, enrollment_id),
    FOREIGN KEY (homework_id) REFERENCES homeworks(id) ON DELETE CASCADE,
    FOREIGN KEY (enrollment_id) REFERENCES student_enrollments(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='رصد واجبات الطلاب (نفذ/لم ينفذ + درجة يدوية اختيارية + وقت التسليم)';

-- ═══════════════════════════════════════════════════════════════════════════════
-- 4. Views
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE OR REPLACE VIEW v_homework_effective_grade AS
SELECT
    sh.id AS student_homework_id,
    sh.homework_id,
    sh.enrollment_id,
    h.subject_id,
    h.classroom_id,
    h.month_id,
    h.homework_type_id,
    h.max_grade,
    sh.is_completed,
    sh.submitted_at,
    sh.manual_grade,
    h.due_date,
    CASE
        WHEN h.due_date IS NOT NULL AND sh.submitted_at IS NOT NULL
             AND DATE(sh.submitted_at) > h.due_date
        THEN TRUE
        ELSE FALSE
    END AS is_late,
    COALESCE(
        sh.manual_grade,
        CASE WHEN sh.is_completed THEN h.max_grade ELSE 0.00 END
    ) AS effective_grade
FROM student_homeworks sh
JOIN homeworks h ON sh.homework_id = h.id
WHERE h.is_active = TRUE;

CREATE OR REPLACE VIEW v_homework_summary AS
SELECT
    h.id AS homework_id,
    h.title,
    h.classroom_id,
    h.subject_id,
    h.month_id,
    h.homework_date,
    h.due_date,
    h.max_grade,
    h.homework_type_id,
    COUNT(sh.id) AS total_students,
    SUM(CASE WHEN sh.is_completed THEN 1 ELSE 0 END) AS completed_count,
    SUM(CASE WHEN NOT sh.is_completed THEN 1 ELSE 0 END) AS not_completed_count,
    ROUND(SUM(sh.is_completed) / NULLIF(COUNT(sh.id), 0) * 100, 1) AS completion_rate,
    AVG(COALESCE(sh.manual_grade, CASE WHEN sh.is_completed THEN h.max_grade ELSE 0 END)) AS avg_grade
FROM homeworks h
LEFT JOIN student_homeworks sh ON h.id = sh.homework_id
WHERE h.is_active = TRUE
GROUP BY h.id, h.title, h.classroom_id, h.subject_id, h.month_id,
         h.homework_date, h.due_date, h.max_grade, h.homework_type_id;

-- ═══════════════════════════════════════════════════════════════════════════════
-- 5. Triggers: homeworks (month_id auto + validation)
-- ═══════════════════════════════════════════════════════════════════════════════

DELIMITER //

CREATE TRIGGER trg_homework_set_month_insert
BEFORE INSERT ON homeworks
FOR EACH ROW
BEGIN
    DECLARE v_month_id INT;
    DECLARE v_given_month_start DATE;

    IF NEW.month_id IS NOT NULL THEN
        SELECT am.id, am.start_date
        INTO v_month_id, v_given_month_start
        FROM academic_months am
        WHERE am.id = NEW.month_id
          AND am.semester_id = NEW.semester_id
        LIMIT 1;

        IF v_month_id IS NULL THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'الشهر الأكاديمي المحدد لا ينتمي للفصل الدراسي المحدد';
        END IF;
    END IF;

    IF NEW.homework_date IS NULL THEN
        SET NEW.homework_date = COALESCE(v_given_month_start, CURRENT_DATE);
    END IF;

    IF NEW.due_date IS NOT NULL AND NEW.due_date < NEW.homework_date THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'تاريخ التسليم لا يمكن أن يكون قبل تاريخ الواجب';
    END IF;

    IF NEW.max_grade <= 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'الدرجة العظمى للواجب يجب أن تكون أكبر من صفر';
    END IF;

    SELECT am.id
    INTO v_month_id
    FROM academic_months am
    WHERE am.semester_id = NEW.semester_id
      AND NEW.homework_date BETWEEN am.start_date AND am.end_date
    LIMIT 1;

    IF v_month_id IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'لا يوجد شهر أكاديمي يطابق تاريخ الواجب داخل الفصل المحدد';
    END IF;

    SET NEW.month_id = v_month_id;
END//

CREATE TRIGGER trg_homework_set_month_update
BEFORE UPDATE ON homeworks
FOR EACH ROW
BEGIN
    DECLARE v_month_id INT;
    DECLARE v_given_month_start DATE;

    IF NEW.month_id IS NOT NULL THEN
        SELECT am.id, am.start_date
        INTO v_month_id, v_given_month_start
        FROM academic_months am
        WHERE am.id = NEW.month_id
          AND am.semester_id = NEW.semester_id
        LIMIT 1;

        IF v_month_id IS NULL THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'الشهر الأكاديمي المحدد لا ينتمي للفصل الدراسي المحدد';
        END IF;
    END IF;

    IF NEW.homework_date IS NULL THEN
        SET NEW.homework_date = COALESCE(v_given_month_start, CURRENT_DATE);
    END IF;

    IF NEW.due_date IS NOT NULL AND NEW.due_date < NEW.homework_date THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'تاريخ التسليم لا يمكن أن يكون قبل تاريخ الواجب';
    END IF;

    IF NEW.max_grade <= 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'الدرجة العظمى للواجب يجب أن تكون أكبر من صفر';
    END IF;

    SELECT am.id
    INTO v_month_id
    FROM academic_months am
    WHERE am.semester_id = NEW.semester_id
      AND NEW.homework_date BETWEEN am.start_date AND am.end_date
    LIMIT 1;

    IF v_month_id IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'لا يوجد شهر أكاديمي يطابق تاريخ الواجب داخل الفصل المحدد';
    END IF;

    SET NEW.month_id = v_month_id;
END//

-- ═══════════════════════════════════════════════════════════════════════════════
-- 6. Triggers: student_homeworks (submitted_at + manual_grade validation)
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE TRIGGER trg_student_homework_validate_insert
BEFORE INSERT ON student_homeworks
FOR EACH ROW
BEGIN
    DECLARE v_max_grade DECIMAL(5,2);

    SELECT h.max_grade INTO v_max_grade
    FROM homeworks h
    WHERE h.id = NEW.homework_id
    LIMIT 1;

    IF v_max_grade IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'الواجب غير موجود';
    END IF;

    IF NEW.manual_grade IS NOT NULL AND (NEW.manual_grade < 0 OR NEW.manual_grade > v_max_grade) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'الدرجة اليدوية خارج النطاق المسموح لهذا الواجب';
    END IF;

    IF NEW.is_completed = TRUE AND NEW.submitted_at IS NULL THEN
        SET NEW.submitted_at = CURRENT_TIMESTAMP;
    END IF;

    IF NEW.is_completed = FALSE THEN
        SET NEW.submitted_at = NULL;
    END IF;
END//

CREATE TRIGGER trg_student_homework_validate_update
BEFORE UPDATE ON student_homeworks
FOR EACH ROW
BEGIN
    DECLARE v_max_grade DECIMAL(5,2);

    SELECT h.max_grade INTO v_max_grade
    FROM homeworks h
    WHERE h.id = NEW.homework_id
    LIMIT 1;

    IF v_max_grade IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'الواجب غير موجود';
    END IF;

    IF NEW.manual_grade IS NOT NULL AND (NEW.manual_grade < 0 OR NEW.manual_grade > v_max_grade) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'الدرجة اليدوية خارج النطاق المسموح لهذا الواجب';
    END IF;

    IF NEW.is_completed = TRUE AND OLD.is_completed = FALSE AND NEW.submitted_at IS NULL THEN
        SET NEW.submitted_at = CURRENT_TIMESTAMP;
    END IF;

    IF NEW.is_completed = FALSE AND OLD.is_completed = TRUE THEN
        SET NEW.submitted_at = NULL;
    END IF;
END//

DELIMITER ;

-- ═══════════════════════════════════════════════════════════════════════════════
-- 7. Procedure: إنشاء رصد آلي لجميع طلاب الفصل عند إنشاء واجب
-- ═══════════════════════════════════════════════════════════════════════════════

DELIMITER //

CREATE PROCEDURE sp_populate_student_homeworks(IN p_homework_id INT)
BEGIN
    DECLARE v_classroom_id INT;

    SELECT classroom_id INTO v_classroom_id
    FROM homeworks
    WHERE id = p_homework_id
    LIMIT 1;

    INSERT IGNORE INTO student_homeworks (homework_id, enrollment_id)
    SELECT p_homework_id, se.id
    FROM student_enrollments se
    WHERE se.classroom_id = v_classroom_id
      AND se.is_active = TRUE;
END//

DELIMITER ;

-- ═══════════════════════════════════════════════════════════════════════════════
-- 8. Trigger: استدعاء sp_populate_student_homeworks بعد إنشاء واجب
-- ═══════════════════════════════════════════════════════════════════════════════

DELIMITER //

CREATE TRIGGER trg_homework_auto_populate
AFTER INSERT ON homeworks
FOR EACH ROW
BEGIN
    CALL sp_populate_student_homeworks(NEW.id);
END//

DELIMITER ;

-- ═══════════════════════════════════════════════════════════════════════════════
SELECT '✅ DDL_HOMEWORKS v3.3: تم إنشاء الواجبات + التحقق + الحساب الآلي للشهر بنجاح' AS message;
