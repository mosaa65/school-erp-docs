-- ╔══════════════════════════════════════════════════════════════════════════════╗
-- ║           نظام الدرجات والتقويم الذكي (SGAS) - v4.0                        ║
-- ║           ملف 4: المحصلات الشهرية + الحساب الآلي (Monthly Grades)           ║
-- ╚══════════════════════════════════════════════════════════════════════════════╝

-- التاريخ: 2026-02-19
-- الإصدار: 4.0 (exam_timetable FK + manual score validation + denormalization)
-- الاعتمادات: DDL_POLICIES, System 08 (exam_timetable), DDL_HOMEWORKS, System 04 (الحضور)

-- ═══════════════════════════════════════════════════════════════════════════════
-- 1. المحصلة الشهرية (جمع كل مكونات الدرجة للشهر)
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS monthly_grades (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    enrollment_id INT UNSIGNED NOT NULL,
    subject_id INT UNSIGNED NOT NULL,
    month_id INT UNSIGNED NOT NULL COMMENT 'FK → academic_months',

    -- أعمدة denormalized لتسريع الاستعلامات (§2.5)
    semester_id INT UNSIGNED NULL COMMENT 'FK → semesters (denormalized من academic_months)',
    academic_year_id INT UNSIGNED NULL COMMENT 'FK → academic_years (denormalized)',

    -- مكونات المحصلة الشهرية
    attendance_score DECIMAL(5,2) DEFAULT 0 COMMENT 'درجة المواظبة (محسوبة من نظام الحضور)',
    homework_score DECIMAL(5,2) DEFAULT 0 COMMENT 'درجة الواجبات (محسوبة من واجبات الشهر)',
    activity_score DECIMAL(5,2) DEFAULT 0 COMMENT 'درجة النشاط (يدوي)',
    contribution_score DECIMAL(5,2) DEFAULT 0 COMMENT 'درجة المساهمة/السلوك (يدوي)',
    custom_components_score DECIMAL(5,2) DEFAULT 0 COMMENT 'مجموع المكونات المخصصة',
    exam_score DECIMAL(5,2) DEFAULT 0 COMMENT 'متوسط الاختبارات لذلك الشهر',

    monthly_total DECIMAL(6,2) GENERATED ALWAYS AS (
        attendance_score + homework_score + activity_score + contribution_score + custom_components_score + exam_score
    ) STORED COMMENT 'المجموع الشهري النهائي',

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NULL ON UPDATE CURRENT_TIMESTAMP,

    CHECK (attendance_score >= 0),
    CHECK (homework_score >= 0),
    CHECK (activity_score >= 0),
    CHECK (contribution_score >= 0),
    CHECK (custom_components_score >= 0),
    CHECK (exam_score >= 0),

    UNIQUE KEY uk_monthly (enrollment_id, subject_id, month_id),
    INDEX idx_mg_month_subject (month_id, subject_id),
    INDEX idx_mg_semester (semester_id),
    INDEX idx_mg_year (academic_year_id),

    FOREIGN KEY (enrollment_id) REFERENCES student_enrollments(id),
    FOREIGN KEY (subject_id) REFERENCES subjects(id),
    FOREIGN KEY (month_id) REFERENCES academic_months(id),
    FOREIGN KEY (semester_id) REFERENCES semesters(id) ON DELETE SET NULL,
    FOREIGN KEY (academic_year_id) REFERENCES academic_years(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='المحصلة الشهرية المرنة — مع denormalization للفصل والعام';

-- ═══════════════════════════════════════════════════════════════════════════════
-- 2. View: حساب درجة المواظبة آلياً من نظام الحضور (System 04)
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE OR REPLACE VIEW v_auto_attendance_score AS
SELECT
    sa.enrollment_id,
    am.id AS month_id,
    am.semester_id,
    COUNT(sa.id) AS total_days,
    SUM(CASE WHEN sa.status_id = 1 THEN 1 ELSE 0 END) AS present_days,
    SUM(CASE WHEN sa.status_id != 1 THEN 1 ELSE 0 END) AS absent_days,
    CASE
        WHEN COUNT(sa.id) = 0 THEN 0
        ELSE (SUM(CASE WHEN sa.status_id = 1 THEN 1 ELSE 0 END) / NULLIF(COUNT(sa.id), 0)) * 100
    END AS attendance_percentage
FROM student_attendance sa
JOIN academic_months am
    ON sa.attendance_date BETWEEN am.start_date AND am.end_date
GROUP BY sa.enrollment_id, am.id, am.semester_id;

-- ═══════════════════════════════════════════════════════════════════════════════
-- 3. View: حساب متوسط درجة الواجبات آلياً لكل طالب/مادة/شهر
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE OR REPLACE VIEW v_auto_homework_score AS
SELECT
    vheg.enrollment_id,
    vheg.subject_id,
    vheg.month_id,
    COUNT(vheg.student_homework_id) AS total_homeworks,
    SUM(CASE WHEN vheg.is_completed THEN 1 ELSE 0 END) AS completed_count,
    AVG(vheg.effective_grade) AS avg_grade,
    SUM(vheg.effective_grade) AS total_grade,
    SUM(vheg.max_grade) AS total_max_grade
FROM v_homework_effective_grade vheg
WHERE vheg.month_id IS NOT NULL
GROUP BY vheg.enrollment_id, vheg.subject_id, vheg.month_id;

-- ═══════════════════════════════════════════════════════════════════════════════
-- 4. درجات المكونات المخصصة الشهرية
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS monthly_custom_component_scores (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    enrollment_id INT UNSIGNED NOT NULL,
    subject_id INT UNSIGNED NOT NULL,
    month_id INT UNSIGNED NOT NULL,
    policy_component_id INT UNSIGNED NOT NULL COMMENT 'FK → grading_policy_custom_components',
    score DECIMAL(5,2) NOT NULL DEFAULT 0.00,
    notes VARCHAR(255) NULL,
    created_by_user_id INT UNSIGNED NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NULL ON UPDATE CURRENT_TIMESTAMP,

    UNIQUE KEY uk_mccs (enrollment_id, subject_id, month_id, policy_component_id),
    INDEX idx_mccs_component (policy_component_id),
    INDEX idx_mccs_month_subject (month_id, subject_id),

    FOREIGN KEY (enrollment_id) REFERENCES student_enrollments(id) ON DELETE CASCADE,
    FOREIGN KEY (subject_id) REFERENCES subjects(id),
    FOREIGN KEY (month_id) REFERENCES academic_months(id),
    FOREIGN KEY (policy_component_id) REFERENCES grading_policy_custom_components(id) ON DELETE CASCADE,
    FOREIGN KEY (created_by_user_id) REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='درجات المكونات المخصصة الشهرية لكل طالب';

DELIMITER //

CREATE TRIGGER trg_mccs_validate_insert
BEFORE INSERT ON monthly_custom_component_scores
FOR EACH ROW
BEGIN
    DECLARE v_component_max DECIMAL(5,2);
    DECLARE v_link_count INT DEFAULT 0;
    DECLARE v_classroom_id INT;
    DECLARE v_month_semester_id INT;
    DECLARE v_month_academic_year_id INT;
    DECLARE v_current_user_id INT;
    DECLARE v_current_employee_id INT;
    DECLARE v_is_authorized INT DEFAULT 0;

    IF NEW.score < 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'لا يمكن إدخال درجة سالبة للمكون المخصص';
    END IF;

    SELECT gpcc.max_score
    INTO v_component_max
    FROM grading_policy_custom_components gpcc
    WHERE gpcc.id = NEW.policy_component_id
      AND gpcc.is_active = TRUE
    LIMIT 1;

    IF v_component_max IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'المكون المخصص غير موجود أو غير نشط';
    END IF;

    IF NEW.score > v_component_max THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'درجة المكون المخصص أعلى من الدرجة العظمى للمكون';
    END IF;

    SELECT COUNT(*)
    INTO v_link_count
    FROM student_enrollments se
    JOIN classrooms c ON c.id = se.classroom_id
    JOIN academic_months am ON am.id = NEW.month_id
    JOIN semesters sem ON sem.id = am.semester_id
    JOIN grading_policy_custom_components gpcc ON gpcc.id = NEW.policy_component_id
    JOIN grading_policies gp ON gp.id = gpcc.policy_id
    WHERE se.id = NEW.enrollment_id
      AND gp.subject_id = NEW.subject_id
      AND gp.academic_year_id = c.academic_year_id
      AND gp.grade_level_id = c.grade_level_id
      AND gp.exam_type_id = 1 -- MONTHLY
      AND sem.academic_year_id = c.academic_year_id
    LIMIT 1;

    IF v_link_count = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'هذا المكون لا يتبع سياسة الطالب/المادة/الشهر';
    END IF;

    -- التحقق من تكليف المعلم بالمادة/الفصل
    -- bypass اختياري للعمليات النظامية: SET @skip_teacher_assignment_check = 1;
    IF COALESCE(@skip_teacher_assignment_check, 0) = 0 THEN
        SET v_current_user_id = COALESCE(@current_user_id, NULL);

        IF v_current_user_id IS NULL THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'يجب ضبط @current_user_id قبل إدخال درجات المكونات المخصصة';
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

        SELECT se.classroom_id
        INTO v_classroom_id
        FROM student_enrollments se
        WHERE se.id = NEW.enrollment_id
        LIMIT 1;

        SELECT am.semester_id, sem.academic_year_id
        INTO v_month_semester_id, v_month_academic_year_id
        FROM academic_months am
        JOIN semesters sem ON sem.id = am.semester_id
        WHERE am.id = NEW.month_id
        LIMIT 1;

        SELECT COUNT(*)
        INTO v_is_authorized
        FROM teacher_assignments ta
        WHERE ta.employee_id = v_current_employee_id
          AND ta.academic_year_id = v_month_academic_year_id
          AND ta.semester_id = v_month_semester_id
          AND ta.subject_id = NEW.subject_id
          AND ta.classroom_id = v_classroom_id
          AND ta.is_active = TRUE;

        IF v_is_authorized = 0 THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'غير مصرح لك بإدخال درجات هذا المكون (تحقق من teacher_assignments)';
        END IF;
    END IF;
END//

CREATE TRIGGER trg_mccs_validate_update
BEFORE UPDATE ON monthly_custom_component_scores
FOR EACH ROW
BEGIN
    DECLARE v_component_max DECIMAL(5,2);
    DECLARE v_classroom_id INT;
    DECLARE v_month_semester_id INT;
    DECLARE v_month_academic_year_id INT;
    DECLARE v_current_user_id INT;
    DECLARE v_current_employee_id INT;
    DECLARE v_is_authorized INT DEFAULT 0;

    IF NEW.score < 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'لا يمكن إدخال درجة سالبة للمكون المخصص';
    END IF;

    SELECT gpcc.max_score
    INTO v_component_max
    FROM grading_policy_custom_components gpcc
    WHERE gpcc.id = NEW.policy_component_id
      AND gpcc.is_active = TRUE
    LIMIT 1;

    IF v_component_max IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'المكون المخصص غير موجود أو غير نشط';
    END IF;

    IF NEW.score > v_component_max THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'درجة المكون المخصص أعلى من الدرجة العظمى للمكون';
    END IF;

    -- التحقق من تكليف المعلم بالمادة/الفصل
    IF COALESCE(@skip_teacher_assignment_check, 0) = 0 THEN
        SET v_current_user_id = COALESCE(@current_user_id, NULL);

        IF v_current_user_id IS NULL THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'يجب ضبط @current_user_id قبل تعديل درجات المكونات المخصصة';
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

        SELECT se.classroom_id
        INTO v_classroom_id
        FROM student_enrollments se
        WHERE se.id = NEW.enrollment_id
        LIMIT 1;

        SELECT am.semester_id, sem.academic_year_id
        INTO v_month_semester_id, v_month_academic_year_id
        FROM academic_months am
        JOIN semesters sem ON sem.id = am.semester_id
        WHERE am.id = NEW.month_id
        LIMIT 1;

        SELECT COUNT(*)
        INTO v_is_authorized
        FROM teacher_assignments ta
        WHERE ta.employee_id = v_current_employee_id
          AND ta.academic_year_id = v_month_academic_year_id
          AND ta.semester_id = v_month_semester_id
          AND ta.subject_id = NEW.subject_id
          AND ta.classroom_id = v_classroom_id
          AND ta.is_active = TRUE;

        IF v_is_authorized = 0 THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'غير مصرح لك بتعديل درجات هذا المكون (تحقق من teacher_assignments)';
        END IF;
    END IF;
END//

DELIMITER ;

-- ═══════════════════════════════════════════════════════════════════════════════
-- 5. Procedure: ملء المحصلات الشهرية آلياً
-- ═══════════════════════════════════════════════════════════════════════════════
-- يجمع: attendance + homework + exam + custom
-- يبقي: activity_score + contribution_score يدوياً

DELIMITER //

CREATE PROCEDURE sp_calculate_monthly_grades(
    IN p_month_id INT,
    IN p_subject_id INT,
    IN p_classroom_id INT
)
BEGIN
    DECLARE v_grade_level_id INT;
    DECLARE v_academic_year_id INT;
    DECLARE v_month_semester_id INT;
    DECLARE v_max_attendance DECIMAL(5,2);
    DECLARE v_max_homework DECIMAL(5,2);
    DECLARE v_max_exam DECIMAL(5,2);
    DECLARE v_month_start DATE;
    DECLARE v_month_end DATE;

    SELECT c.grade_level_id, c.academic_year_id
    INTO v_grade_level_id, v_academic_year_id
    FROM classrooms c
    WHERE c.id = p_classroom_id
    LIMIT 1;

    SELECT gp.max_attendance_score, gp.max_homework_score, gp.max_exam_score
    INTO v_max_attendance, v_max_homework, v_max_exam
    FROM grading_policies gp
    WHERE gp.academic_year_id = v_academic_year_id
      AND gp.grade_level_id = v_grade_level_id
      AND gp.subject_id = p_subject_id
      AND gp.exam_type_id = 1 -- MONTHLY
    LIMIT 1;

    SELECT am.start_date, am.end_date, am.semester_id
    INTO v_month_start, v_month_end, v_month_semester_id
    FROM academic_months am
    WHERE am.id = p_month_id
    LIMIT 1;

    INSERT INTO monthly_grades (
        enrollment_id, subject_id, month_id, semester_id, academic_year_id,
        attendance_score, homework_score, exam_score, custom_components_score
    )
    SELECT
        se.id AS enrollment_id,
        p_subject_id,
        p_month_id,
        v_month_semester_id,
        v_academic_year_id,

        COALESCE((vas.attendance_percentage / 100) * COALESCE(v_max_attendance, 5.00), 0) AS calc_attendance,

        COALESCE(
            CASE
                WHEN vahs.total_max_grade > 0
                THEN (vahs.total_grade / vahs.total_max_grade) * COALESCE(v_max_homework, 5.00)
                ELSE 0
            END,
            0
        ) AS calc_homework,

        COALESCE(
            CASE
                WHEN exam_data.total_max > 0
                THEN (exam_data.total_score / exam_data.total_max) * COALESCE(v_max_exam, 20.00)
                ELSE 0
            END,
            0
        ) AS calc_exam,

        COALESCE(custom_data.total_custom, 0) AS calc_custom

    FROM student_enrollments se

    LEFT JOIN v_auto_attendance_score vas
        ON vas.enrollment_id = se.id
       AND vas.month_id = p_month_id

    LEFT JOIN v_auto_homework_score vahs
        ON vahs.enrollment_id = se.id
       AND vahs.subject_id = p_subject_id
       AND vahs.month_id = p_month_id

    LEFT JOIN (
        SELECT
            ses.enrollment_id,
            SUM(ses.score) AS total_score,
            SUM(et.max_score) AS total_max
        FROM student_exam_scores ses
        JOIN exam_timetable et ON ses.exam_timetable_id = et.id
        JOIN exam_periods ep ON ep.id = et.exam_period_id
        JOIN lookup_exam_period_statuses leps ON leps.id = ep.status_id
        WHERE et.subject_id = p_subject_id
          AND et.grade_level_id = v_grade_level_id
          AND et.is_active = TRUE
          AND et.exam_date BETWEEN v_month_start AND v_month_end
          AND ep.is_active = TRUE
          AND ep.academic_year_id = v_academic_year_id
          AND ep.semester_id = v_month_semester_id
          AND ep.exam_type_id = 1 -- MONTHLY only
          AND leps.code IN ('SCORING', 'REVIEW', 'APPROVED')
          AND ses.is_present = TRUE
        GROUP BY ses.enrollment_id
    ) exam_data ON exam_data.enrollment_id = se.id

    LEFT JOIN (
        SELECT
            mccs.enrollment_id,
            mccs.subject_id,
            mccs.month_id,
            SUM(mccs.score) AS total_custom
        FROM monthly_custom_component_scores mccs
        JOIN grading_policy_custom_components gpcc ON gpcc.id = mccs.policy_component_id
        WHERE mccs.subject_id = p_subject_id
          AND mccs.month_id = p_month_id
          AND gpcc.is_active = TRUE
          AND gpcc.include_in_monthly = TRUE
        GROUP BY mccs.enrollment_id, mccs.subject_id, mccs.month_id
    ) custom_data ON custom_data.enrollment_id = se.id
                AND custom_data.subject_id = p_subject_id
                AND custom_data.month_id = p_month_id

    WHERE se.classroom_id = p_classroom_id
      AND se.is_active = TRUE

    ON DUPLICATE KEY UPDATE
        attendance_score = VALUES(attendance_score),
        homework_score = VALUES(homework_score),
        exam_score = VALUES(exam_score),
        custom_components_score = VALUES(custom_components_score),
        updated_at = CURRENT_TIMESTAMP;

END//

DELIMITER ;

-- ═══════════════════════════════════════════════════════════════════════════════
-- 6. Trigger: التحقق من حدود الدرجات اليدوية (§2.6)
-- ═══════════════════════════════════════════════════════════════════════════════

DELIMITER //

CREATE TRIGGER trg_monthly_grades_validate_manual
BEFORE UPDATE ON monthly_grades
FOR EACH ROW
BEGIN
    DECLARE v_max_activity DECIMAL(5,2) DEFAULT 999;
    DECLARE v_max_contribution DECIMAL(5,2) DEFAULT 999;
    DECLARE v_grade_level_id INT;
    DECLARE v_classroom_id INT;
    DECLARE v_month_semester_id INT;
    DECLARE v_month_academic_year_id INT;
    DECLARE v_current_user_id INT;
    DECLARE v_current_employee_id INT;
    DECLARE v_is_authorized INT DEFAULT 0;

    -- جلب صف الطالب
    SELECT se.classroom_id, c.grade_level_id
    INTO v_classroom_id, v_grade_level_id
    FROM student_enrollments se
    JOIN classrooms c ON se.classroom_id = c.id
    WHERE se.id = NEW.enrollment_id
    LIMIT 1;

    SELECT am.semester_id, sem.academic_year_id
    INTO v_month_semester_id, v_month_academic_year_id
    FROM academic_months am
    JOIN semesters sem ON sem.id = am.semester_id
    WHERE am.id = NEW.month_id
    LIMIT 1;

    -- جلب الحدود من السياسة
    SELECT gp.max_activity_score, gp.max_contribution_score
    INTO v_max_activity, v_max_contribution
    FROM grading_policies gp
    WHERE gp.grade_level_id = v_grade_level_id
      AND gp.subject_id = NEW.subject_id
      AND gp.academic_year_id = COALESCE(NEW.academic_year_id, v_month_academic_year_id)
      AND gp.exam_type_id = 1 -- MONTHLY
    LIMIT 1;

    -- التحقق من تكليف المعلم فقط عند تعديل الحقول اليدوية (نشاط/مساهمة)
    -- bypass اختياري للعمليات النظامية: SET @skip_teacher_assignment_check = 1;
    IF (
        NOT (OLD.activity_score <=> NEW.activity_score)
        OR NOT (OLD.contribution_score <=> NEW.contribution_score)
    ) AND COALESCE(@skip_teacher_assignment_check, 0) = 0 THEN
        SET v_current_user_id = COALESCE(@current_user_id, NULL);

        IF v_current_user_id IS NULL THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'يجب ضبط @current_user_id قبل تعديل درجات النشاط/المساهمة';
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
        WHERE ta.employee_id = v_current_employee_id
          AND ta.academic_year_id = v_month_academic_year_id
          AND ta.semester_id = v_month_semester_id
          AND ta.subject_id = NEW.subject_id
          AND ta.classroom_id = v_classroom_id
          AND ta.is_active = TRUE;

        IF v_is_authorized = 0 THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'غير مصرح لك بتعديل النشاط/المساهمة لهذا الطالب (تحقق من teacher_assignments)';
        END IF;
    END IF;

    IF NEW.activity_score > v_max_activity THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'درجة النشاط تتجاوز الحد الأقصى المعتمد في السياسة';
    END IF;

    IF NEW.contribution_score > v_max_contribution THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'درجة المساهمة تتجاوز الحد الأقصى المعتمد في السياسة';
    END IF;
END//

DELIMITER ;

-- ═══════════════════════════════════════════════════════════════════════════════
SELECT '✅ DDL_MONTHLY v4.0: المحصلات الشهرية + التحقق من الحدود + denormalization' AS message;
