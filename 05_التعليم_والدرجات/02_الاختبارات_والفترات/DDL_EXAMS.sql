-- ╔══════════════════════════════════════════════════════════════════════════════╗
-- ║           نظام الدرجات والتقويم الذكي (SGAS) - v4.0                        ║
-- ║           ملف 2: الفترات الامتحانية ودرجات الطلاب (Exams & Scores)         ║
-- ╚══════════════════════════════════════════════════════════════════════════════╝

-- التاريخ: 2026-02-19
-- الإصدار: 4.0 (إعادة هيكلة — الجدولة انتقلت لـ System 08)
-- الاعتمادات: DDL_POLICIES, System 01, System 02, System 04, System 08 (exam_timetable)

-- ═══════════════════════════════════════════════════════════════════════════════
-- 1. جدول مرجعي: حالات الفترة الامتحانية (State Machine)
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS lookup_exam_period_statuses (
    id TINYINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    code VARCHAR(20) NOT NULL UNIQUE,
    name_ar VARCHAR(50) NOT NULL,
    description VARCHAR(200) NULL,
    sort_order TINYINT UNSIGNED DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='حالات الفترة الامتحانية (مراحل سير العمل)';

INSERT INTO lookup_exam_period_statuses (code, name_ar, description, sort_order) VALUES
('DRAFT',      'مسودة',            'فترة قيد الإعداد — يمكن التعديل بحرية',     1),
('SCHEDULING', 'قيد الجدولة',      'جاري جدولة الاختبارات في System 08',          2),
('SCORING',    'قيد إدخال الدرجات', 'الاختبارات تمت — جاري إدخال الدرجات',        3),
('REVIEW',     'قيد المراجعة',     'الدرجات مدخلة — تحت المراجعة والاعتماد',     4),
('APPROVED',   'معتمدة',           'الفترة معتمدة ومقفلة — لا يمكن التعديل',     5)
ON DUPLICATE KEY UPDATE
    name_ar = VALUES(name_ar),
    description = VALUES(description),
    sort_order = VALUES(sort_order),
    is_active = TRUE;

-- ═══════════════════════════════════════════════════════════════════════════════
-- 2. الفترات الامتحانية (Academic Exam Periods)
-- ═══════════════════════════════════════════════════════════════════════════════
-- ملاحظة: لا تحتوي تواريخ الأيام المحددة — التواريخ في exam_timetable (System 08)
-- start_date/end_date هنا تحدد النطاق العام فقط (مثلاً: أسبوع الاختبارات)

CREATE TABLE IF NOT EXISTS exam_periods (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    academic_year_id INT UNSIGNED NOT NULL,
    semester_id INT UNSIGNED NOT NULL,
    name_ar VARCHAR(100) NOT NULL COMMENT 'مثل: اختبار شهر محرم، اختبار منتصف الفصل الثاني',

    -- نوع الفترة (FK بدل ENUM)
    exam_type_id TINYINT UNSIGNED NOT NULL DEFAULT 1 COMMENT 'FK → lookup_exam_types (System 08)',

    -- النطاق الزمني العام (اختياري — يُعبأ من نظام الجدولة)
    start_date DATE NULL COMMENT 'تاريخ بداية الفترة (عام — التفاصيل في exam_timetable)',
    end_date DATE NULL COMMENT 'تاريخ نهاية الفترة',

    is_active BOOLEAN DEFAULT TRUE,

    -- حالة سير العمل (State Machine)
    status_id TINYINT UNSIGNED NOT NULL DEFAULT 1 COMMENT 'FK → lookup_exam_period_statuses',

    -- التوثيق
    created_by INT UNSIGNED NOT NULL COMMENT 'المستخدم الذي أنشأ الفترة',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    -- قفل البيانات (Governance)
    is_locked BOOLEAN DEFAULT FALSE COMMENT 'قفل الفترة لمنع التعديل',
    locked_at TIMESTAMP NULL,
    locked_by_user_id INT UNSIGNED NULL,

    -- التحقق
    CHECK (end_date IS NULL OR start_date IS NULL OR end_date >= start_date),

    INDEX idx_ep_year (academic_year_id),
    INDEX idx_ep_semester (semester_id),
    INDEX idx_ep_type (exam_type_id),
    INDEX idx_ep_status (status_id),
    INDEX idx_ep_active (is_active),

    FOREIGN KEY (academic_year_id) REFERENCES academic_years(id),
    FOREIGN KEY (semester_id) REFERENCES semesters(id),
    FOREIGN KEY (exam_type_id) REFERENCES lookup_exam_types(id),
    FOREIGN KEY (status_id) REFERENCES lookup_exam_period_statuses(id),
    FOREIGN KEY (created_by) REFERENCES users(id),
    FOREIGN KEY (locked_by_user_id) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='الفترات الامتحانية الأكاديمية — النوع عبر lookup_exam_types والحالة عبر State Machine';

-- ═══════════════════════════════════════════════════════════════════════════════
-- 3. درجات الطلاب في الاختبارات
-- ═══════════════════════════════════════════════════════════════════════════════
-- ملاحظة: exam_schedule_id أصبح exam_timetable_id (FK → System 08)

CREATE TABLE IF NOT EXISTS student_exam_scores (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    exam_timetable_id INT UNSIGNED NOT NULL COMMENT 'FK → exam_timetable (System 08)',
    enrollment_id INT UNSIGNED NOT NULL COMMENT 'FK → student_enrollments',

    -- الدرجة
    score DECIMAL(5,2) DEFAULT 0.00,

    -- الحضور والغياب
    is_present BOOLEAN DEFAULT TRUE,
    absence_type ENUM('بعذر', 'بدون_عذر') NULL COMMENT 'نوع الغياب — NULL إذا حاضر',
    excuse_details TEXT NULL COMMENT 'تفاصيل العذر (للغائبين بعذر)',

    -- ملاحظات
    teacher_notes TEXT,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NULL ON UPDATE CURRENT_TIMESTAMP,

    UNIQUE KEY uk_student_exam (exam_timetable_id, enrollment_id),
    INDEX idx_ses_enrollment (enrollment_id),
    INDEX idx_ses_present (is_present),

    FOREIGN KEY (exam_timetable_id) REFERENCES exam_timetable(id) ON DELETE CASCADE,
    FOREIGN KEY (enrollment_id) REFERENCES student_enrollments(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='درجات الطلاب في الاختبارات — مرتبط بجدول الاختبارات في System 08';

-- ═══════════════════════════════════════════════════════════════════════════════
-- 4. Triggers: التحقق من درجات الطلاب + تطابق الصف + احترام القفل
-- ═══════════════════════════════════════════════════════════════════════════════

DELIMITER //

-- ─── 4.1 Insert trigger: التحقق الشامل ───
CREATE TRIGGER trg_exam_score_validate_insert
BEFORE INSERT ON student_exam_scores
FOR EACH ROW
BEGIN
    DECLARE v_max_score DECIMAL(5,2);
    DECLARE v_is_locked BOOLEAN;
    DECLARE v_exam_grade_level_id INT;
    DECLARE v_student_grade_level_id INT;
    DECLARE v_exam_subject_id INT;
    DECLARE v_exam_classroom_id INT;
    DECLARE v_exam_academic_year_id INT;
    DECLARE v_exam_semester_id INT;
    DECLARE v_current_user_id INT;
    DECLARE v_current_employee_id INT;
    DECLARE v_is_authorized INT DEFAULT 0;

    -- جلب بيانات الاختبار من exam_timetable + exam_periods
    SELECT
        et.max_score,
        ep.is_locked,
        et.grade_level_id,
        et.subject_id,
        et.classroom_id,
        ep.academic_year_id,
        ep.semester_id
    INTO
        v_max_score,
        v_is_locked,
        v_exam_grade_level_id,
        v_exam_subject_id,
        v_exam_classroom_id,
        v_exam_academic_year_id,
        v_exam_semester_id
    FROM exam_timetable et
    JOIN exam_periods ep ON et.exam_period_id = ep.id
    WHERE et.id = NEW.exam_timetable_id
    LIMIT 1;

    IF v_max_score IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'الاختبار غير موجود في جدول الاختبارات';
    END IF;

    IF v_is_locked = TRUE THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'لا يمكن إدخال درجات في فترة امتحانية مقفلة';
    END IF;

    -- §1.2: التحقق من تطابق صف الطالب مع صف الاختبار
    SELECT c.grade_level_id INTO v_student_grade_level_id
    FROM student_enrollments se
    JOIN classrooms c ON se.classroom_id = c.id
    WHERE se.id = NEW.enrollment_id
    LIMIT 1;

    IF v_student_grade_level_id != v_exam_grade_level_id THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'الطالب غير مسجل في صف يتوافق مع هذا الاختبار';
    END IF;

    -- التحقق من تكليف المعلم بالمادة/الفصل (§2.4)
    -- bypass اختياري للعمليات النظامية: SET @skip_teacher_assignment_check = 1;
    IF COALESCE(@skip_teacher_assignment_check, 0) = 0 THEN
        SET v_current_user_id = COALESCE(@current_user_id, NULL);

        IF v_current_user_id IS NULL THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'يجب ضبط @current_user_id قبل إدخال درجات الاختبار';
        END IF;

        SELECT u.employee_id
        INTO v_current_employee_id
        FROM users u
        WHERE u.id = v_current_user_id
          AND u.is_active = TRUE
        LIMIT 1;

        IF v_current_employee_id IS NULL THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'المستخدم الحالي غير مرتبط بملف موظف نشط';
        END IF;

        SELECT COUNT(*)
        INTO v_is_authorized
        FROM teacher_assignments ta
        JOIN classrooms c ON c.id = ta.classroom_id
        WHERE ta.employee_id = v_current_employee_id
          AND ta.academic_year_id = v_exam_academic_year_id
          AND ta.semester_id = v_exam_semester_id
          AND ta.subject_id = v_exam_subject_id
          AND ta.is_active = TRUE
          AND (
                (v_exam_classroom_id IS NOT NULL AND ta.classroom_id = v_exam_classroom_id)
             OR (v_exam_classroom_id IS NULL AND c.grade_level_id = v_exam_grade_level_id)
          );

        IF v_is_authorized = 0 THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'غير مصرح لك بإدخال درجات هذا الاختبار (تحقق من teacher_assignments)';
        END IF;
    END IF;

    -- التحقق من الدرجة
    IF NEW.score > v_max_score THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'الدرجة المدخلة أعلى من الدرجة العظمى للاختبار';
    END IF;

    IF NEW.score < 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'لا يمكن إدخال درجة سالبة';
    END IF;

    -- معالجة الغياب
    IF NEW.is_present = FALSE AND NEW.score > 0 THEN
        SET NEW.score = 0;
    END IF;

    IF NEW.is_present = FALSE AND NEW.absence_type IS NULL THEN
        SET NEW.absence_type = 'بدون_عذر';
    END IF;

    IF NEW.is_present = TRUE THEN
        SET NEW.absence_type = NULL;
        SET NEW.excuse_details = NULL;
    END IF;
END//

-- ─── 4.2 Update trigger ───
CREATE TRIGGER trg_exam_score_validate_update
BEFORE UPDATE ON student_exam_scores
FOR EACH ROW
BEGIN
    DECLARE v_max_score DECIMAL(5,2);
    DECLARE v_old_is_locked BOOLEAN DEFAULT FALSE;
    DECLARE v_new_is_locked BOOLEAN DEFAULT FALSE;
    DECLARE v_exam_grade_level_id INT;
    DECLARE v_student_grade_level_id INT;
    DECLARE v_exam_subject_id INT;
    DECLARE v_exam_classroom_id INT;
    DECLARE v_exam_academic_year_id INT;
    DECLARE v_exam_semester_id INT;
    DECLARE v_current_user_id INT;
    DECLARE v_current_employee_id INT;
    DECLARE v_is_authorized INT DEFAULT 0;

    -- إصلاح ثغرة القفل: تحقق أولًا من الاختبار القديم (OLD)
    SELECT ep.is_locked
    INTO v_old_is_locked
    FROM exam_timetable et
    JOIN exam_periods ep ON et.exam_period_id = ep.id
    WHERE et.id = OLD.exam_timetable_id
    LIMIT 1;

    IF v_old_is_locked = TRUE THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'لا يمكن تعديل سجل درجة مرتبط بفترة امتحانية مقفلة';
    END IF;

    -- تحقق من الاختبار الجديد (NEW)
    SELECT
        et.max_score,
        ep.is_locked,
        et.grade_level_id,
        et.subject_id,
        et.classroom_id,
        ep.academic_year_id,
        ep.semester_id
    INTO
        v_max_score,
        v_new_is_locked,
        v_exam_grade_level_id,
        v_exam_subject_id,
        v_exam_classroom_id,
        v_exam_academic_year_id,
        v_exam_semester_id
    FROM exam_timetable et
    JOIN exam_periods ep ON et.exam_period_id = ep.id
    WHERE et.id = NEW.exam_timetable_id
    LIMIT 1;

    IF v_max_score IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'الاختبار غير موجود في جدول الاختبارات';
    END IF;

    IF v_new_is_locked = TRUE THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'لا يمكن التعديل على فترة امتحانية مقفلة';
    END IF;

    -- التحقق من تطابق صف الطالب مع صف الاختبار
    SELECT c.grade_level_id
    INTO v_student_grade_level_id
    FROM student_enrollments se
    JOIN classrooms c ON se.classroom_id = c.id
    WHERE se.id = NEW.enrollment_id
    LIMIT 1;

    IF v_student_grade_level_id != v_exam_grade_level_id THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'الطالب غير مسجل في صف يتوافق مع هذا الاختبار';
    END IF;

    -- التحقق من تكليف المعلم بالمادة/الفصل (§2.4)
    IF COALESCE(@skip_teacher_assignment_check, 0) = 0 THEN
        SET v_current_user_id = COALESCE(@current_user_id, NULL);

        IF v_current_user_id IS NULL THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'يجب ضبط @current_user_id قبل تعديل درجات الاختبار';
        END IF;

        SELECT u.employee_id
        INTO v_current_employee_id
        FROM users u
        WHERE u.id = v_current_user_id
          AND u.is_active = TRUE
        LIMIT 1;

        IF v_current_employee_id IS NULL THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'المستخدم الحالي غير مرتبط بملف موظف نشط';
        END IF;

        SELECT COUNT(*)
        INTO v_is_authorized
        FROM teacher_assignments ta
        JOIN classrooms c ON c.id = ta.classroom_id
        WHERE ta.employee_id = v_current_employee_id
          AND ta.academic_year_id = v_exam_academic_year_id
          AND ta.semester_id = v_exam_semester_id
          AND ta.subject_id = v_exam_subject_id
          AND ta.is_active = TRUE
          AND (
                (v_exam_classroom_id IS NOT NULL AND ta.classroom_id = v_exam_classroom_id)
             OR (v_exam_classroom_id IS NULL AND c.grade_level_id = v_exam_grade_level_id)
          );

        IF v_is_authorized = 0 THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'غير مصرح لك بتعديل درجات هذا الاختبار (تحقق من teacher_assignments)';
        END IF;
    END IF;

    IF NEW.score > v_max_score THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'الدرجة المدخلة أعلى من الدرجة العظمى للاختبار';
    END IF;

    IF NEW.score < 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'لا يمكن إدخال درجة سالبة';
    END IF;

    IF NEW.is_present = FALSE AND NEW.score > 0 THEN
        SET NEW.score = 0;
    END IF;

    IF NEW.is_present = FALSE AND NEW.absence_type IS NULL THEN
        SET NEW.absence_type = 'بدون_عذر';
    END IF;

    IF NEW.is_present = TRUE THEN
        SET NEW.absence_type = NULL;
        SET NEW.excuse_details = NULL;
    END IF;
END//

-- ─── 4.3 Delete lock trigger ───
CREATE TRIGGER trg_exam_score_lock_delete
BEFORE DELETE ON student_exam_scores
FOR EACH ROW
BEGIN
    DECLARE v_is_locked BOOLEAN;
    DECLARE v_exam_grade_level_id INT;
    DECLARE v_exam_subject_id INT;
    DECLARE v_exam_classroom_id INT;
    DECLARE v_exam_academic_year_id INT;
    DECLARE v_exam_semester_id INT;
    DECLARE v_current_user_id INT;
    DECLARE v_current_employee_id INT;
    DECLARE v_is_authorized INT DEFAULT 0;

    SELECT
        ep.is_locked,
        et.grade_level_id,
        et.subject_id,
        et.classroom_id,
        ep.academic_year_id,
        ep.semester_id
    INTO
        v_is_locked,
        v_exam_grade_level_id,
        v_exam_subject_id,
        v_exam_classroom_id,
        v_exam_academic_year_id,
        v_exam_semester_id
    FROM exam_timetable et
    JOIN exam_periods ep ON et.exam_period_id = ep.id
    WHERE et.id = OLD.exam_timetable_id
    LIMIT 1;

    IF v_is_locked = TRUE THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'لا يمكن حذف درجات من فترة امتحانية مقفلة';
    END IF;

    -- التحقق من تكليف المعلم بالمادة/الفصل (§2.4)
    IF COALESCE(@skip_teacher_assignment_check, 0) = 0 THEN
        SET v_current_user_id = COALESCE(@current_user_id, NULL);

        IF v_current_user_id IS NULL THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'يجب ضبط @current_user_id قبل حذف درجات الاختبار';
        END IF;

        SELECT u.employee_id
        INTO v_current_employee_id
        FROM users u
        WHERE u.id = v_current_user_id
          AND u.is_active = TRUE
        LIMIT 1;

        IF v_current_employee_id IS NULL THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'المستخدم الحالي غير مرتبط بملف موظف نشط';
        END IF;

        SELECT COUNT(*)
        INTO v_is_authorized
        FROM teacher_assignments ta
        JOIN classrooms c ON c.id = ta.classroom_id
        WHERE ta.employee_id = v_current_employee_id
          AND ta.academic_year_id = v_exam_academic_year_id
          AND ta.semester_id = v_exam_semester_id
          AND ta.subject_id = v_exam_subject_id
          AND ta.is_active = TRUE
          AND (
                (v_exam_classroom_id IS NOT NULL AND ta.classroom_id = v_exam_classroom_id)
             OR (v_exam_classroom_id IS NULL AND c.grade_level_id = v_exam_grade_level_id)
          );

        IF v_is_authorized = 0 THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'غير مصرح لك بحذف درجات هذا الاختبار (تحقق من teacher_assignments)';
        END IF;
    END IF;
END//

DELIMITER ;

-- ═══════════════════════════════════════════════════════════════════════════════
-- 5. View: ملخص نتائج اختبار
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE OR REPLACE VIEW v_exam_results_summary AS
SELECT
    et.id AS exam_timetable_id,
    ep.name_ar AS period_name,
    let.name_ar AS exam_type,
    sub.name_ar AS subject_name,
    gl.name_ar AS grade_level_name,
    et.exam_date,
    et.max_score,
    leps.name_ar AS period_status,
    COUNT(ses.id) AS total_students,
    SUM(CASE WHEN ses.is_present THEN 1 ELSE 0 END) AS present_count,
    SUM(CASE WHEN NOT ses.is_present THEN 1 ELSE 0 END) AS absent_count,
    SUM(CASE WHEN ses.absence_type = 'بعذر' THEN 1 ELSE 0 END) AS excused_absent,
    SUM(CASE WHEN ses.absence_type = 'بدون_عذر' THEN 1 ELSE 0 END) AS unexcused_absent,
    ROUND(AVG(CASE WHEN ses.is_present THEN ses.score END), 2) AS avg_score,
    MAX(CASE WHEN ses.is_present THEN ses.score END) AS max_achieved_score,
    MIN(CASE WHEN ses.is_present THEN ses.score END) AS min_achieved_score,
    ROUND(AVG(CASE WHEN ses.is_present THEN (ses.score / NULLIF(et.max_score, 0)) * 100 END), 1) AS avg_percentage,
    SUM(
        CASE
            WHEN ses.is_present
             AND (ses.score / NULLIF(et.max_score, 0)) * 100 >= COALESCE(gp.passing_score, 50)
            THEN 1
            ELSE 0
        END
    ) AS passed_count,
    SUM(
        CASE
            WHEN ses.is_present
             AND (ses.score / NULLIF(et.max_score, 0)) * 100 < COALESCE(gp.passing_score, 50)
            THEN 1
            ELSE 0
        END
    ) AS failed_count
FROM exam_timetable et
JOIN exam_periods ep ON et.exam_period_id = ep.id
JOIN lookup_exam_types let ON ep.exam_type_id = let.id
JOIN lookup_exam_period_statuses leps ON ep.status_id = leps.id
JOIN subjects sub ON et.subject_id = sub.id
JOIN grade_levels gl ON et.grade_level_id = gl.id
LEFT JOIN grading_policies gp ON gp.academic_year_id = ep.academic_year_id
    AND gp.grade_level_id = et.grade_level_id
    AND gp.subject_id = et.subject_id
    AND gp.exam_type_id = ep.exam_type_id
LEFT JOIN student_exam_scores ses ON et.id = ses.exam_timetable_id
WHERE ep.is_active = TRUE
GROUP BY et.id, ep.name_ar, let.name_ar, sub.name_ar, gl.name_ar,
         et.exam_date, et.max_score, leps.name_ar, gp.passing_score;

-- ═══════════════════════════════════════════════════════════════════════════════
SELECT '✅ DDL_EXAMS v4.0: الفترات الامتحانية + درجات الطلاب (الجدولة في System 08)' AS message;
