-- ╔══════════════════════════════════════════════════════════════════════════════╗
-- ║         نظام جدولة الاختبارات وتوزيع اللجان (ETDS) - v2.0                 ║
-- ║         ملف الجدولة: Exam Timetabling & Scheduling                        ║
-- ╚══════════════════════════════════════════════════════════════════════════════╝

-- التاريخ: 2026-02-19
-- الإصدار: 2.0 (نظام فرعي مستقل للجدولة - منقول من System 05 ومُعزّز)
-- الاعتمادات: System 01 (users), System 02 (النواة), System 04 (الطلاب), System 05 (الفترات)
-- المهندس المسؤول: موسى العواضي

-- ═══════════════════════════════════════════════════════════════════════════════
-- 1. جدول مرجعي: أنواع الاختبارات (موحّد لكل الأنظمة)
-- ═══════════════════════════════════════════════════════════════════════════════
-- يحل محل ENUM في exam_periods.type و exam_sessions.exam_type
-- يُستخدم في: System 05 (grading_policies, exam_periods) + System 08 (exam_sessions, exam_timetable)

CREATE TABLE IF NOT EXISTS lookup_exam_types (
    id TINYINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    code VARCHAR(20) NOT NULL UNIQUE COMMENT 'رمز النوع (MONTHLY, MIDTERM, FINAL...)',
    name_ar VARCHAR(50) NOT NULL COMMENT 'الاسم بالعربية',
    name_en VARCHAR(50) NULL COMMENT 'الاسم بالإنجليزية',
    requires_committee BOOLEAN DEFAULT FALSE COMMENT 'هل يتطلب لجان وتوزيع مقاعد؟',
    sort_order TINYINT UNSIGNED DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='أنواع الاختبارات الموحدة (تُستخدم في System 05 + 08)';

INSERT INTO lookup_exam_types (code, name_ar, name_en, requires_committee, sort_order) VALUES
('MONTHLY',     'شهري',         'Monthly',      FALSE, 1),
('MIDTERM',     'منتصف الفصل',  'Midterm',      TRUE,  2),
('FINAL',       'نهائي',        'Final',        TRUE,  3),
('DIAGNOSTIC',  'تشخيصي',       'Diagnostic',   FALSE, 4),
('CUSTOM',      'مخصص',         'Custom',       FALSE, 5);

-- ═══════════════════════════════════════════════════════════════════════════════
-- 2. جدول مرجعي: الفترات الزمنية للاختبارات (Time Slots)
-- ═══════════════════════════════════════════════════════════════════════════════
-- يحدد أوقات الاختبارات المتاحة خلال اليوم
-- مثال: الفترة الأولى 8:00-10:00، الفترة الثانية 10:00-12:00

CREATE TABLE IF NOT EXISTS lookup_exam_time_slots (
    id TINYINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name_ar VARCHAR(50) NOT NULL COMMENT 'اسم الفترة (الفترة الأولى، الثانية...)',
    start_time TIME NOT NULL COMMENT 'وقت البداية',
    end_time TIME NOT NULL COMMENT 'وقت النهاية',
    duration_minutes SMALLINT UNSIGNED GENERATED ALWAYS AS (TIMESTAMPDIFF(MINUTE, start_time, end_time)) STORED
        COMMENT 'المدة بالدقائق (محسوبة)',
    period_id TINYINT UNSIGNED NULL COMMENT 'FK → lookup_periods (صباحي/مسائي)',
    sort_order TINYINT UNSIGNED DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CHECK (end_time > start_time),
    FOREIGN KEY (period_id) REFERENCES lookup_periods(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='الفترات الزمنية المتاحة للاختبارات خلال اليوم';

INSERT INTO lookup_exam_time_slots (name_ar, start_time, end_time, sort_order) VALUES
('الفترة الأولى',  '08:00:00', '10:00:00', 1),
('الفترة الثانية', '10:00:00', '12:00:00', 2),
('الفترة الثالثة', '12:00:00', '14:00:00', 3);

-- ═══════════════════════════════════════════════════════════════════════════════
-- 3. جدول مرجعي: أنواع مقر الاختبار
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS lookup_exam_venues (
    id TINYINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    code VARCHAR(20) NOT NULL UNIQUE,
    name_ar VARCHAR(50) NOT NULL,
    description VARCHAR(200) NULL,
    is_active BOOLEAN DEFAULT TRUE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='أنواع أماكن إجراء الاختبار';

INSERT INTO lookup_exam_venues (code, name_ar, description) VALUES
('CLASSROOM', 'في الفصل العادي', 'الطالب يختبر في فصله الدراسي العادي — للاختبارات الشهرية'),
('COMMITTEE', 'في لجنة امتحانية', 'الطالب يُوزع على لجنة مع مقعد — للنهائية والمنتصف');

-- ═══════════════════════════════════════════════════════════════════════════════
-- 4. جدول الاختبارات الرئيسي (Exam Timetable)
-- ═══════════════════════════════════════════════════════════════════════════════
-- يحل محل exam_schedules القديم من System 05
-- يحدد: أي مادة، أي صف، أي يوم، أي فترة زمنية، أين (فصل أم لجنة)
-- لا تُحدد التواريخ في exam_periods — بل هنا

CREATE TABLE IF NOT EXISTS exam_timetable (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,

    -- ربط بالفترة الامتحانية (من System 05)
    exam_period_id INT UNSIGNED NOT NULL COMMENT 'FK → exam_periods (النوع الأكاديمي)',

    -- ربط بجلسة اللجان (من System 08) — فقط للاختبارات التي تتطلب لجان
    exam_session_id INT UNSIGNED NULL COMMENT 'FK → exam_sessions (NULL = لا حاجة للجان)',

    -- ماذا؟
    subject_id INT UNSIGNED NOT NULL COMMENT 'المادة',
    grade_level_id INT UNSIGNED NOT NULL COMMENT 'الصف (كل الشعب)',
    classroom_id INT UNSIGNED NULL COMMENT 'شعبة محددة (NULL = كل شعب الصف)',

    -- متى؟
    exam_date DATE NOT NULL COMMENT 'تاريخ الاختبار',
    time_slot_id TINYINT UNSIGNED NULL COMMENT 'الفترة الزمنية (NULL = في وقت الحصة العادية)',

    -- أين؟
    venue_type_id TINYINT UNSIGNED NOT NULL DEFAULT 1 COMMENT 'FK → lookup_exam_venues',

    -- تفاصيل الاختبار
    max_score DECIMAL(5,2) NOT NULL DEFAULT 20.00 COMMENT 'الدرجة العظمى للاختبار',
    duration_minutes SMALLINT UNSIGNED NULL COMMENT 'مدة الاختبار بالدقائق (تجاوز مدة الفترة)',

    -- ملاحظات وحالة
    notes TEXT NULL,
    is_active BOOLEAN DEFAULT TRUE COMMENT 'حذف ناعم',

    -- التدقيق
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NULL ON UPDATE CURRENT_TIMESTAMP,
    created_by_user_id INT UNSIGNED NULL,

    -- الفهارس
    INDEX idx_et_period (exam_period_id),
    INDEX idx_et_session (exam_session_id),
    INDEX idx_et_subject (subject_id),
    INDEX idx_et_grade (grade_level_id),
    INDEX idx_et_date (exam_date),
    INDEX idx_et_venue (venue_type_id),

    -- قيد فريد: مادة واحدة لكل صف/فترة (أو شعبة إن حُددت)
    UNIQUE KEY uk_exam_timetable (exam_period_id, subject_id, grade_level_id, classroom_id),

    -- المفاتيح الخارجية
    FOREIGN KEY (exam_period_id) REFERENCES exam_periods(id) ON DELETE RESTRICT,
    FOREIGN KEY (exam_session_id) REFERENCES exam_sessions(id) ON DELETE SET NULL,
    FOREIGN KEY (subject_id) REFERENCES subjects(id) ON DELETE RESTRICT,
    FOREIGN KEY (grade_level_id) REFERENCES grade_levels(id) ON DELETE RESTRICT,
    FOREIGN KEY (classroom_id) REFERENCES classrooms(id) ON DELETE SET NULL,
    FOREIGN KEY (time_slot_id) REFERENCES lookup_exam_time_slots(id) ON DELETE SET NULL,
    FOREIGN KEY (venue_type_id) REFERENCES lookup_exam_venues(id) ON DELETE RESTRICT,
    FOREIGN KEY (created_by_user_id) REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='جدول الاختبارات الرئيسي — يحدد ماذا ومتى وأين لكل اختبار';

-- ═══════════════════════════════════════════════════════════════════════════════
-- 5. جدول المراقبين
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS lookup_proctor_roles (
    id TINYINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name_ar VARCHAR(50) NOT NULL,
    code VARCHAR(30) NOT NULL UNIQUE,
    is_active BOOLEAN DEFAULT TRUE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='أدوار المراقبين';

INSERT INTO lookup_proctor_roles (name_ar, code) VALUES
('رئيس لجنة', 'HEAD'),
('مراقب', 'PROCTOR'),
('مراقب احتياطي', 'BACKUP'),
('مسؤول التصحيح', 'GRADER');

CREATE TABLE IF NOT EXISTS exam_proctors (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    exam_session_id INT UNSIGNED NOT NULL COMMENT 'جلسة الامتحان',
    committee_id INT UNSIGNED NOT NULL COMMENT 'اللجنة',
    employee_id INT UNSIGNED NOT NULL COMMENT 'المراقب (FK → employees)',
    role_id TINYINT UNSIGNED NOT NULL DEFAULT 2 COMMENT 'FK → lookup_proctor_roles',
    assignment_date DATE NULL COMMENT 'تاريخ التكليف',
    is_active BOOLEAN DEFAULT TRUE,
    notes TEXT NULL,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by_user_id INT UNSIGNED NULL,

    -- قيد فريد: مراقب واحد في لجنة واحدة بنفس الجلسة
    UNIQUE KEY uk_proctor_session_committee (exam_session_id, committee_id, employee_id),
    -- قيد: المراقب لا يُعيّن في أكثر من لجنة بنفس الجلسة
    UNIQUE KEY uk_proctor_single_committee (exam_session_id, employee_id),

    INDEX idx_ep_session (exam_session_id),
    INDEX idx_ep_committee (committee_id),
    INDEX idx_ep_employee (employee_id),

    FOREIGN KEY (exam_session_id) REFERENCES exam_sessions(id) ON DELETE CASCADE,
    FOREIGN KEY (committee_id) REFERENCES exam_committees(id) ON DELETE CASCADE,
    FOREIGN KEY (employee_id) REFERENCES employees(id) ON DELETE CASCADE,
    FOREIGN KEY (role_id) REFERENCES lookup_proctor_roles(id) ON DELETE RESTRICT,
    FOREIGN KEY (created_by_user_id) REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='تعيين المراقبين على لجان الامتحان — مراقب في لجنة واحدة فقط بنفس الجلسة';

-- ═══════════════════════════════════════════════════════════════════════════════
-- 6. قوالب الفترات الامتحانية (لإعادة الاستخدام سنوياً)
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS exam_period_templates (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name_ar VARCHAR(100) NOT NULL COMMENT 'اسم القالب',
    exam_type_id TINYINT UNSIGNED NOT NULL COMMENT 'FK → lookup_exam_types',
    semester_number TINYINT UNSIGNED NOT NULL COMMENT '1 أو 2',
    relative_start_week TINYINT UNSIGNED NULL COMMENT 'بداية نسبية من أول الفصل (أسبوع)',
    duration_days TINYINT UNSIGNED NULL COMMENT 'المدة بالأيام',
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CHECK (semester_number BETWEEN 1 AND 2),
    FOREIGN KEY (exam_type_id) REFERENCES lookup_exam_types(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='قوالب الفترات الامتحانية — تُعرّف مرة وتُعاد استخدامها كل عام';

INSERT INTO exam_period_templates (name_ar, exam_type_id, semester_number, relative_start_week, duration_days) VALUES
('اختبار الشهر الأول - الفصل الأول',  1, 1, 4, 5),
('اختبار الشهر الثاني - الفصل الأول', 1, 1, 8, 5),
('اختبار الشهر الأول - الفصل الثاني', 1, 2, 4, 5),
('اختبار الشهر الثاني - الفصل الثاني', 1, 2, 8, 5),
('منتصف الفصل الأول',                  2, 1, 6, 7),
('منتصف الفصل الثاني',                 2, 2, 6, 7),
('الاختبار النهائي - الفصل الأول',      3, 1, 16, 14),
('الاختبار النهائي - الفصل الثاني',     3, 2, 16, 14);

-- ═══════════════════════════════════════════════════════════════════════════════
-- 7. ربط جلسة اللجان بالفترات الامتحانية
-- ═══════════════════════════════════════════════════════════════════════════════
-- ملاحظة: هذا الجدول كان في System 05 وتم نقله هنا لأنه يخص الربط اللوجستي

CREATE TABLE IF NOT EXISTS exam_session_periods (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    exam_session_id INT UNSIGNED NOT NULL COMMENT 'FK → exam_sessions',
    exam_period_id INT UNSIGNED NOT NULL COMMENT 'FK → exam_periods (System 05)',

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    UNIQUE KEY uk_session_period (exam_session_id, exam_period_id),

    FOREIGN KEY (exam_session_id) REFERENCES exam_sessions(id) ON DELETE CASCADE,
    FOREIGN KEY (exam_period_id) REFERENCES exam_periods(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='ربط جلسات اللجان بالفترات الامتحانية الأكاديمية';

-- ═══════════════════════════════════════════════════════════════════════════════
-- 8. Triggers: التحقق والحماية
-- ═══════════════════════════════════════════════════════════════════════════════

DELIMITER //

-- ─── 8.1 منع تعارض وقت اختبارين لنفس الصف في نفس اليوم والفترة ───
CREATE TRIGGER trg_exam_timetable_no_conflict_insert
BEFORE INSERT ON exam_timetable
FOR EACH ROW
BEGIN
    DECLARE v_conflict INT DEFAULT 0;
    DECLARE v_is_locked BOOLEAN DEFAULT FALSE;
    DECLARE v_is_school_day BOOLEAN DEFAULT TRUE;

    -- التحقق من قفل الفترة الامتحانية
    SELECT ep.is_locked INTO v_is_locked
    FROM exam_periods ep
    WHERE ep.id = NEW.exam_period_id
    LIMIT 1;

    IF v_is_locked = TRUE THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'لا يمكن إضافة اختبار داخل فترة امتحانية مقفلة';
    END IF;

    -- التحقق من التقويم المرجعي: هل التاريخ يوم دراسي؟
    SELECT cm.is_school_day INTO v_is_school_day
    FROM calendar_master cm
    WHERE cm.gregorian_date = NEW.exam_date
    LIMIT 1;

    IF v_is_school_day = FALSE THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'لا يمكن جدولة اختبار في يوم غير دراسي (عطلة أو إجازة)';
    END IF;

    -- التحقق من تعارض الوقت (إذا حُددت فترة زمنية)
    IF NEW.time_slot_id IS NOT NULL THEN
        SELECT COUNT(*) INTO v_conflict
        FROM exam_timetable et
        WHERE et.exam_date = NEW.exam_date
          AND et.time_slot_id = NEW.time_slot_id
          AND et.grade_level_id = NEW.grade_level_id
          AND et.is_active = TRUE
          AND et.id != COALESCE(NEW.id, 0)
          -- إذا كلاهما لكل الشعب أو أحدهما لكل الشعب
          AND (et.classroom_id IS NULL OR NEW.classroom_id IS NULL OR et.classroom_id = NEW.classroom_id);

        IF v_conflict > 0 THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'يوجد تعارض: اختبار آخر لنفس الصف في نفس اليوم والفترة الزمنية';
        END IF;
    END IF;

    -- التحقق من الدرجة العظمى
    IF NEW.max_score <= 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'الدرجة العظمى للاختبار يجب أن تكون أكبر من صفر';
    END IF;
END//

CREATE TRIGGER trg_exam_timetable_no_conflict_update
BEFORE UPDATE ON exam_timetable
FOR EACH ROW
BEGIN
    DECLARE v_conflict INT DEFAULT 0;
    DECLARE v_is_locked BOOLEAN DEFAULT FALSE;
    DECLARE v_is_school_day BOOLEAN DEFAULT TRUE;

    -- التحقق من قفل الفترة الامتحانية
    SELECT ep.is_locked INTO v_is_locked
    FROM exam_periods ep
    WHERE ep.id = NEW.exam_period_id
    LIMIT 1;

    IF v_is_locked = TRUE THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'لا يمكن تعديل اختبار داخل فترة امتحانية مقفلة';
    END IF;

    -- التحقق من التقويم المرجعي
    SELECT cm.is_school_day INTO v_is_school_day
    FROM calendar_master cm
    WHERE cm.gregorian_date = NEW.exam_date
    LIMIT 1;

    IF v_is_school_day = FALSE THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'لا يمكن جدولة اختبار في يوم غير دراسي';
    END IF;

    -- التحقق من تعارض الوقت
    IF NEW.time_slot_id IS NOT NULL THEN
        SELECT COUNT(*) INTO v_conflict
        FROM exam_timetable et
        WHERE et.exam_date = NEW.exam_date
          AND et.time_slot_id = NEW.time_slot_id
          AND et.grade_level_id = NEW.grade_level_id
          AND et.is_active = TRUE
          AND et.id != NEW.id
          AND (et.classroom_id IS NULL OR NEW.classroom_id IS NULL OR et.classroom_id = NEW.classroom_id);

        IF v_conflict > 0 THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'يوجد تعارض: اختبار آخر لنفس الصف في نفس اليوم والفترة الزمنية';
        END IF;
    END IF;

    IF NEW.max_score <= 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'الدرجة العظمى للاختبار يجب أن تكون أكبر من صفر';
    END IF;
END//

-- ─── 8.2 التحقق من تقاطع تواريخ الجلسة والفترة ───
CREATE TRIGGER trg_esp_validate_dates_insert
BEFORE INSERT ON exam_session_periods
FOR EACH ROW
BEGIN
    DECLARE v_session_start DATE;
    DECLARE v_session_end DATE;
    DECLARE v_period_start DATE;
    DECLARE v_period_end DATE;

    SELECT start_date, end_date INTO v_session_start, v_session_end
    FROM exam_sessions WHERE id = NEW.exam_session_id;

    SELECT start_date, end_date INTO v_period_start, v_period_end
    FROM exam_periods WHERE id = NEW.exam_period_id;

    -- التحقق من وجود تقاطع زمني
    IF v_session_end IS NOT NULL AND v_period_start IS NOT NULL
       AND v_session_end < v_period_start THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'لا يوجد تقاطع زمني بين الجلسة والفترة الامتحانية';
    END IF;

    IF v_session_start IS NOT NULL AND v_period_end IS NOT NULL
       AND v_session_start > v_period_end THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'لا يوجد تقاطع زمني بين الجلسة والفترة الامتحانية';
    END IF;
END//

DELIMITER ;

-- ═══════════════════════════════════════════════════════════════════════════════
-- 9. Procedure: توليد درجات الطلاب تلقائياً من جدول الاختبارات
-- ═══════════════════════════════════════════════════════════════════════════════

DELIMITER //

CREATE PROCEDURE sp_populate_exam_scores(IN p_exam_timetable_id INT)
BEGIN
    DECLARE v_grade_level_id INT;
    DECLARE v_classroom_id INT;
    DECLARE v_max_score DECIMAL(5,2);

    SELECT grade_level_id, classroom_id, max_score
    INTO v_grade_level_id, v_classroom_id, v_max_score
    FROM exam_timetable
    WHERE id = p_exam_timetable_id
    LIMIT 1;

    IF v_grade_level_id IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'الاختبار غير موجود في جدول الاختبارات';
    END IF;

    -- إدراج سجلات الدرجات لكل طالب مسجل في الصف/الشعبة
    INSERT IGNORE INTO student_exam_scores (enrollment_id, exam_timetable_id)
    SELECT se.id, p_exam_timetable_id
    FROM student_enrollments se
    JOIN classrooms c ON se.classroom_id = c.id
    WHERE c.grade_level_id = v_grade_level_id
      AND se.is_active = TRUE
      AND (v_classroom_id IS NULL OR se.classroom_id = v_classroom_id);
END//

DELIMITER ;

-- ═══════════════════════════════════════════════════════════════════════════════
-- 10. Views: تقارير الجدولة
-- ═══════════════════════════════════════════════════════════════════════════════

-- View: جدول اختبارات صف معين
CREATE OR REPLACE VIEW v_exam_timetable_by_grade AS
SELECT
    et.id AS timetable_id,
    ep.name_ar AS period_name,
    let.name_ar AS exam_type,
    gl.id AS grade_level_id,
    gl.name_ar AS grade_name,
    COALESCE(c.name_ar, 'كل الشعب') AS classroom_name,
    sub.name_ar AS subject_name,
    sub.code AS subject_code,
    et.exam_date,
    cm.day_name_ar AS day_name,
    cm.hijri_date,
    COALESCE(ets.name_ar, 'وقت الحصة') AS time_slot,
    COALESCE(ets.start_time, NULL) AS start_time,
    COALESCE(ets.end_time, NULL) AS end_time,
    lev.name_ar AS venue_type,
    et.max_score,
    et.duration_minutes
FROM exam_timetable et
JOIN exam_periods ep ON et.exam_period_id = ep.id
JOIN lookup_exam_types let ON ep.exam_type_id = let.id
JOIN grade_levels gl ON et.grade_level_id = gl.id
LEFT JOIN classrooms c ON et.classroom_id = c.id
JOIN subjects sub ON et.subject_id = sub.id
LEFT JOIN calendar_master cm ON et.exam_date = cm.gregorian_date
LEFT JOIN lookup_exam_time_slots ets ON et.time_slot_id = ets.id
JOIN lookup_exam_venues lev ON et.venue_type_id = lev.id
WHERE et.is_active = TRUE
ORDER BY et.exam_date, ets.sort_order, sub.sort_order;

-- View: جدول يوم اختبار كامل
CREATE OR REPLACE VIEW v_exam_day_schedule AS
SELECT
    et.exam_date,
    cm.day_name_ar AS day_name,
    cm.hijri_date,
    cm.hijri_month_name,
    gl.name_ar AS grade_name,
    sub.name_ar AS subject_name,
    COALESCE(ets.name_ar, 'وقت الحصة') AS time_slot,
    lev.name_ar AS venue,
    COALESCE(c.name_ar, 'كل الشعب') AS classroom,
    et.max_score,
    ep.name_ar AS period_name
FROM exam_timetable et
JOIN exam_periods ep ON et.exam_period_id = ep.id
JOIN grade_levels gl ON et.grade_level_id = gl.id
JOIN subjects sub ON et.subject_id = sub.id
LEFT JOIN classrooms c ON et.classroom_id = c.id
LEFT JOIN calendar_master cm ON et.exam_date = cm.gregorian_date
LEFT JOIN lookup_exam_time_slots ets ON et.time_slot_id = ets.id
JOIN lookup_exam_venues lev ON et.venue_type_id = lev.id
WHERE et.is_active = TRUE
ORDER BY et.exam_date, gl.sort_order, ets.sort_order;

-- View: ملخص المراقبين لكل جلسة
CREATE OR REPLACE VIEW v_exam_proctors_summary AS
SELECT
    es.id AS session_id,
    es.exam_name,
    ec.committee_number,
    ec.location AS committee_location,
    ep.employee_id,
    e.full_name AS proctor_name,
    lpr.name_ar AS proctor_role,
    ep.assignment_date,
    ep.is_active
FROM exam_proctors ep
JOIN exam_sessions es ON ep.exam_session_id = es.id
JOIN exam_committees ec ON ep.committee_id = ec.id
JOIN employees e ON ep.employee_id = e.id
JOIN lookup_proctor_roles lpr ON ep.role_id = lpr.id
ORDER BY es.id, ec.committee_number, lpr.id;

-- ═══════════════════════════════════════════════════════════════════════════════
SELECT '✅ DDL_SCHEDULING v2.0: تم إنشاء نظام جدولة الاختبارات بنجاح' AS message;
