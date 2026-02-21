-- ╔══════════════════════════════════════════════════════════════════════════════╗
-- ║           نظام الدرجات والتقويم الذكي (SGAS) - v4.0                        ║
-- ║           ملف 7: التدقيق والحوكمة (Audit & Governance)                     ║
-- ╚══════════════════════════════════════════════════════════════════════════════╝

-- التاريخ: 2026-02-19
-- الإصدار: 4.0 (COALESCE for @current_user_id + exam_timetable FK)

-- ═══════════════════════════════════════════════════════════════════════════════
-- 1. سجل تدقيق تغييرات الدرجات
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS student_grade_audit (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    enrollment_id INT UNSIGNED NOT NULL,
    subject_id INT UNSIGNED NOT NULL,

    -- مصدر التعديل
    grade_table ENUM('monthly_grades', 'semester_grades', 'annual_grades', 'student_exam_scores') NOT NULL,
    grade_field VARCHAR(50) NOT NULL COMMENT 'الحقل الذي تم تعديله',

    old_value DECIMAL(8,2) DEFAULT NULL,
    new_value DECIMAL(8,2) DEFAULT NULL,

    -- من عدّل؟
    changed_by_user_id INT UNSIGNED NULL,
    change_reason TEXT COMMENT 'سبب التعديل',
    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    INDEX idx_audit_enrollment (enrollment_id),
    INDEX idx_audit_table (grade_table),
    INDEX idx_audit_date (changed_at),

    FOREIGN KEY (enrollment_id) REFERENCES student_enrollments(id),
    FOREIGN KEY (subject_id) REFERENCES subjects(id),
    FOREIGN KEY (changed_by_user_id) REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='سجل تدقيق تعديلات الدرجات';

-- ═══════════════════════════════════════════════════════════════════════════════
-- 2. Triggers: منع تعديل الحقول الجوهرية بعد الاعتماد
-- ═══════════════════════════════════════════════════════════════════════════════

DELIMITER //

CREATE TRIGGER trg_semester_grade_lock
BEFORE UPDATE ON semester_grades
FOR EACH ROW
BEGIN
    IF OLD.grading_status_id = 3 AND (
        NOT (OLD.semester_work_total <=> NEW.semester_work_total)
        OR NOT (OLD.final_exam_score <=> NEW.final_exam_score)
        OR NOT (OLD.enrollment_id <=> NEW.enrollment_id)
        OR NOT (OLD.subject_id <=> NEW.subject_id)
        OR NOT (OLD.semester_id <=> NEW.semester_id)
    ) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'لا يمكن تعديل الحقول الأساسية لنتيجة فصل معتمدة';
    END IF;
END//

CREATE TRIGGER trg_annual_grade_lock
BEFORE UPDATE ON annual_grades
FOR EACH ROW
BEGIN
    IF OLD.grading_status_id = 3 AND (
        NOT (OLD.semester1_total <=> NEW.semester1_total)
        OR NOT (OLD.semester2_total <=> NEW.semester2_total)
        OR NOT (OLD.annual_percentage <=> NEW.annual_percentage)
        OR NOT (OLD.final_status_id <=> NEW.final_status_id)
        OR NOT (OLD.enrollment_id <=> NEW.enrollment_id)
        OR NOT (OLD.subject_id <=> NEW.subject_id)
        OR NOT (OLD.academic_year_id <=> NEW.academic_year_id)
    ) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'لا يمكن تعديل الحقول الأساسية لنتيجة سنوية معتمدة';
    END IF;
END//

CREATE TRIGGER trg_annual_result_lock
BEFORE UPDATE ON annual_result
FOR EACH ROW
BEGIN
    IF OLD.grading_status_id = 3 AND (
        NOT (OLD.total_all_subjects <=> NEW.total_all_subjects)
        OR NOT (OLD.max_possible_total <=> NEW.max_possible_total)
        OR NOT (OLD.percentage <=> NEW.percentage)
        OR NOT (OLD.rank_in_class <=> NEW.rank_in_class)
        OR NOT (OLD.rank_in_grade <=> NEW.rank_in_grade)
        OR NOT (OLD.passed_subjects_count <=> NEW.passed_subjects_count)
        OR NOT (OLD.failed_subjects_count <=> NEW.failed_subjects_count)
        OR NOT (OLD.promotion_decision_id <=> NEW.promotion_decision_id)
        OR NOT (OLD.enrollment_id <=> NEW.enrollment_id)
        OR NOT (OLD.academic_year_id <=> NEW.academic_year_id)
    ) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'لا يمكن تعديل الحقول الأساسية لنتيجة نهائية معتمدة';
    END IF;
END//

-- ═══════════════════════════════════════════════════════════════════════════════
-- 3. Triggers: التدقيق التلقائي
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE TRIGGER trg_exam_score_audit
AFTER UPDATE ON student_exam_scores
FOR EACH ROW
BEGIN
    IF NOT (OLD.score <=> NEW.score) THEN
        INSERT INTO student_grade_audit
            (enrollment_id, subject_id, grade_table, grade_field, old_value, new_value, changed_by_user_id)
        SELECT
            NEW.enrollment_id,
            et.subject_id,
            'student_exam_scores',
            'score',
            OLD.score,
            NEW.score,
            COALESCE(@current_user_id, NULL)
        FROM exam_timetable et
        WHERE et.id = NEW.exam_timetable_id;
    END IF;
END//

CREATE TRIGGER trg_monthly_grade_audit
AFTER UPDATE ON monthly_grades
FOR EACH ROW
BEGIN
    IF NOT (OLD.attendance_score <=> NEW.attendance_score) THEN
        INSERT INTO student_grade_audit
            (enrollment_id, subject_id, grade_table, grade_field, old_value, new_value, changed_by_user_id)
        VALUES
            (NEW.enrollment_id, NEW.subject_id, 'monthly_grades', 'attendance_score', OLD.attendance_score, NEW.attendance_score, @current_user_id);
    END IF;

    IF NOT (OLD.homework_score <=> NEW.homework_score) THEN
        INSERT INTO student_grade_audit
            (enrollment_id, subject_id, grade_table, grade_field, old_value, new_value, changed_by_user_id)
        VALUES
            (NEW.enrollment_id, NEW.subject_id, 'monthly_grades', 'homework_score', OLD.homework_score, NEW.homework_score, @current_user_id);
    END IF;

    IF NOT (OLD.activity_score <=> NEW.activity_score) THEN
        INSERT INTO student_grade_audit
            (enrollment_id, subject_id, grade_table, grade_field, old_value, new_value, changed_by_user_id)
        VALUES
            (NEW.enrollment_id, NEW.subject_id, 'monthly_grades', 'activity_score', OLD.activity_score, NEW.activity_score, @current_user_id);
    END IF;

    IF NOT (OLD.contribution_score <=> NEW.contribution_score) THEN
        INSERT INTO student_grade_audit
            (enrollment_id, subject_id, grade_table, grade_field, old_value, new_value, changed_by_user_id)
        VALUES
            (NEW.enrollment_id, NEW.subject_id, 'monthly_grades', 'contribution_score', OLD.contribution_score, NEW.contribution_score, @current_user_id);
    END IF;

    IF NOT (OLD.custom_components_score <=> NEW.custom_components_score) THEN
        INSERT INTO student_grade_audit
            (enrollment_id, subject_id, grade_table, grade_field, old_value, new_value, changed_by_user_id)
        VALUES
            (NEW.enrollment_id, NEW.subject_id, 'monthly_grades', 'custom_components_score', OLD.custom_components_score, NEW.custom_components_score, @current_user_id);
    END IF;

    IF NOT (OLD.exam_score <=> NEW.exam_score) THEN
        INSERT INTO student_grade_audit
            (enrollment_id, subject_id, grade_table, grade_field, old_value, new_value, changed_by_user_id)
        VALUES
            (NEW.enrollment_id, NEW.subject_id, 'monthly_grades', 'exam_score', OLD.exam_score, NEW.exam_score, @current_user_id);
    END IF;
END//

DELIMITER ;

-- ═══════════════════════════════════════════════════════════════════════════════
SELECT '✅ DDL_AUDIT v4.0: التدقيق + COALESCE(@current_user_id) + exam_timetable FK' AS message;
